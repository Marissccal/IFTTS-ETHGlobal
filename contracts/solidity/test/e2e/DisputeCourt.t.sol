// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../../contracts/disputeCourt.sol";
import "./Mocks.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract E2EDisputeCourtTest is Test {
    DisputeCourt public disputeCourt;
    address dummyOracle = address(0); 
    uint256 private startAt;

    constructor() {
        disputeCourt = new DisputeCourt(dummyOracle);
        startAt = block.timestamp;
    }

    function getMessageHash(
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function testRaiseDisputeType1() public {
        string memory message = "Hello World";
        bytes
            memory signature = hex"487646cdc119c536137467b592b52485c22fd41488f12b5e7f0a70471ae95f7e1e90d5e9687cda52ddb632ec397a3686c2d5d85fad6ea048fc6bb72f5354adcf1c";
        assert(signature.length == 65);

        bytes32 messageHash = getMessageHash(message);        

        bytes32 disputeId = disputeCourt.raiseDisputeType1(
            messageHash,
            signature
        );

        (
            DisputeCourt.DisputeType dtype,
            DisputeCourt.DisputeState state,
            ,
            ,
            ,
            ,
            bytes[] memory facts,
            
        ) = disputeCourt.getDispute(disputeId);

        assert(uint(dtype) == uint(DisputeCourt.DisputeType.Type1));
        assert(uint(state) == uint(DisputeCourt.DisputeState.Raised));
        assert(facts.length == 0);
    }

    function testAutoResolveDispute() public {
        string memory message = "Hello World";
        bytes memory signature = hex"487646cdc119c536137467b592b52485c22fd41488f12b5e7f0a70471ae95f7e1e90d5e9687cda52ddb632ec397a3686c2d5d85fad6ea048fc6bb72f5354adcf1c"; 
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(message)));
        
        bytes32 disputeId = disputeCourt.raiseDisputeType1(messageHash, signature);
        
        vm.warp(startAt + 2 hours);

        disputeCourt.autoResolveDispute(disputeId);

        (, DisputeCourt.DisputeState state, , , , , , ) = disputeCourt.getDispute(disputeId);
        assert(uint(state) == uint(DisputeCourt.DisputeState.Resolved));
    }
}
