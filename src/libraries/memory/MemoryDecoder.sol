// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Library for abi decoding in memory
library MemoryDecoder {
  error SliceOutOfBounds();

  /// @notice equivalent to SliceOutOfBounds.selector, stored in least-significant bits
  uint256 internal constant SLICE_ERROR_SELECTOR = 0x3b99b53d;

  function decodeAddress(bytes memory _bytes) internal pure returns (address value) {
    assembly ('memory-safe') {
      value := mload(add(_bytes, 0x20))
    }
  }

  function decodeAddress(bytes memory _bytes, uint256 _arg) internal pure returns (address value) {
    assembly ('memory-safe') {
      value := mload(add(_bytes, add(0x20, shl(5, _arg))))
    }
  }

  function decodeUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly ('memory-safe') {
      value := mload(add(_bytes, 0x20))
    }
  }

  function decodeUint256(bytes memory _bytes, uint256 _arg) internal pure returns (uint256 value) {
    assembly ('memory-safe') {
      value := mload(add(_bytes, add(0x20, shl(5, _arg))))
    }
  }

  function decodeBytes32(bytes memory _bytes) internal pure returns (bytes32 value) {
    assembly ('memory-safe') {
      value := mload(add(_bytes, 0x20))
    }
  }

  function decodeBytes32(bytes memory _bytes, uint256 _arg) internal pure returns (bytes32 value) {
    assembly ('memory-safe') {
      value := mload(add(_bytes, add(0x20, shl(5, _arg))))
    }
  }

  /// @notice Decode the first element in `_bytes` as `bytes`
  /// @param _bytes The input bytes string to extract a bytes string from
  function decodeBytes(bytes memory _bytes) internal pure returns (bytes memory res) {
    return decodeBytes(_bytes, 0);
  }

  /// @notice Decode the `_arg`-th element in `_bytes` as `bytes`
  /// @dev No copy is made. The element begins with its own length word, which is exactly what a
  /// `bytes memory` pointer expects, so the result aliases `_bytes`.
  /// @param _bytes The input bytes string to extract a bytes string from
  /// @param _arg The index of the argument to extract
  function decodeBytes(bytes memory _bytes, uint256 _arg) internal pure returns (bytes memory res) {
    assembly ('memory-safe') {
      // The data part starts after the length word; the `_arg`-th head word holds the element's
      // offset measured from there. shl(5, x) is equivalent to mul(32, x)
      let dataStart := add(_bytes, 0x20)
      res := add(dataStart, mload(add(dataStart, shl(5, _arg))))

      // if the provided bytes string isnt as long as the encoding says, revert
      if lt(add(mload(_bytes), dataStart), add(mload(res), add(res, 0x20))) {
        mstore(0, SLICE_ERROR_SELECTOR)
        revert(0x1c, 4)
      }
    }
  }

  /// @notice Overwrite the 32-byte word at `offset` bytes into `_bytes`
  /// @param _bytes The buffer to patch, modified in place
  /// @param offset Byte offset from the start of the payload
  /// @param value The word to write
  function mstore(bytes memory _bytes, uint256 offset, bytes32 value)
    internal
    pure
    returns (bytes memory)
  {
    assembly ('memory-safe') {
      mstore(add(_bytes, add(offset, 0x20)), value)
    }
    return _bytes;
  }
}
