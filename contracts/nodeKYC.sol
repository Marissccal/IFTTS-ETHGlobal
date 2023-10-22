// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {GenesisUtils} from "@iden3/contracts/lib/GenesisUtils.sol";
import {ICircuitValidator} from "@iden3/contracts/interfaces/ICircuitValidator.sol";
import {ZKPVerifier} from "@iden3/contracts/verifiers/ZKPVerifier.sol";

contract NodeKYC is Ownable, ZKPVerifier {
    uint64 public constant TRANSFER_REQUEST_ID = 1;
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;
    mapping(address => bool) private _activeNodes;

    event NodeRegistered(address indexed node);
    event NodeDeregistered(address indexed node);

    constructor(string memory name_, string memory symbol_) {}

    function isActive(address node) external view returns (bool) {
        return _activeNodes[node];
    }

    function registerNode(address node) public {
        require(!_activeNodes[node], "NodeRegistry: Node already registered");
        _activeNodes[node] = true;
        emit NodeRegistered(node);
    }

    function deregisterNode(address node) external onlyOwner {
        require(_activeNodes[node], "NodeRegistry: Node not registered");
        _activeNodes[node] = false;
        emit NodeDeregistered(node);
    }

    function _beforeProofSubmit(
        uint64 /* requestId */,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        address addr = GenesisUtils.int256ToAddress(
            inputs[validator.getChallengeInputIndex()]
        );
        require(
            _msgSender() == addr,
            "address in proof is not a sender address"
        );
    }

    function _afterProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal override {
        require(
            requestId == TRANSFER_REQUEST_ID && addressToId[_msgSender()] == 0,
            "proof can not be submitted more than once"
        );
        uint256 id = inputs[1];
        registerNode(msg.sender);
    }
}
