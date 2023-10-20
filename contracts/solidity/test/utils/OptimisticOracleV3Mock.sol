// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract OptimisticOracleV3Mock {
    mapping(bytes32 => bool) public results;

    function settleAndGetAssertionResult(bytes32 disputeId) external view returns (bool) {
        return results[disputeId];
    }

    function setAssertionResult(bytes32 disputeId, bool result) external {
        results[disputeId] = result;
    }
}