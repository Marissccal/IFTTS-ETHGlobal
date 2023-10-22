// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DisputeCourt} from '../../contracts/DisputeCourt.sol';
import {TssAccountManager} from '../../contracts/TssAccountManager.sol';
import {NodeRegistry} from '../../contracts/NodeRegistry.sol';
import {Test} from 'forge-std/Test.sol';

contract E2EDisputeCourt is Test {
  DisputeCourt public disputeCourt;
  TssAccountManager public accountManager;
  NodeRegistry public nodeRegistry;
  bytes32 public inactiveAccountId;
  bytes32 public activeAccountId;
  address[] public nodes;

  constructor() {
    vm.deal(address(this), 10 ether);
    nodeRegistry = new NodeRegistry(address(this));
    accountManager = new TssAccountManager(nodeRegistry);
    disputeCourt = new DisputeCourt(accountManager);
    TssAccountManager.Rule[] memory _rules;
    inactiveAccountId =
      accountManager.createAccount{value: accountManager.createAccountFee()}(2, 2, address(this), _rules);

    // Create several nodes
    for (uint256 _i = 0; _i < 5; _i++) {
      address _node = address(uint160(_i + 1));
      nodes.push(_node);
      nodeRegistry.registerNode(_node);
    }
    // Setup an account
    activeAccountId =
      accountManager.createAccount{value: accountManager.createAccountFee()}(2, 2, address(this), _rules);
    vm.prank(nodes[0]);
    accountManager.registerSigner(activeAccountId, 0, address(1001));
    vm.prank(nodes[1]);
    accountManager.registerSigner(activeAccountId, 1, address(1002));

    // TODO: call accountManager.registerPublicAddress but that will require signatures
    // Alternatives:
    // 1. Instead of TssAccountManager using a mock class that doesn't check the signatures.
    // 2. Manually creating two accounts and signing the expected messages
  }

  function testRaiseDispute() public {
    vm.expectRevert(bytes('DisputeCourt: account inactive'));
    disputeCourt.raiseNonExistentRuleDispute(inactiveAccountId, bytes('Hola'), 0, 0, 0);
    /*
        string memory reason = "Test dispute reason";

        (, , , DisputeCourt.DisputeStatus status) = disputeCourt.disputes(disputeId);
        require(disputeId == 0, "Dispute ID should be 0 for the first dispute");
        require(status == DisputeCourt.DisputeStatus.Open, "Dispute should be Open");
    */
  }

  function testResolveDispute() public {
    /*
        string memory reason = "Test dispute reason";

        uint256 disputeId = disputeCourt.raiseDispute(address(this), reason);
        disputeCourt.resolveDispute(disputeId);
        (, , , DisputeCourt.DisputeStatus status) = disputeCourt.disputes(disputeId);
        require(status == DisputeCourt.DisputeStatus.Resolved, "Dispute should be Resolved");
    */
  }

  function testRejectDispute() public {
    /*
        string memory reason = "Test dispute reason";

        uint256 disputeId = disputeCourt.raiseDispute(address(this), reason);
        disputeCourt.rejectDispute(disputeId);
        (, , , DisputeCourt.DisputeStatus status) = disputeCourt.disputes(disputeId);
        require(status == DisputeCourt.DisputeStatus.Rejected, "Dispute should be Rejected");
    */
  }
}
