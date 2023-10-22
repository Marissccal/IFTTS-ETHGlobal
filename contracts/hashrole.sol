// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashVerificationContract {
    // The expected hash value
    bytes32 private expectedHash;

    // Constructor to set the expected hash value from the original data
    constructor(bytes32 _expectedhash) {
        expectedHash = _expectedhash;
    }

    // Modifier to check if the keccak256 of the provided original data matches the expected hash
    modifier validData(bytes32 _originalData) {
        require(keccak256(abi.encodePacked(_originalData)) == expectedHash, "Invalid data provided");
        _;
    }

    // Function that can only be executed with the correct original data that matches the stored hash
    function executeFunction(bytes32 _originalData) public validData(_originalData) {}
}
