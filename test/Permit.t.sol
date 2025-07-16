// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import 'forge-std/interfaces/IERC721.sol';

import 'src/interfaces/IERC721Permit_v3.sol';
import 'src/interfaces/IERC721Permit_v4.sol';
import 'src/libraries/token/PermitHelper.sol';

contract MockERC20Permit is IERC20Permit, IDaiLikePermit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) pure external {
    require(owner != address(0), 'Invalid owner');
    require(spender != address(0), 'Invalid spender');
    require(value != 0, 'Invalid value');
    require(deadline != 0, 'Invalid deadline');
    require(v != 0, 'Invalid v');
    require(r != bytes32(0), 'Invalid r');
    require(s != bytes32(0), 'Invalid s');
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32) {}

  function nonces(address owner) external view returns (uint256) {}

  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) pure external {
    require(holder != address(0), 'Invalid holder');
    require(spender != address(0), 'Invalid spender');
    require(nonce != 0, 'Invalid nonce');
    require(expiry != 0, 'Invalid expiry');
    require(allowed, 'Invalid allowed');
    require(v != 0, 'Invalid v');
    require(r != bytes32(0), 'Invalid r');
    require(s != bytes32(0), 'Invalid s');
  }
}

contract PermitTest is Test {
  using PermitHelper for address;

  string ETH_RPC_URL = vm.envString('ETH_NODE_URL');
  uint256 constant FORK_BLOCK = 22_930_000;

  bytes32 constant PERMIT_TYPEHASH =
    0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

  address uniV3NFT = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
  address uniV4NFT = 0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e;
  uint256 uniV3TokenId = 11;
  uint256 uniV4TokenId = 36_880;
  address uniV3TokenOwner = 0x11921c9c14bA2ccd34cEf17c01C0Ef36ffad8713;
  address uniV4TokenOwner = 0x1f2F10D1C40777AE1Da742455c65828FF36Df387;
  address spender;
  address mockERC20Permit;
  Vm.Wallet public testWallet = vm.createWallet('test wallet');

  function setUp() public {
    vm.createSelectFork(ETH_RPC_URL, FORK_BLOCK);
    vm.prank(uniV3TokenOwner);
    IERC721(uniV3NFT).transferFrom(uniV3TokenOwner, testWallet.addr, uniV3TokenId);
    vm.prank(uniV4TokenOwner);
    IERC721(uniV4NFT).transferFrom(uniV4TokenOwner, testWallet.addr, uniV4TokenId);
    spender = address(this);
    mockERC20Permit = address(new MockERC20Permit());
  }

  /* ========== ERC721 PERMIT TESTS ========== */
  function test_uniV3Permit() public {
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        IERC721Permit_v3(uniV3NFT).DOMAIN_SEPARATOR(),
        keccak256(
          abi.encode(
            IERC721Permit_v3(uniV3NFT).PERMIT_TYPEHASH(),
            spender,
            uniV3TokenId,
            0,
            block.timestamp + 1 days
          )
        )
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);
    bytes memory callData = abi.encode(block.timestamp + 1 days, v, r, s);
    bool success = PermitTest(address(this)).erc721Permit(uniV3NFT, uniV3TokenId, callData);
    assertEq(success, true);
  }

  function test_uniV4Permit() public {
    bytes32 digest = _hashTypedData(_hashPermit(spender, uniV4TokenId, 0, block.timestamp + 1 days));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);
    bytes memory signature = abi.encodePacked(r, s, v);

    bytes memory callData = abi.encode(block.timestamp + 1 days, 0, signature);

    bool success = PermitTest(address(this)).erc721Permit(uniV4NFT, uniV4TokenId, callData);
    assertEq(success, true);
  }

  /* ========== ERC20 PERMIT TESTS ========== */
  function test_DaiLikePermit() public {
    bytes32 digest = bytes32('random');
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);
    bytes memory callData = abi.encode(10, block.timestamp + 1 days, true, v, r, s);

    bool success = PermitTest(address(this)).erc20Permit(mockERC20Permit, callData);
    assertEq(success, true);
  }

  function test_erc20Permit() public {
    bytes32 digest = bytes32('random');
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);
    bytes memory callData = abi.encode(1 ether, block.timestamp + 1 days, v, r, s);
    bool success = PermitTest(address(this)).erc20Permit(mockERC20Permit, callData);
    assertEq(success, true);
  }

  function erc721Permit(address token, uint256 tokenId, bytes calldata permitData)
    external
    returns (bool success)
  {
    success = PermitHelper.erc721Permit(token, tokenId, permitData);
  }

  function erc20Permit(address token, bytes calldata permitData) external returns (bool success) {
    success = PermitHelper.erc20Permit(token, permitData);
  }

  function _hashPermit(address _spender, uint256 tokenId, uint256 nonce, uint256 deadline)
    internal
    pure
    returns (bytes32 digest)
  {
    // equivalent to: keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonce, deadline));
    assembly ("memory-safe") {
      let fmp := mload(0x40)
      mstore(fmp, PERMIT_TYPEHASH)
      mstore(add(fmp, 0x20), and(_spender, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(fmp, 0x40), tokenId)
      mstore(add(fmp, 0x60), nonce)
      mstore(add(fmp, 0x80), deadline)
      digest := keccak256(fmp, 0xa0)

      // now clean the memory we used
      mstore(fmp, 0) // fmp held PERMIT_TYPEHASH
      mstore(add(fmp, 0x20), 0) // fmp+0x20 held spender
      mstore(add(fmp, 0x40), 0) // fmp+0x40 held tokenId
      mstore(add(fmp, 0x60), 0) // fmp+0x60 held nonce
      mstore(add(fmp, 0x80), 0) // fmp+0x80 held deadline
    }
  }

  function _hashTypedData(bytes32 dataHash) internal view returns (bytes32 digest) {
    // equal to keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), dataHash));
    bytes32 domainSeparator = IERC721Permit_v3(uniV4NFT).DOMAIN_SEPARATOR();
    assembly ("memory-safe") {
      let fmp := mload(0x40)
      mstore(fmp, hex'1901')
      mstore(add(fmp, 0x02), domainSeparator)
      mstore(add(fmp, 0x22), dataHash)
      digest := keccak256(fmp, 0x42)

      // now clean the memory we used
      mstore(fmp, 0) // fmp held "\x19\x01", domainSeparator
      mstore(add(fmp, 0x20), 0) // fmp+0x20 held domainSeparator, dataHash
      mstore(add(fmp, 0x40), 0) // fmp+0x40 held dataHash
    }
  }
}
