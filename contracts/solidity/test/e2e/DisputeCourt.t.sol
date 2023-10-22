// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DisputeCourt} from '../../contracts/DisputeCourt.sol';
import {TssAccountManager} from '../../contracts/TssAccountManager.sol';
import {NodeRegistry} from '../../contracts/NodeRegistry.sol';
import {OptimisticOracleV3} from '@uma/core/contracts/optimistic-oracle-v3/implementation/OptimisticOracleV3.sol';
import {Finder} from '@uma/core/contracts/data-verification-mechanism/implementation/Finder.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {Test} from 'forge-std/Test.sol';


contract E2EDisputeCourt is Test {         
  DisputeCourt public disputeCourt;
  OptimisticOracleV3 public accountOracle;
  TssAccountManager public accountManager;
  Finder public finder;  
  NodeRegistry public nodeRegistry;
  bytes32 public inactiveAccountId;
  bytes32 public activeAccountId;
  address[] public nodes;       
  IERC20 public defaultCurrency; 
  uint64 public defaultLiveness;
  uint256 public startAt;
  

  constructor(address _erc20Address) {
    startAt = block.timestamp;
    vm.deal(address(this), 10 ether);    
    nodeRegistry = new NodeRegistry(address(this));
    accountManager = new TssAccountManager(nodeRegistry);
    finder = new Finder();    
    defaultCurrency = IERC20(_erc20Address);
    defaultLiveness = 100;
    accountOracle = new OptimisticOracleV3(finder, defaultCurrency, defaultLiveness); 
    disputeCourt = new DisputeCourt(accountManager, accountOracle);
    TssAccountManager.Rule[] memory _rules;
    inactiveAccountId =
      accountManager.createAccount{value: accountManager.createAccountFee()}(2, 2, address(this), _rules);

    // Create several nodes
    for (uint256 _i = 0; _i < 5; _i++) {
      address _node = address(uint160(_i + 1));
      nodes.push(_node);
      nodeRegistry.registerNode(address(this));
    }
    // Setup an account
    activeAccountId =
      accountManager.createAccount{value: accountManager.createAccountFee()}(2, 2, address(this), _rules);
    vm.prank(nodes[0]);
    accountManager.registerSigner(activeAccountId, 0, address(1001));
    vm.prank(nodes[1]);
    accountManager.registerSigner(activeAccountId, 1, address(1002));
  }
  

  function testRaiseDispute() public {
    // Try raising a dispute for an inactive account
    
    vm.expectRevert(bytes('DisputeCourt: account inactive'));
    disputeCourt.raiseNonExistentRuleDispute(inactiveAccountId, bytes('Hi'), 0, 0, 0);
       
  }

  function testResolveDispute() public {
    /*
    bytes memory _message = bytes("Hello");
    bytes32 _messageHash = ECDSA.toEthSignedMessageHash(_message);
    bytes memory signature = vm.sign(_messageHash); 
    
    uint8 v;
    bytes32 r;
    bytes32 s;
    (bytes memory r, bytes memory s, uint8 v) = vm.sign(_messageHash, nodes[0]);

    uint256 disputeId = disputeCourt.raiseNonExistentRuleDispute(activeAccountId, _message, v, r, s);
    
    vm.warp(startAt + 8 days);
    disputeCourt.resolveDispute(disputeId);
    
    DisputeCourt.DisputeStatus status = disputeCourt.disputes(disputeId).status;
    vm.assertEqual(uint(status), uint(DisputeCourt.DisputeStatus.Resolved), "The dispute should be resolved");
*/
}


  
}
