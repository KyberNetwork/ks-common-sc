// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import 'forge-std/interfaces/IERC721.sol';

import 'src/interfaces/IERC721Permit_v3.sol';
import 'src/interfaces/IERC721Permit_v4.sol';
import 'src/libraries/token/PermitHelper.sol';

import 'openzeppelin-contracts/contracts/utils/Nonces.sol';
import 'openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol';

contract PermitTest is Test {
  using PermitHelper for *;

  bytes32 constant PERMIT_TYPEHASH =
    0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

  IAllowanceTransfer permit2 = IAllowanceTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

  address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address uniswapV3NFT = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
  uint256 uniswapV3TokenId = 11;

  address uniswapV4NFT = 0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e;
  uint256 uniswapV4TokenId = 36_880;

  Vm.Wallet public testWallet = vm.createWallet('test wallet');

  function setUp() public {
    vm.createSelectFork(vm.envString('ETH_NODE_URL'), 22_930_000);

    address owner = IERC721(uniswapV3NFT).ownerOf(uniswapV3TokenId);
    vm.prank(owner);
    IERC721(uniswapV3NFT).transferFrom(owner, testWallet.addr, uniswapV3TokenId);

    owner = IERC721(uniswapV4NFT).ownerOf(uniswapV4TokenId);
    vm.prank(owner);
    IERC721(uniswapV4NFT).transferFrom(owner, testWallet.addr, uniswapV4TokenId);
  }

  /* ========== ERC721 PERMIT TESTS ========== */
  function test_callERC721Permit_v3() public {
    bytes32 digest = MessageHashUtils.toTypedDataHash(
      IERC721Permit_v3(uniswapV3NFT).DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          IERC721Permit_v3(uniswapV3NFT).PERMIT_TYPEHASH(),
          address(this),
          uniswapV3TokenId,
          0,
          block.timestamp + 1 days
        )
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);
    bool success = this.callERC721Permit(
      uniswapV3NFT, uniswapV3TokenId, abi.encode(block.timestamp + 1 days, v, r, s)
    );
    assertEq(success, true);
  }

  function test_callERC721Permit_v4() public {
    bytes32 digest = MessageHashUtils.toTypedDataHash(
      IERC721Permit_v3(uniswapV4NFT).DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          IERC721Permit_v3(uniswapV3NFT).PERMIT_TYPEHASH(),
          address(this),
          uniswapV4TokenId,
          0,
          block.timestamp + 1 days
        )
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);
    bytes memory signature = abi.encodePacked(r, s, v);

    bool success = this.callERC721Permit(
      uniswapV4NFT, uniswapV4TokenId, abi.encode(block.timestamp + 1 days, 0, signature)
    );
    assertEq(success, true);
  }

  /* ========== ERC20 PERMIT TESTS ========== */
  function test_callERC20Permit_dai() public {
    console.log('nonce', Nonces(DAI).nonces(address(this)));

    bytes32 digest = MessageHashUtils.toTypedDataHash(
      IERC20Permit(DAI).DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          IDaiLikePermit(DAI).PERMIT_TYPEHASH(),
          testWallet.addr,
          address(this),
          0,
          block.timestamp + 1 days,
          true
        )
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);

    bool success = this.callERC20Permit(
      DAI, testWallet.addr, abi.encode(0, block.timestamp + 1 days, true, v, r, s)
    );
    assertEq(success, true);
  }

  function test_callERC20Permit_usdc() public {
    bytes32 digest = MessageHashUtils.toTypedDataHash(
      IERC20Permit(USDC).DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          IDaiLikePermit(USDC).PERMIT_TYPEHASH(),
          testWallet.addr,
          address(this),
          1 ether,
          0,
          block.timestamp + 1 days
        )
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(testWallet, digest);

    bool success = this.callERC20Permit(
      USDC, testWallet.addr, abi.encode(1 ether, block.timestamp + 1 days, v, r, s)
    );
    assertEq(success, true);
  }

  function callERC721Permit(address token, uint256 tokenId, bytes calldata permitData)
    external
    returns (bool success)
  {
    success = token.callERC721Permit(tokenId, permitData);
  }

  function callERC20Permit(address token, address owner, bytes calldata permitData)
    external
    returns (bool success)
  {
    success = token.callERC20Permit(owner, permitData);
  }

  function callPermit2(address owner, bytes calldata permit2Data) external returns (bool success) {
    success = permit2.callPermit2(owner, permit2Data);
  }
}
