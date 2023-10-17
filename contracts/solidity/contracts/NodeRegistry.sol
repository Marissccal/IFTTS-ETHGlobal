// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {INodeRegistry} from "../interfaces/INodeRegistry.sol";

contract NodeRegistry is Ownable, INodeRegistry {
    // State variable to track active nodes
    mapping(address => bool) private _activeNodes;

    event NodeRegistered(address indexed node);

    event NodeDeregistered(address indexed node);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function isActive(address node) external override view  returns (bool) {
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
