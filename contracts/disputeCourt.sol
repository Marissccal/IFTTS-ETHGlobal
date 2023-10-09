// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract DisputeCourt {

    enum DisputeStatus { Open, Resolved, Rejected }

    struct Dispute {
        address complainant; // Address of the user who raised the dispute
        address node; // Address of the node in question
        string reason; // Reason for the dispute
        DisputeStatus status; // Status of the dispute
    }

    Dispute[] public disputes;

    event DisputeRaised(uint256 indexed disputeId, address indexed complainant, address indexed node, string reason);
    event DisputeResolved(uint256 indexed disputeId);
    event DisputeRejected(uint256 indexed disputeId);

    function raiseDispute(address _node, string memory _reason) public returns (uint256) {
        Dispute memory newDispute = Dispute({
            complainant: msg.sender,
            node: _node,
            reason: _reason,
            status: DisputeStatus.Open
        });

        disputes.push(newDispute);
        uint256 disputeId = disputes.length - 1;
        emit DisputeRaised(disputeId, msg.sender, _node, _reason);
        return disputeId;
    }

    function resolveDispute(uint256 _disputeId) public {
        // Add multisignature exucution??
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not open");
        disputes[_disputeId].status = DisputeStatus.Resolved;
        emit DisputeResolved(_disputeId);
    }

    function rejectDispute(uint256 _disputeId) public {
       // Add multisignature exucution??
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not open");
        disputes[_disputeId].status = DisputeStatus.Rejected;
        emit DisputeRejected(_disputeId);
    }
}


//   add

// Evidence Submission: Allow users to submit evidence when raising a dispute and during the dispute resolution process.

// Voting Mechanism: Implement a voting mechanism where multiple judges can vote on the outcome of a dispute.

// Penalties: Implement penalties for nodes found guilty. For instance, they could be removed from the active node list or fined.