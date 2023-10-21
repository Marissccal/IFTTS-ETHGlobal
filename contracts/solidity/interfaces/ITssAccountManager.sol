// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Facts} from '../contracts/Facts.sol';

/**
 * @title ITssAccountManager interface
 * @dev Interface for the TssAccountManager
 */
interface ITssAccountManager {
  function getPublicAddress(bytes32 _accountId) external view returns (address _publicAddress);

  function messagesToSignFromFacts(
    bytes32 _accountId,
    uint256 _ruleIndex,
    Facts.Fact[] memory _facts
  ) external view returns (bytes[] memory _messagesToSign);
}
