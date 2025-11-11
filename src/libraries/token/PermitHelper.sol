// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IAllowanceTransfer} from '../../interfaces/IAllowanceTransfer.sol';
import {IDaiLikePermit} from '../../interfaces/IDaiLikePermit.sol';
import {IERC721Permit_v3} from '../../interfaces/IERC721Permit_v3.sol';
import {IERC721Permit_v4} from '../../interfaces/IERC721Permit_v4.sol';
import {CalldataDecoder} from '../calldata/CalldataDecoder.sol';

import {
  IERC20Permit
} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';

library PermitHelper {
  using CalldataDecoder for bytes;

  function callERC20Permit(address token, address owner, bytes calldata permitData)
    internal
    returns (bool)
  {
    if (permitData.length == 32 * 5) {
      uint256 value = permitData.decodeUint256(0);
      uint256 deadline = permitData.decodeUint256(1);
      uint8 v = uint8(permitData.decodeUint256(2));
      bytes32 r = permitData.decodeBytes32(3);
      bytes32 s = permitData.decodeBytes32(4);

      try IERC20Permit(token).permit(owner, address(this), value, deadline, v, r, s) {
        return true;
      } catch {}
    } else if (permitData.length == 32 * 6) {
      uint256 nonce = permitData.decodeUint256(0);
      uint256 expiry = permitData.decodeUint256(1);
      bool allowed = permitData.decodeBool(2);
      uint8 v = uint8(permitData.decodeUint256(3));
      bytes32 r = permitData.decodeBytes32(4);
      bytes32 s = permitData.decodeBytes32(5);

      try IDaiLikePermit(token).permit(owner, address(this), nonce, expiry, allowed, v, r, s) {
        return true;
      } catch {}
    }
  }

  function callERC721Permit(address token, uint256 tokenId, bytes calldata permitData)
    internal
    returns (bool)
  {
    if (permitData.length == 32 * 4) {
      uint256 deadline = permitData.decodeUint256(0);
      uint8 v = uint8(permitData.decodeUint256(1));
      bytes32 r = permitData.decodeBytes32(2);
      bytes32 s = permitData.decodeBytes32(3);

      try IERC721Permit_v3(token).permit(address(this), tokenId, deadline, v, r, s) {
        return true;
      } catch {}
    } else if (permitData.length == 32 * 7) {
      uint256 deadline = permitData.decodeUint256(0);
      uint256 nonce = permitData.decodeUint256(1);
      bytes calldata signature = permitData.decodeBytes(2);

      try IERC721Permit_v4(token).permit(address(this), tokenId, deadline, nonce, signature) {
        return true;
      } catch {}
    }
  }

  function callPermit2(IAllowanceTransfer permit2, address owner, bytes calldata permit2Data)
    internal
    returns (bool)
  {
    IAllowanceTransfer.PermitBatch calldata permitBatch;
    assembly ('memory-safe') {
      permitBatch := add(permit2Data.offset, calldataload(permit2Data.offset))
    }
    bytes calldata signature = permit2Data.decodeBytes(1);

    try permit2.permit(owner, permitBatch, signature) {
      return true;
    } catch {}
  }
}
