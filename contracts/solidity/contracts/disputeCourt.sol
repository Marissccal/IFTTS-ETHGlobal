// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@uma/core/contracts/optimistic-oracle-v3/implementation/OptimisticOracleV3.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DisputeCourt {
    //using ECDSA for bytes32;

    enum DisputeType {
        Type1,
        Type2
    }
    enum DisputeState {
        Raised,
        Resolved,
        Rejected
    }

    struct Dispute {
        DisputeType dtype;
        DisputeState state;
        address raiser;
        bytes32 message;
        bytes signature;
        uint256 ruleNumber;
        bytes[] facts;   
        uint256 timestamp;     
    }

    uint256 public disputeTimeout = 1 hours;

    OptimisticOracleV3 public oracle;
    mapping(bytes32 => Dispute) public disputes;

    constructor(address _oracle) {
        oracle = OptimisticOracleV3(_oracle);
    }

    function ruleApplies(uint256 ruleNumber, bytes[] memory facts, bytes32 message) internal pure returns (bool) {
        ruleNumber;
        facts;
        message;
        return true;
    }

    function raiseDisputeType1(
        bytes32 message,
        bytes memory signature        
    ) external returns (bytes32) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message); 
        address signer = ECDSA.recover(messageHash, signature);        

        bytes32 disputeId = keccak256(
            abi.encodePacked(message, signer)
        );
        disputes[disputeId] = Dispute({
            dtype: DisputeType.Type1,
            state: DisputeState.Raised,
            raiser: msg.sender,
            message: message,
            signature: signature,
            ruleNumber: 0,
            facts: new bytes[](0),
            timestamp: block.timestamp
        });
        disputes[disputeId].timestamp = block.timestamp;
        return disputeId;
    }

    function raiseDisputeType2(
        bytes32 message,
        bytes memory signature,
        uint256 ruleNumber,
        bytes[] memory facts
    ) external returns (bytes32) {                        

        // TODO: Add logic to validate that the rule and facts produce the message

        bytes32 disputeId = keccak256(
            abi.encodePacked(msg.sender, message, ruleNumber)
        );
        disputes[disputeId] = Dispute({
            dtype: DisputeType.Type2,
            state: DisputeState.Raised,
            raiser: msg.sender,
            message: message,
            signature: signature,
            ruleNumber: ruleNumber,
            facts: facts,
            timestamp: block.timestamp
            
        });
        require(ruleApplies(ruleNumber, facts, message), "The rule and facts do not produce the message");
        disputes[disputeId].timestamp = block.timestamp;
        return disputeId;
    }    

    function getDispute(
        bytes32 disputeId
    )
        external
        view
        returns (
            DisputeType dtype,
            DisputeState state,
            address raiser,
            bytes32 message,
            bytes memory signature,
            uint256 ruleNumber,
            bytes[] memory facts,
            uint256 timestamp
        )
    {
        Dispute storage dispute = disputes[disputeId];
        dtype = dispute.dtype;
        state = dispute.state;
        raiser = dispute.raiser;
        message = dispute.message;
        signature = dispute.signature;
        ruleNumber = dispute.ruleNumber;
        facts = dispute.facts;
        timestamp = dispute.timestamp;
    }

    function resolveDispute(bytes32 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.state == DisputeState.Raised, "Dispute not in Raised state");
        require(block.timestamp <= dispute.timestamp + disputeTimeout, "Dispute resolution time has passed");
        
        bool result = oracle.settleAndGetAssertionResult(disputeId);
        if (result) {
            dispute.state = DisputeState.Resolved;
        } else {
            dispute.state = DisputeState.Rejected;
        }
    }

    function autoResolveDispute(bytes32 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.state == DisputeState.Raised, "Dispute not in Raised state");
        require(block.timestamp > dispute.timestamp + disputeTimeout, "Dispute resolution time has not passed yet");

        dispute.state = DisputeState.Resolved; 
    }

    function rejectDispute(bytes32 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(
            dispute.state == DisputeState.Raised,
            "Dispute not in Raised state"
        );
        
        dispute.state = DisputeState.Rejected;
    }
    
}
