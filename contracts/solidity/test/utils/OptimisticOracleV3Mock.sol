// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract OptimisticOracleV3Mock {
  mapping(bytes32 => bool) public results;

  function settleAndGetAssertionResult(bytes32 _disputeId) external view returns (bool _result) {
    return results[_disputeId];
  }

  function setAssertionResult(bytes32 _disputeId, bool _result) external {
    results[_disputeId] = _result;
  }
}
