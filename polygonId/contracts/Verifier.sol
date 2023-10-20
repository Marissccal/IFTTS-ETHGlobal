// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GenesisUtils} from "@iden3/contracts/lib/GenesisUtils.sol";
import {ICircuitValidator} from "@iden3/contracts/interfaces/ICircuitValidator.sol";
import {ZKPVerifier} from "@iden3/contracts/verifiers/ZKPVerifier.sol";
import {NodeRegister} from "./NodeRegister.sol";

contract Verifier is ZKPVerifier, NodeRegister {
    address public constant nodeRegisterAddress = 0x05DE9b2D90FAd9B3212486b4e7ab1d7839aA98a3;
    NodeRegister public nodeRegister;
    
    uint64 public constant TRANSFER_REQUEST_ID = 1;

    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;



    constructor(string memory name_, string memory symbol_)
       {}

    function _beforeProofSubmit(
        uint64, /* requestId */
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        // check that  challenge input is address of sender
        address addr = GenesisUtils.int256ToAddress(
            inputs[validator.getChallengeInputIndex()]
        );
        // this is linking between msg.sender and
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

        // get user id
        uint256 id = inputs[1];
        
        NodeRegister(nodeRegisterAddress).registerNode(msg.sender);
    }

}