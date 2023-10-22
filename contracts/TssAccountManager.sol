// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TssAccountManager {
    INodeRegistry immutable _nodeRegistry;

    struct Rule {
        address ruleContract;
        bytes4 selector;
        bytes payload;
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

    constructor(INodeRegistry nodeRegistry_) {
        _nodeRegistry = nodeRegistry_;
    }

    function createAccount(
        bytes32 accountId,
        uint8 signersCount_,
        uint8 threshold_,
        address owner_,
        Rule[] calldata rules
    ) public {
        // TODO: add somekind of whitelist or payment to create accounts
        require(_accounts[accountId].signersCount == 0, "TssAccountManager: Account already exists!");
        // TODO: the accountId should be created in a pseudorandom way instead of received
        require(
            signersCount_ > 0 && threshold_ > 0 && signersCount_ >= threshold_,
            "TssAccountManager: invalid threshold setup"
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
            _rules[accountId].push(rules[i]);
            emit NewRule(accountId, i, rules[i]);
        }
    }

    function registerSigner(bytes32 accountId, uint8 signerIndex, address signerAddress) public {
        require(_nodeRegistry.isActive(msg.sender), "TssAccountManager: must be called by an active node");
        require(_accounts[accountId].signersCount > 0, "TssAccountManager: account doesn't exists");
        require(_accounts[accountId].publicAddress == address(0), "TssAccountManager: account already initialized");
        require(_accounts[accountId].signers[signerIndex] == address(0), "TssAccountManager: signer slot already taken");
        bool signersComplete = true;
        for (uint8 i = 0; i < _accounts[accountId].signersCount; i++) {
            require(
                _accounts[accountId].signerNodes[i] != msg.sender,
                "TssAccountManager: this node is already a signer for the account"
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
        require(_accounts[accountId].publicAddress != address(0), "TssAccountManager: publicAddress already set");
        require(_accounts[accountId].signersCount > 0, "TssAccountManager: account doesn't exists");
        require(
            _accounts[accountId].signersCount == v.length && _accounts[accountId].signersCount == r.length
                && _accounts[accountId].signersCount == s.length,
            "TssAccountManager: invalid signatures length"
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(abi.encodePacked(accountId, publicAddress));

        for (uint8 i = 0; i < _accounts[accountId].signersCount; i++) {
            address recoveredSigner = ECDSA.recover(message, v[i], r[i], s[i]);
            require(
                recoveredSigner == _accounts[accountId].signers[i] && recoveredSigner != address(0),
                "TssAccountManager: invalid signature"
            );
        }
        _accounts[accountId].publicAddress = publicAddress;
    }
}
