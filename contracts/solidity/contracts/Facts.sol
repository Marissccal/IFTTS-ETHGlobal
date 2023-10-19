// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title Facts library
 * @dev Library for the implementation of the different facts.
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
library Facts {
  enum FactType {
    unknown, // To skip uint(FactType) ==  0
    ethEvent,
    ethCall,
    ethBalance,
    ethNonce,
    ethBlock
  }

  struct Fact {
    FactType fType;
    bytes data;
  }

  struct EthEventFact {
    uint32 chainId;
    bytes32[] topics;
    bytes32 data;
    bytes32 txHash;
    uint32 logIndex;
    bytes32 blockHash;
    uint32 blockNumber;
    uint40 timestamp;
    uint16 minConfirmations;
  }

  struct EthCallFact {
    uint32 chainId;
    address targetContract;
    bytes4 selector;
    bytes data;
    bytes result;
    bytes32 blockHash;
    uint32 blockNumber;
    uint40 timestamp;
    uint16 minConfirmations;
  }

  struct EthBalanceFact {
    uint32 chainId;
    address account;
    uint256 balance;
    bytes32 blockHash;
    uint32 blockNumber;
    uint40 timestamp;
    uint16 minConfirmations;
  }

  struct EthNonceFact {
    uint32 chainId;
    address account;
    uint256 nonce;
    bytes32 blockHash;
    uint32 blockNumber;
    uint40 timestamp;
    uint16 minConfirmations;
  }

  struct EthBlockFact {
    uint32 chainId;
    bytes32 blockHash;
    uint32 blockNumber;
    uint40 timestamp;
    bytes32 parentBlockHash;
    uint16 minConfirmations;
  }

  function decodeEthEventFact(Fact memory _fact) internal pure returns (EthEventFact memory _ret) {
    require(_fact.fType == FactType.ethEvent, 'Facts: invalid fact type');
    (_ret) = abi.decode(_fact.data, (EthEventFact));
    return _ret;
  }

  function decodeEthCallFact(Fact memory _fact) internal pure returns (EthCallFact memory _ret) {
    require(_fact.fType == FactType.ethEvent, 'Facts: invalid fact type');
    (_ret) = abi.decode(_fact.data, (EthCallFact));
    return _ret;
  }

  function decodeEthBalanceFact(Fact memory _fact) internal pure returns (EthBalanceFact memory _ret) {
    require(_fact.fType == FactType.ethEvent, 'Facts: invalid fact type');
    (_ret) = abi.decode(_fact.data, (EthBalanceFact));
    return _ret;
  }

  function decodeEthNonceFact(Fact memory _fact) internal pure returns (EthNonceFact memory _ret) {
    require(_fact.fType == FactType.ethEvent, 'Facts: invalid fact type');
    (_ret) = abi.decode(_fact.data, (EthNonceFact));
    return _ret;
  }

  function decodeEthBlockFact(Fact memory _fact) internal pure returns (EthBlockFact memory _ret) {
    require(_fact.fType == FactType.ethEvent, 'Facts: invalid fact type');
    (_ret) = abi.decode(_fact.data, (EthBlockFact));
    return _ret;
  }
}
