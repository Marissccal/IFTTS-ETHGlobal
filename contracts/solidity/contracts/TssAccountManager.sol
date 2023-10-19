// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {INodeRegistry} from '../interfaces/INodeRegistry.sol';
import {ITssAccountManager} from '../interfaces/ITssAccountManager.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import {Facts} from './Facts.sol';

contract TssAccountManager is ITssAccountManager {
  using Address for address;

  /**
   * @dev GRACE_TIME is the time we leave to the nodes before they know a rule has expired.
   */
  uint40 public constant GRACE_TIME = 3600;
  uint256 public constant createAccountFee = 1 ether;

  INodeRegistry public immutable NODE_REGISTRY;

  uint256 private _nonce = 0;

  struct Rule {
    address targetContract; // Address of the contract holding the code of the rule
    bytes4 selector; // Selector of the method to call
    bytes payload; // First parameter to pass to the method (the 2nd one will be an array of facts)
    uint40 validFrom; // Timestamp since when this rule is valid
    uint40 validTo; // Timestamp when this rule is no longer valid or 0 if unbounded.
  }

  /**
   * @dev This struct tracks the accounts managed. The account is ready to use when it has publicAddress.
   *
   *      We keep a list of the signer nodes and the public keys they use. A node can be a contract or an EOA,
   *      and it's the one that is whiltelisted in the NodeRegistry and accepts to participate in a particular account.
   *      Each node, for security or other reasons, can have several key pairs that will use for the signatures.
   *
   *      Constraints: we can't have the same node twice in the same account.
   */
  struct Account {
    address publicAddress;
    uint8 signersCount;
    uint8 threshold;
    address owner;
    address[] signers;
    address[] signerNodes;
  }

  mapping(bytes32 => Account) internal _accounts;
  mapping(bytes32 => Rule[]) internal _rules;

  event AccountCreated(bytes32 indexed _accountId, uint8 _signersCount, uint8 _threshold);
  event AccountSignersReady(bytes32 indexed _accountId, uint8 _signersCount, address[] _signers);
  event AccountReady(bytes32 indexed _accountId, address indexed _publicAddress);
  event AccountNewSigner(bytes32 indexed _accountId, address indexed _node, uint8 _signerIndex, address _signer);
  event NewRule(bytes32 indexed _accountId, uint256 indexed _index, Rule _rule);
  event RuleExpired(bytes32 indexed _accountId, uint256 indexed _index, uint40 _validTo);

  constructor(INodeRegistry _nodeRegistry) {
    NODE_REGISTRY = _nodeRegistry;
  }

  function createAccount(
    uint8 _signersCount,
    uint8 _threshold,
    address _owner,
    Rule[] memory _accountRules
  ) public payable returns (bytes32 _accountId) {
    require(msg.value == createAccountFee, 'TssAccountManager: Incorrect fee sent');

    _accountId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _nonce));
    require(_accounts[_accountId].signersCount == 0, 'TssAccountManager: Account already exists!');
    _nonce++;

    require(
      _signersCount > 0 && _threshold > 0 && _signersCount >= _threshold, 'TssAccountManager: invalid threshold setup'
    );
    _accounts[_accountId] = Account({
      publicAddress: address(0),
      signersCount: _signersCount,
      threshold: _threshold,
      owner: _owner,
      signers: new address[](_signersCount),
      signerNodes: new address[](_signersCount)
    });
    emit AccountCreated(_accountId, _signersCount, _threshold);
    for (uint256 _i = 0; _i < _accountRules.length; _i++) {
      _validateRule(_accountRules[_i]);
      _rules[_accountId].push(_accountRules[_i]);
      emit NewRule(_accountId, _i, _accountRules[_i]);
    }
    return _accountId;
  }

  function _validateRule(Rule memory _rule) internal view {
    require(_rule.targetContract != address(0), 'TssAccountManager: target contract can\'t be 0');
    require(
      _rule.validTo == 0 && _rule.validTo >= block.timestamp + GRACE_TIME,
      'TssAccountManager: rule expires after grace time'
    );
    // TODO: other rule validations
  }

  function registerSigner(bytes32 _accountId, uint8 _signerIndex, address _signerAddress) public {
    require(NODE_REGISTRY.isActive(msg.sender), 'TssAccountManager: must be called by an active node');
    require(_accounts[_accountId].signersCount > 0, 'TssAccountManager: account doesn\'t exists');
    require(_accounts[_accountId].publicAddress == address(0), 'TssAccountManager: account already initialized');
    require(_accounts[_accountId].signers[_signerIndex] == address(0), 'TssAccountManager: signer slot already taken');
    bool _signersComplete = true;
    for (uint8 _i = 0; _i < _accounts[_accountId].signersCount; _i++) {
      require(
        _accounts[_accountId].signerNodes[_i] != msg.sender,
        'TssAccountManager: this node is already a signer for the account'
      );
      if (_signersComplete && _accounts[_accountId].signers[_i] == address(0)) {
        _signersComplete = false;
      }
    }
    _accounts[_accountId].signers[_signerIndex] = _signerAddress;
    _accounts[_accountId].signerNodes[_signerIndex] = msg.sender;
    emit AccountNewSigner(_accountId, msg.sender, _signerIndex, _signerAddress);
    if (_signersComplete) {
      emit AccountSignersReady(_accountId, _accounts[_accountId].signersCount, _accounts[_accountId].signers);
    }
  }

  function registerPublicAddress(
    bytes32 _accountId,
    address _publicAddress,
    uint8[] calldata _v,
    bytes32[] calldata _r,
    bytes32[] calldata _s
  ) public {
    Account storage _account = _accounts[_accountId];
    require(_account.publicAddress == address(0), 'TssAccountManager: publicAddress already set');
    require(_account.signersCount > 0, 'TssAccountManager: account doesn\'t exists');
    require(
      _account.signersCount == _v.length && _account.signersCount == _r.length && _account.signersCount == _s.length,
      'TssAccountManager: invalid signatures length'
    );
    bytes32 _message = MessageHashUtils.toEthSignedMessageHash(abi.encodePacked(_accountId, _publicAddress));

    for (uint8 _i = 0; _i < _account.signersCount; _i++) {
      address _recoveredSigner = ECDSA.recover(_message, _v[_i], _r[_i], _s[_i]);
      require(
        _recoveredSigner == _account.signers[_i] && _recoveredSigner != address(0),
        'TssAccountManager: invalid signature'
      );
    }
    _account.publicAddress = _publicAddress;

    // sets validFrom for all the active rules
    for (uint8 _i = 0; _i < _rules[_accountId].length; _i++) {
      if (block.timestamp > _rules[_accountId][_i].validFrom) {
        _rules[_accountId][_i].validFrom = uint40(block.timestamp);
      }
    }
  }

  function addRule(bytes32 _accountId, Rule memory _newRule) public {
    require(_accounts[_accountId].owner == msg.sender, 'TssAccountManager: you must be the owner');
    _validateRule(_newRule);
    _rules[_accountId].push(_newRule);
    emit NewRule(_accountId, _rules[_accountId].length - 1, _newRule);
  }

  function expireRule(bytes32 _accountId, uint256 _ruleIndex) public {
    require(_accounts[_accountId].owner == msg.sender, 'TssAccountManager: you must be the owner');
    Rule storage _rule = _rules[_accountId][_ruleIndex];
    require(
      _rule.validTo == 0 && _rule.validTo > block.timestamp + GRACE_TIME, 'TssAccountManager: rule already expired'
    );
    _rule.validTo = uint40(block.timestamp) + GRACE_TIME;
    emit RuleExpired(_accountId, _ruleIndex, _rule.validTo);
  }

  function messagesToSignFromFacts(
    bytes32 _accountId,
    uint256 _ruleIndex,
    Facts.Fact[] memory _facts
  ) external view returns (bytes[] memory _messages) {
    Rule storage _rule = _rules[_accountId][_ruleIndex];
    require(_rule.targetContract != address(0), 'TssAccountManager: rule doesn\'t exists');
    require(_rule.validFrom <= block.timestamp, 'TssAccountManager: rule is not active yet');
    require(_rule.validTo == 0 || _rule.validTo >= block.timestamp, 'TssAccountManager: rule has expired');
    bytes memory _result =
      _rule.targetContract.functionStaticCall(abi.encodeWithSelector(_rule.selector, _rule.payload, _facts));
    return abi.decode(_result, (bytes[]));
  }

  function getPublicAddress(bytes32 _accountId) external view override returns (address _publicAddress) {
    return _accounts[_accountId].publicAddress;
  }
}
