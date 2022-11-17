// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library BytesLibExt {
    error Uint24OutOfBounds();

    function toUint24(bytes memory bytes_, uint256 start_)
        internal
        pure
        returns (uint24 tempUint)
    {
        if (bytes_.length < start_ + 3) revert Uint24OutOfBounds();

        assembly {
            tempUint := mload(add(add(bytes_, 0x3), start_))
        }
    }
}
