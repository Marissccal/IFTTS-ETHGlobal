// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NodeRegistry is INodeRegistry, Ownable {
    // State variable to track active nodes
    mapping(address => bool) private _activeNodes;

    event NodeRegistered(address indexed node);

    event NodeDeregistered(address indexed node);

    function isActive(address node) external view override returns (bool) {
        return _activeNodes[node];
    }

    function registerNode(address node) external override onlyOwner {
        require(!_activeNodes[node], "NodeRegistry: Node already registered");
        _activeNodes[node] = true;
        emit NodeRegistered(node);
    }

    function deregisterNode(address node) external override onlyOwner {
        require(_activeNodes[node], "NodeRegistry: Node not registered");
        _activeNodes[node] = false;
        emit NodeDeregistered(node);
    }
}
