// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {FinderInterface} from '@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol';
import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract OptimisticOracleV3Mock {
  using SafeERC20 for IERC20;

  FinderInterface public immutable FINDER;

  IERC20 public defaultCurrency;
  uint64 public defaultLiveness;

  mapping(bytes32 => bool) public results;

  constructor(FinderInterface _finder, IERC20 _defaultCurrency, uint64 _defaultLiveness) {
    FINDER = _finder;
    setAdminProperties(_defaultCurrency, _defaultLiveness, 0.5e18);
  }

  function setAdminProperties(IERC20 _defaultCurrency, uint64 _defaultLiveness, uint256 _burnedBondPercentage) public {
    defaultCurrency = _defaultCurrency;
    defaultLiveness = _defaultLiveness;
    _burnedBondPercentage = _burnedBondPercentage;
  }

  function settleAndGetAssertionResult(bytes32 _disputeId) external view returns (bool _result) {
    return results[_disputeId];
  }

  function setAssertionResult(bytes32 _disputeId, bool _result) external {
    results[_disputeId] = _result;
  }
}
