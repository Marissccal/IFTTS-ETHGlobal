// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {INodeRegistry} from '../../interfaces/INodeRegistry.sol';

contract NodeRegistryMock is INodeRegistry {
  mapping(address => bool) public nodes;

  function isActive(address _node) external view override returns (bool _isActive) {
    return nodes[_node];
  }

  function registerNode(address _node) external override {
    nodes[_node] = true;
  }

  function deregisterNode(address _node) external override {
    nodes[_node] = false;
  }
}
