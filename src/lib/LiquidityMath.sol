// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./FixedPoint96.sol";
import "prb-math/PRBMath.sol";

library LiquidityMath {
    function getLiquidityForAmount0(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        // liquidity = (amount0 * sqrtPriceBX96 * sqrtPriceAX96 / FixedPoint96.Q96) / sqrtPriceBX96 - sqrtPriceAX96

        uint256 intermediate = PRBMath.mulDiv(
            sqrtPriceAX96,
            sqrtPriceBX96,
            FixedPoint96.Q96
        );

        liquidity = uint128(
            PRBMath.mulDiv(amount0, intermediate, sqrtPriceBX96 - sqrtPriceAX96)
        );
    }

    function getLiquidityForAmount1(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        // liquidity = amount1 * FixedPoint96.Q96 / (sqrtPriceBX96 - sqrtPriceAX96);

        liquidity = uint128(
            PRBMath.mulDiv(
                amount1,
                FixedPoint96.Q96,
                sqrtPriceBX96 - sqrtPriceAX96
            )
        );
    }

    function getLiquidityForAmounts(
        uint160 sqrtPriceX96, // currentTick
        uint160 sqrtPriceAX96, // lowerTick
        uint160 sqrtPriceBX96, // upperTick
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint160 liquidity) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        if (sqrtPriceX96 <= sqrtPriceAX96) {
            liquidity = getLiquidityForAmount0(
                sqrtPriceAX96,
                sqrtPriceBX96,
                amount0
            );
        } else if (sqrtPriceX96 <= sqrtPriceBX96) {
            uint160 liquidity0 = getLiquidityForAmount0(
                sqrtPriceAX96,
                sqrtPriceBX96,
                amount0
            );
            uint160 liquidity1 = getLiquidityForAmount1(
                sqrtPriceAX96,
                sqrtPriceBX96,
                amount0
            );

            liquidity = liquidity0 <= liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(
                sqrtPriceAX96,
                sqrtPriceBX96,
                amount1
            );
        }
    }
}
