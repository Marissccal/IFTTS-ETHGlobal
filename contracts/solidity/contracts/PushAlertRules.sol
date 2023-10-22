// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Facts} from './Facts.sol';

contract PushAlertRules {
  function checkHFRule(bytes memory payload, Facts.Fact[] memory facts) public view returns (bytes[] memory messages) {
    (address user, uint256 triggerHF) = abi.decode(payload, (address, uint256));
    require(facts[0].fType == Facts.FactType.ethCall);
    Facts.EthCallFact hfCall = abi.decode(facts[0].data, (Facts.EthCallFact));
    require(hfCall.targetContract == AAVE_POOL && hfCall.selector == AAVE_GET_USER_DATA);
    (,,,,, uint256 hf) = abi.decode(hfCall.result, (uint256, uint256, uint256, uint256, uint256, uint256));
    if (hf <= triggerHF) {
      return _encodePushMessage("Your AAVE health factor is under threshold!");
    }
  }
}
