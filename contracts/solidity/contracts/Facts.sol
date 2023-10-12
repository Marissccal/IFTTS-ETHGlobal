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
    unknown,  // To skip uint(FactType) ==  0
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

  function decodeEthEventFact(Fact memory fact) internal pure returns (EthEventFact memory ret) {
    require(fact.fType == FactType.ethEvent, "Facts: invalid fact type");
    (ret) = abi.decode(fact.data, (EthEventFact));
    return ret;
  }

  function decodeEthCallFact(Fact memory fact) internal pure returns (EthCallFact memory ret) {
    require(fact.fType == FactType.ethEvent, "Facts: invalid fact type");
    (ret) = abi.decode(fact.data, (EthCallFact));
    return ret;
  }

  function decodeEthBalanceFact(Fact memory fact) internal pure returns (EthBalanceFact memory ret) {
    require(fact.fType == FactType.ethEvent, "Facts: invalid fact type");
    (ret) = abi.decode(fact.data, (EthBalanceFact));
    return ret;
  }

  function decodeEthNonceFact(Fact memory fact) internal pure returns (EthNonceFact memory ret) {
    require(fact.fType == FactType.ethEvent, "Facts: invalid fact type");
    (ret) = abi.decode(fact.data, (EthNonceFact));
    return ret;
  }

  function decodeEthBlockFact(Fact memory fact) internal pure returns (EthBlockFact memory ret) {
    require(fact.fType == FactType.ethEvent, "Facts: invalid fact type");
    (ret) = abi.decode(fact.data, (EthBlockFact));
    return ret;
  }
}
