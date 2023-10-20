// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";

contract FinderMock is FinderInterface {
    mapping(bytes32 => address) public interfaces;

    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external override {
        interfaces[interfaceName] = implementationAddress;
    }

    function getImplementationAddress(bytes32 interfaceName) external view override returns (address) {
        return interfaces[interfaceName];
    }
}
