// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interfaces/INodeRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NodeRegistry is INodeRegistry, Ownable {
    // State variable to track active nodes
    mapping(address => bool) private _activeNodes;

    // Event to log node registration
    event NodeRegistered(address indexed node);

    // Event to log node deregistration
    event NodeDeregistered(address indexed node);

    // Function to check if a node is active
    function isActive(address node) external view override returns (bool) {
        return _activeNodes[node];
    }

    // Function to register a node
    // Only owner can register a node now
    function registerNode(address node) external override onlyOwner {
        require(!_activeNodes[node], "NodeRegistry: Node already registered");
        _activeNodes[node] = true;
        emit NodeRegistered(node);
    }

    // Function to deregister a node
    // Only owner can deregister a node now
    function deregisterNode(address node) external override onlyOwner {
        require(_activeNodes[node], "NodeRegistry: Node not registered");
        _activeNodes[node] = false;
        emit NodeDeregistered(node);
    }
}
