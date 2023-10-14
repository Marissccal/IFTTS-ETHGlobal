// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../contracts/disputeCourt.sol";

contract E2EDisputeCourt {
    DisputeCourt public disputeCourt;

    constructor() {
        disputeCourt = new DisputeCourt();
    }

    function testRaiseDispute() public {
        string memory reason = "Test dispute reason";
        
        uint256 disputeId = disputeCourt.raiseDispute(address(this), reason);
        (, , , DisputeCourt.DisputeStatus status) = disputeCourt.disputes(disputeId);
        require(disputeId == 0, "Dispute ID should be 0 for the first dispute");
        require(status == DisputeCourt.DisputeStatus.Open, "Dispute should be Open");
    }

    function testResolveDispute() public {
        string memory reason = "Test dispute reason";
        
        uint256 disputeId = disputeCourt.raiseDispute(address(this), reason);
        disputeCourt.resolveDispute(disputeId);
        (, , , DisputeCourt.DisputeStatus status) = disputeCourt.disputes(disputeId);
        require(status == DisputeCourt.DisputeStatus.Resolved, "Dispute should be Resolved");
    }

    function testRejectDispute() public {
        string memory reason = "Test dispute reason";
        
        uint256 disputeId = disputeCourt.raiseDispute(address(this), reason);
        disputeCourt.rejectDispute(disputeId);
        (, , , DisputeCourt.DisputeStatus status) = disputeCourt.disputes(disputeId);
        require(status == DisputeCourt.DisputeStatus.Rejected, "Dispute should be Rejected");
    }
}
