// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@uma/core/contracts/optimistic-oracle-v3/implementation/OptimisticOracleV3.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DisputeCourt {
    using ECDSA for bytes32;

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
        bytes message;
        bytes signature;
        uint256 ruleNumber;
        bytes[] facts;
    }

    OptimisticOracleV3 public oracle;
    mapping(bytes32 => Dispute) public disputes;

    constructor(address _oracle) {
        oracle = OptimisticOracleV3(_oracle);
    }

    function raiseDisputeType1(
        bytes memory message,
        bytes memory signature
    ) external returns (bytes32) {
        bytes32 messageHash = toEthSignedMessageHash(abi.encodePacked(message));
        address signer = messageHash.recover(signature);
        //require(signer == msg.sender, "Invalid signature");

        bytes32 disputeId = keccak256(
            abi.encodePacked(msg.sender, message, block.timestamp)
        );
        disputes[disputeId] = Dispute({
            dtype: DisputeType.Type1,
            state: DisputeState.Raised,
            raiser: msg.sender,
            message: message,
            signature: signature,
            ruleNumber: 0,
            facts: new bytes[](0)
            //timestamp: block.timestamp
        });
        return disputeId;
    }

    function raiseDisputeType2(
        bytes memory message,
        bytes memory signature,
        uint256 ruleNumber,
        bytes[] memory facts
    ) external returns (bytes32) {
        bytes32 messageHash = toEthSignedMessageHash(abi.encodePacked(message));
        address signer = messageHash.recover(signature);
        //require(signer == msg.sender, "Invalid signature");

        // TODO: Add logic to validate that the rule and facts produce the message

        bytes32 disputeId = keccak256(
            abi.encodePacked(msg.sender, message, ruleNumber, block.timestamp)
        );
        disputes[disputeId] = Dispute({
            dtype: DisputeType.Type2,
            state: DisputeState.Raised,
            raiser: msg.sender,
            message: message,
            signature: signature,
            ruleNumber: ruleNumber,
            facts: facts
            //timestamp: block.timestamp
        });
              return disputeId;
    }

    function getDisputeDetails(
        bytes32 disputeId
    )
        external
        view
        returns (
            DisputeType dtype,
            DisputeState state,
            address raiser,
            bytes memory message,
            bytes memory signature,
            uint256 ruleNumber,
            bytes[] memory facts
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
            bytes memory message,
            bytes memory signature,
            uint256 ruleNumber,
            bytes[] memory facts
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
    }

    function resolveDispute(bytes32 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(
            dispute.state == DisputeState.Raised,
            "Dispute not in Raised state"
        );
        
        bool result = oracle.settleAndGetAssertionResult(disputeId);
        if (result) {
            dispute.state = DisputeState.Resolved;
        } else {
            dispute.state = DisputeState.Rejected;
        }
    }

    function rejectDispute(bytes32 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(
            dispute.state == DisputeState.Raised,
            "Dispute not in Raised state"
        );
        
        dispute.state = DisputeState.Rejected;
    }

    function toEthSignedMessageHash(
        bytes memory _message
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(_message)
                )
            );
    }
}
