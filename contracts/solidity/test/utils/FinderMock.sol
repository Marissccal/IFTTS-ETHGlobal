// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {FinderInterface} from '@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol';

contract FinderMock is FinderInterface {
  mapping(bytes32 => address) public interfaces;

  function changeImplementationAddress(bytes32 _interfaceName, address _implementationAddress) external override {
    interfaces[_interfaceName] = _implementationAddress;
  }

  function getImplementationAddress(bytes32 _interfaceName)
    external
    view
    override
    returns (address _implementationAddress)
  {
    _implementationAddress = interfaces[_interfaceName];
    return _implementationAddress;
  }
}
