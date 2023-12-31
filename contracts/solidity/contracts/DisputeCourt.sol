// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ITssAccountManager} from '../interfaces/ITssAccountManager.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';

contract DisputeCourt {
  uint40 public constant DISPUTE_RESOLUTION_TIME = 7 days;

  ITssAccountManager public immutable ACCOUNT_MGR;

  enum DisputeType {
    invalid,
    sigOfNonExistentRule,
    sigOfFalseFact,
    sigRequestNotFulfilled
  }

  enum DisputeStatus {
    Open, // Created disputes start at this stage
    Resolved, // This is state is when the dispute wasn't rejected (after deadline)
    Rejected // This state is when the dispute was rejected (before deadline)
  }

  struct Dispute {
    address complainant; // Address of the user who raised the dispute
    bytes32 accountId; // Id of the account in question
    DisputeType disputeType; // Reason for the dispute
    DisputeStatus status; // Status of the dispute
    uint40 deadline; // Deadline until the dispute can be challenged
  }

  Dispute[] public disputes;

  struct NonExistentRuleDispute {
    bytes message;
  }

  mapping(uint256 => NonExistentRuleDispute) internal _nonExistentRuleDisputes;

  event DisputeRaised(
    uint256 indexed _disputeId, address indexed _complainant, bytes32 indexed _accountId, DisputeType _disputeType
  );
  event DisputeResolved(uint256 indexed _disputeId);
  event DisputeRejected(uint256 indexed _disputeId);

  event NonExistentRuleDisputeRaised(uint256 indexed _disputeId, bytes _message);

  constructor(ITssAccountManager _tssAccountManager) {
    ACCOUNT_MGR = _tssAccountManager;
  }

  function _raiseDispute(bytes32 _accountId, DisputeType _disputeType) internal returns (uint256 _disputeId) {
    Dispute memory _newDispute = Dispute({
      complainant: msg.sender,
      accountId: _accountId,
      disputeType: _disputeType,
      status: DisputeStatus.Open,
      deadline: uint40(block.timestamp) + DISPUTE_RESOLUTION_TIME
    });

    disputes.push(_newDispute);
    _disputeId = disputes.length - 1;
    emit DisputeRaised(_disputeId, msg.sender, _accountId, _disputeType);
    return _disputeId;
  }

  function raiseNonExistentRuleDispute(
    bytes32 _accountId,
    bytes memory _message,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (uint256 _disputeId) {
    address _publicAddress = ACCOUNT_MGR.getPublicAddress(_accountId);
    require(_publicAddress != address(0), 'DisputeCourt: account inactive');
    bytes32 _messageHash = MessageHashUtils.toEthSignedMessageHash(_message);
    address _recoveredSigner = ECDSA.recover(_messageHash, _v, _r, _s);
    require(_publicAddress == _recoveredSigner, 'DisputeCourt: message not signed');
    _disputeId = _raiseDispute(_accountId, DisputeType.sigOfNonExistentRule);
    _nonExistentRuleDisputes[_disputeId] = NonExistentRuleDispute({message: _message});
    emit NonExistentRuleDisputeRaised(_disputeId, _message);
  }

  function resolveDispute(uint256 _disputeId) public {
    // Add multisignature exucution??
    require(disputes[_disputeId].status == DisputeStatus.Open, 'Dispute is not open');
    require(disputes[_disputeId].deadline <= block.timestamp, 'Dispute is still challengeable');
    disputes[_disputeId].status = DisputeStatus.Resolved;
    emit DisputeResolved(_disputeId);
  }

  function rejectDispute(uint256 _disputeId) public {
    // Add multisignature exucution??
    require(disputes[_disputeId].status == DisputeStatus.Open, 'Dispute is not open');
    disputes[_disputeId].status = DisputeStatus.Rejected;
    emit DisputeRejected(_disputeId);
  }
}

//   add

// Evidence Submission: Allow users to submit evidence when raising a dispute and during the dispute resolution process.

// Voting Mechanism: Implement a voting mechanism where multiple judges can vote on the outcome of a dispute.

// Penalties: Implement penalties for nodes found guilty. For instance, they could be removed from the active node list or fined.
