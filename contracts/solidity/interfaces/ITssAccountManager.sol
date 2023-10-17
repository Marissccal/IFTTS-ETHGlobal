// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ITssAccountManager interface
 * @dev Interface for the TssAccountManager
 */
interface ITssAccountManager {
  function getPublicAddress(bytes32 accountId) external view returns (address);
}
