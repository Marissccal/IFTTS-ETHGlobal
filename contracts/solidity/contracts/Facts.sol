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

  struct EthBlockFact {
    uint32 chainId;
    bytes32 blockHash;
    uint32 blockNumber;
    uint40 timestamp;
    bytes32 parentBlockHash;
    uint16 minConfirmations;
  }

  function decodeEthEventFact(bytes memory data) internal pure returns (EthEventFact memory ret) {
    (ret) = abi.decode(data, (EthEventFact));
    return ret;
  }

  function decodeEthCallFact(bytes memory data) internal pure returns (EthCallFact memory ret) {
    (ret) = abi.decode(data, (EthCallFact));
    return ret;
  }

  function decodeEthBalanceFact(bytes memory data) internal pure returns (EthBalanceFact memory ret) {
    (ret) = abi.decode(data, (EthBalanceFact));
    return ret;
  }

  function decodeEthBlockFact(bytes memory data) internal pure returns (EthBlockFact memory ret) {
    (ret) = abi.decode(data, (EthBlockFact));
    return ret;
  }

}
