// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../contracts/disputeCourt.sol";
import "./Mocks.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract E2EDisputeCourt {
    DisputeCourt disputeCourt;
    MockOptimisticOracleV3 mockOracle;
    address externalAddress;
    bytes message = bytes("Hello World");

    function beforeEach() public {
        mockOracle = new MockOptimisticOracleV3();
        disputeCourt = new DisputeCourt(address(mockOracle));
    }

    function testRaiseDisputeType1() public {
        bytes32 hash = keccak256(abi.encodePacked(message));
        bytes memory signature = "";

        bytes32 disputeId = disputeCourt.raiseDisputeType1(message, signature);

        (
            DisputeCourt.DisputeType dtype,
            DisputeCourt.DisputeState state,
            address raiser,
            bytes memory message_,
            bytes memory signature_,
            uint256 ruleNumber,
            bytes[] memory facts
        ) = disputeCourt.getDisputeDetails(0);

        assert(dtype == DisputeCourt.DisputeType.Type1);
        assert(state == DisputeCourt.DisputeState.Raised);
        assert(raiser == address(this));
        assert(keccak256(message_) == keccak256(message));
        assert(keccak256(signature_) == keccak256(signature));
    }

    function testRaiseDisputeType2() public {
        bytes32 hash = keccak256(abi.encodePacked(message));
        bytes memory signature = "";

        uint256 ruleNumber = 3;
        bytes[] memory facts = new bytes[](2);
        facts[0] = bytes("Fact 1");
        facts[1] = bytes("Fact 2");

        bytes32 disputeId = disputeCourt.raiseDisputeType2(message, signature, ruleNumber, facts);

        (
            DisputeCourt.DisputeType dtype,
            DisputeCourt.DisputeState state,
            address raiser,
            bytes memory message_,
            bytes memory signature_,
            uint256 ruleNumber_,
            bytes[] memory facts_
        ) = disputeCourt.getDisputeDetails(0);

        assert(dtype == DisputeCourt.DisputeType.Type2);
        assert(state == DisputeCourt.DisputeState.Raised);
        assert(raiser == address(this));
        assert(keccak256(message_) == keccak256(message));
        assert(keccak256(signature_) == keccak256(signature));
        assert(ruleNumber_ == ruleNumber);
        assert(facts_.length == 2);
        assert(keccak256(facts_[0]) == keccak256(facts[0]));
        assert(keccak256(facts_[1]) == keccak256(facts[1]));
    }

    function testResolveDispute() public {
        bytes32 hash = keccak256(abi.encodePacked(message));
        bytes memory signature = "";

        uint256 ruleNumber = 3;
        bytes[] memory facts = new bytes[](2);
        facts[0] = bytes("Fact 1");
        facts[1] = bytes("Fact 2");

        bytes32 disputeId = disputeCourt.raiseDisputeType2(
            message,
            signature,
            ruleNumber,
            facts
        );
        mockOracle.setAssertionResult(disputeId, true);

        disputeCourt.resolveDispute(disputeId);

        (
            DisputeCourt.DisputeType dtype,
            DisputeCourt.DisputeState state,
            address raiser,
            bytes memory message_,
            bytes memory signature_,
            uint256 ruleNumber_,
            bytes[] memory facts_
        ) = disputeCourt.getDispute(0);

        assert(state == DisputeCourt.DisputeState.Resolved);
    }

    function testRejectDispute() public {
        bytes32 hash = keccak256(abi.encodePacked(message));
        bytes memory signature = "";

        uint256 ruleNumber = 3;
        bytes[] memory facts = new bytes[](2);
        facts[0] = bytes("Fact 1");
        facts[1] = bytes("Fact 2");

        bytes32 disputeId = disputeCourt.raiseDisputeType2(
            message,
            signature,
            ruleNumber,
            facts
        );
        disputeCourt.rejectDispute(disputeId);

        (
            DisputeCourt.DisputeType dtype,
            DisputeCourt.DisputeState state,
            address raiser,
            bytes memory message_,
            bytes memory signature_,
            uint256 ruleNumber_,
            bytes[] memory facts_
        ) = disputeCourt.getDispute(0);

        assert(state == DisputeCourt.DisputeState.Rejected);
    }
}
