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

  uint8 private nonce = 0;
  uint256 public constant createAccountFee = 1 ether;

  INodeRegistry immutable _nodeRegistry;

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

  mapping(bytes32 => Account) _accounts;
  mapping(bytes32 => Rule[]) _rules;

  event AccountCreated(bytes32 indexed accountId, uint8 signersCount, uint8 threshold);
  event AccountSignersReady(bytes32 indexed accountId, uint8 signersCount, address[] signers);
  event AccountReady(bytes32 indexed accountId, address indexed publicAddress);
  event AccountNewSigner(bytes32 indexed accountId, address indexed node, uint8 signerIndex, address signer);
  event NewRule(bytes32 indexed accountId, uint256 indexed index, Rule rule);
  event RuleExpired(bytes32 indexed accountId, uint256 indexed index, uint40 validTo);

  constructor(INodeRegistry nodeRegistry_) {
    _nodeRegistry = nodeRegistry_;
  }

  function createAccount(
    uint8 signersCount_,
    uint8 threshold_,
    address owner_,
    Rule[] memory rules
  ) public payable returns (bytes32 accountId) {
    require(msg.value == createAccountFee, 'TssAccountManager: Incorrect fee sent');

    accountId = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce));
    require(_accounts[accountId].signersCount == 0, 'TssAccountManager: Account already exists!');
    nonce++;

    require(
      signersCount_ > 0 && threshold_ > 0 && signersCount_ >= threshold_, 'TssAccountManager: invalid threshold setup'
    );
    _accounts[accountId] = Account({
      publicAddress: address(0),
      signersCount: signersCount_,
      threshold: threshold_,
      owner: owner_,
      signers: new address[](signersCount_),
      signerNodes: new address[](signersCount_)
    });
    emit AccountCreated(accountId, signersCount_, threshold_);
    for (uint256 i = 0; i < rules.length; i++) {
      _validateRule(rules[i]);
      _rules[accountId].push(rules[i]);
      emit NewRule(accountId, i, rules[i]);
    }
    return accountId;
  }

  function _validateRule(Rule memory rule) internal view {
    require(rule.targetContract != address(0), "TssAccountManager: target contract can't be 0");
    require(
      rule.validTo == 0 && rule.validTo >= block.timestamp + GRACE_TIME,
      'TssAccountManager: rule must be unbounded or expire after grace time'
    );
    // TODO: other rule validations
  }

  function registerSigner(bytes32 accountId, uint8 signerIndex, address signerAddress) public {
    require(_nodeRegistry.isActive(msg.sender), 'TssAccountManager: must be called by an active node');
    require(_accounts[accountId].signersCount > 0, "TssAccountManager: account doesn't exists");
    require(_accounts[accountId].publicAddress == address(0), 'TssAccountManager: account already initialized');
    require(_accounts[accountId].signers[signerIndex] == address(0), 'TssAccountManager: signer slot already taken');
    bool signersComplete = true;
    for (uint8 i = 0; i < _accounts[accountId].signersCount; i++) {
      require(
        _accounts[accountId].signerNodes[i] != msg.sender,
        'TssAccountManager: this node is already a signer for the account'
      );
      if (signersComplete && _accounts[accountId].signers[i] == address(0)) {
        signersComplete = false;
      }
    }
    _accounts[accountId].signers[signerIndex] = signerAddress;
    _accounts[accountId].signerNodes[signerIndex] = msg.sender;
    emit AccountNewSigner(accountId, msg.sender, signerIndex, signerAddress);
    if (signersComplete) {
      emit AccountSignersReady(accountId, _accounts[accountId].signersCount, _accounts[accountId].signers);
    }
  }

  function registerPublicAddress(
    bytes32 accountId,
    address publicAddress,
    uint8[] calldata v,
    bytes32[] calldata r,
    bytes32[] calldata s
  ) public {
    require(_accounts[accountId].publicAddress != address(0), 'TssAccountManager: publicAddress already set');
    require(_accounts[accountId].signersCount > 0, "TssAccountManager: account doesn't exists");
    require(
      _accounts[accountId].signersCount == v.length && _accounts[accountId].signersCount == r.length
        && _accounts[accountId].signersCount == s.length,
      'TssAccountManager: invalid signatures length'
    );
    bytes32 message = MessageHashUtils.toEthSignedMessageHash(abi.encodePacked(accountId, publicAddress));

    for (uint8 i = 0; i < _accounts[accountId].signersCount; i++) {
      address recoveredSigner = ECDSA.recover(message, v[i], r[i], s[i]);
      require(
        recoveredSigner == _accounts[accountId].signers[i] && recoveredSigner != address(0),
        'TssAccountManager: invalid signature'
      );
    }
    _accounts[accountId].publicAddress = publicAddress;

    // sets validFrom for all the active rules
    for (uint8 i = 0; i < _rules[accountId].length; i++) {
      if (block.timestamp > _rules[accountId][i].validFrom) {
        _rules[accountId][i].validFrom = uint40(block.timestamp);
      }
    }
  }

  function addRule(bytes32 accountId, Rule memory newRule) public {
    require(_accounts[accountId].owner == msg.sender, 'TssAccountManager: you must be the owner');
    _validateRule(newRule);
    _rules[accountId].push(newRule);
    emit NewRule(accountId, _rules[accountId].length - 1, newRule);
  }

  function expireRule(bytes32 accountId, uint256 ruleIndex) public {
    require(_accounts[accountId].owner == msg.sender, 'TssAccountManager: you must be the owner');
    Rule storage rule = _rules[accountId][ruleIndex];
    require(rule.validTo == 0 && rule.validTo > block.timestamp + GRACE_TIME, 'TssAccountManager: rule already expired');
    rule.validTo = uint40(block.timestamp) + GRACE_TIME;
    emit RuleExpired(accountId, ruleIndex, rule.validTo);
  }

  function messagesToSignFromFacts(
    bytes32 accountId,
    uint256 ruleIndex,
    Facts.Fact[] memory facts
  ) external view returns (bytes[] memory messages) {
    Rule storage rule = _rules[accountId][ruleIndex];
    require(rule.targetContract != address(0), "TssAccountManager: rule doesn't exists");
    require(rule.validFrom <= block.timestamp, 'TssAccountManager: rule is not active yet');
    require(rule.validTo == 0 || rule.validTo >= block.timestamp, 'TssAccountManager: rule has expired');
    bytes memory result =
      rule.targetContract.functionStaticCall(abi.encodeWithSelector(rule.selector, rule.payload, facts));
    return abi.decode(result, (bytes[]));
  }

  function getPublicAddress(bytes32 accountId) external view override returns (address) {
    return _accounts[accountId].publicAddress;
  }
}
