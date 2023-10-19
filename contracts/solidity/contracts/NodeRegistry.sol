// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {INodeRegistry} from '../interfaces/INodeRegistry.sol';

contract NodeRegistry is Ownable, INodeRegistry {
  // State variable to track active nodes
  mapping(address => bool) private _activeNodes;

  event NodeRegistered(address indexed _node);

  event NodeDeregistered(address indexed _node);

  constructor(address _initialOwner) Ownable(_initialOwner) {}

  function isActive(address _node) external view override returns (bool _isActive) {
    return _activeNodes[_node];
  }

  function registerNode(address _node) external override onlyOwner {
    require(!_activeNodes[_node], 'NodeRegistry: already registered');
    _activeNodes[_node] = true;
    emit NodeRegistered(_node);
  }

  function deregisterNode(address _node) external override onlyOwner {
    require(_activeNodes[_node], 'NodeRegistry: not registered');
    _activeNodes[_node] = false;
    emit NodeDeregistered(_node);
  }
}
