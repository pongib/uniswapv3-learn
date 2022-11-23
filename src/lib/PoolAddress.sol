// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../UniswapV3Pool.sol";

library PoolAddress {
    error TokenNotSorted();

    function computeAddress(
        address factory,
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (address pool) {
        if (token0 >= token1) revert TokenNotSorted();

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1, fee)),
                            keccak256(type(UniswapV3Pool).creationCode)
                        )
                    )
                )
            )
        );
    }
}
