// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ITssAccountManager} from '../interfaces/ITssAccountManager.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {OptimisticOracleV3} from '@uma/core/contracts/optimistic-oracle-v3/implementation/OptimisticOracleV3.sol';
import {Facts} from './Facts.sol';

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

  enum OracleStatus {
    NotRequested,
    Requested,
    Resolved
  }

  struct Dispute {
    address complainant; // Address of the user who raised the dispute
    bytes32 accountId; // Id of the account in question
    DisputeType disputeType; // Reason for the dispute
    DisputeStatus status; // Status of the dispute
    uint40 deadline; // Deadline until the dispute can be challenged
  }

  struct OracleRequest {
    OracleStatus status;
    uint40 deadline;
  }

  Dispute[] public disputes;

  struct NonExistentRuleDispute {
    bytes message;
  }

  mapping(uint256 => NonExistentRuleDispute) internal _nonExistentRuleDisputes;

  mapping(uint256 => OracleRequest) public oracleRequests;

  event DisputeRaised(
    uint256 indexed _disputeId, address indexed _complainant, bytes32 indexed _accountId, DisputeType _disputeType
  );
  event DisputeResolved(uint256 indexed _disputeId);
  event DisputeRejected(uint256 indexed _disputeId);

  event NonExistentRuleDisputeRaised(uint256 indexed _disputeId, bytes _message);

  OptimisticOracleV3 public optimisticOracleV3Instance;

  constructor(ITssAccountManager _tssAccountManager, address _optimisticOracleV3Address) {
    ACCOUNT_MGR = _tssAccountManager;
    optimisticOracleV3Instance = OptimisticOracleV3(_optimisticOracleV3Address);
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

    optimisticOracleV3Instance.getAssertionResult(keccak256(abi.encodePacked(_disputeId)));
    oracleRequests[_disputeId] =
      OracleRequest({status: OracleStatus.Requested, deadline: uint40(block.timestamp) + DISPUTE_RESOLUTION_TIME});
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
    bytes32 _messageHash = ECDSA.toEthSignedMessageHash(_message);
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
    require(oracleRequests[_disputeId].deadline <= block.timestamp, 'Oracle result is still challengeable');

    bool _result = optimisticOracleV3Instance.settleAndGetAssertionResult(keccak256(abi.encodePacked(_disputeId)));
    if (_result) {
      disputes[_disputeId].status = DisputeStatus.Resolved;
      emit DisputeResolved(_disputeId);
    } else {
      disputes[_disputeId].status = DisputeStatus.Rejected;
      emit DisputeRejected(_disputeId);
    }

    oracleRequests[_disputeId].status = OracleStatus.Resolved;
  }

  function resolveFalseFactDispute(
    bytes32 _accountId,
    uint256 _ruleIndex,
    Facts.Fact[] memory _facts
  ) external returns (uint256 _disputeId) {
    require(msg.sender == address(ACCOUNT_MGR), 'DisputeCourt: Only TssAccountManager can resolve false facts');

    require(_accountId != bytes32(0), 'DisputeCourt: Invalid accountId');
    require(_nonExistentRuleDisputes[_ruleIndex].message.length > 0, 'DisputeCourt: Invalid ruleIndex');

    bytes[] memory _messages = ACCOUNT_MGR.messagesToSignFromFacts(_accountId, _ruleIndex, _facts);
    for (uint256 _i = 0; _i < _messages.length; _i++) {
      require(_messages[_i].length == 0, 'DisputeCourt: Fact is not false');
    }

    _disputeId = _raiseDispute(_accountId, DisputeType.sigOfFalseFact);

    optimisticOracleV3Instance.getAssertionResult(keccak256(abi.encodePacked(_disputeId)));
    oracleRequests[_disputeId] =
      OracleRequest({status: OracleStatus.Requested, deadline: uint40(block.timestamp) + DISPUTE_RESOLUTION_TIME});

    return _disputeId;
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
