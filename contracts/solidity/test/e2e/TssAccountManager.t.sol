// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {TssAccountManager} from '../../contracts/TssAccountManager.sol';
import {NodeRegistryMock} from '../utils/NodeRegistryMock.sol';
import {MessageHashUtils} from 'openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import {Test} from 'forge-std/Test.sol';

contract E2ETssAccountManagerTest is Test {
  TssAccountManager public tssAccountManager;
  NodeRegistryMock public nodeRegistry;

  uint256 internal _signer;
  uint256 internal _owner;
  uint256 internal _node;
  uint256 internal _publicAddress;

  uint256 internal _ownerPrivateKey;
  uint256 internal _nodePrivateKeys;
  uint256 internal _signerPrivateKey;
  uint256 internal _publicAddressPrivateKey;

  constructor() {
    nodeRegistry = new NodeRegistryMock();
    tssAccountManager = new TssAccountManager(nodeRegistry);
  }

  function testCreateAccount() public returns (bool _success) {
    bytes32 _accountId =
      tssAccountManager.createAccount{value: 1 ether}(1, 1, address(this), new TssAccountManager.Rule[](0));
    require(tssAccountManager.getPublicAddress(_accountId) == address(0), 'Account should not have public address set.');
    return true;
  }

  function testRegisterNodeAndSigner() public payable returns (bool _success) {
    bytes32 _accountId =
      tssAccountManager.createAccount{value: 1 ether}(1, 1, address(this), new TssAccountManager.Rule[](0));
    nodeRegistry.registerNode(address(this));
    tssAccountManager.registerSigner(_accountId, 0, address(this));
    require(tssAccountManager.getPublicAddress(_accountId) == address(0), 'Account should not have public address set.');
    return true;
  }

  function testRegisterPublicAddress() public returns (bool _success) {
    _ownerPrivateKey = 0xabc123;
    _nodePrivateKeys = 0xabc1234;
    _signerPrivateKey = 0xabc124;
    _publicAddressPrivateKey = 0xabc125;

    address _ownerAddr = vm.addr(_ownerPrivateKey);
    address _signerAddr = vm.addr(_signerPrivateKey);
    address _publicAddr = vm.addr(_publicAddressPrivateKey);

    bytes32 _accountId =
      tssAccountManager.createAccount{value: 1 ether}(1, 1, _ownerAddr, new TssAccountManager.Rule[](0));

    nodeRegistry.registerNode(address(this));
    tssAccountManager.registerSigner(_accountId, 0, _signerAddr);

    bytes32 _message = MessageHashUtils.toEthSignedMessageHash(abi.encodePacked(_accountId, _publicAddr));

    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_signerPrivateKey, _message);

    uint8[] memory _vs = new uint8[](1);
    bytes32[] memory _rs = new bytes32[](1);
    bytes32[] memory _ss = new bytes32[](1);

    _vs[0] = _v;
    _rs[0] = _r;
    _ss[0] = _s;

    tssAccountManager.registerPublicAddress(_accountId, _publicAddr, _vs, _rs, _ss);

    require(tssAccountManager.getPublicAddress(_accountId) == _publicAddr, 'Error: Public address not set correctly.');

    return true;
  }
}
