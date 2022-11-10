// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Math {
    error PriceX96LessThanOrEqualZero();

    function calcAmount0Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        // prevent underflow when subtract
        if (sqrtPriceAX96 > sqrtPriceBX96
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        // prevent divide by zero or negative amount
        if (sqrtPriceAX96 <= 0) revert PriceX96LessThanOrEqualZero();

        // Formular
        // amount0 =
        //     (liquidity * (sqrtPriceBX96 - sqrtPriceAX96)) /
        //     (sqrtPriceBX96 * sqrtPriceAX96);

        amount0 = divRoundingUp(
            mulDivRoundingUp(
                (uint256(liquidity) << FixedPoint96.RESOLUTION),
                (sqrtPriceBX96 - sqrtPriceAX96),
                sqrtPriceBX96
            ),
            sqrtPriceAX96
        );
    }

    function calcAmount1Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        // prevent underflow when subtract
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        // formular
        // amount1 = liquidity * (sqrtPriceBX96 - sqrtPriceAX96);

        amount1 = mulDivRoundingUp(
            liquidity,
            (sqrtPriceBX96 - sqrtPriceAX96),
            FixedPoint96.Q96
        );
    }
}
