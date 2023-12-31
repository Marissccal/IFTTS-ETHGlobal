// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title INodeRegistry interface
 * @dev Interface for the register of active nodes that can participate in the decentralized signature process.
 */
interface INodeRegistry {
  function isActive(address _node) external view returns (bool _isActive);
  function registerNode(address _node) external;
  function deregisterNode(address _node) external;
}
