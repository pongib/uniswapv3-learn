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
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }
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

    function getNextSqrtPrictFromInput(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtPriceNextX96) {
        sqrtPriceNextX96 = zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amountIn
            )
            : getNextSqrtPriceFromAmount1RoundingDown(
                sqrtPriceX96,
                liquidity,
                amountIn
            );
    }

    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {
        uint256 numerator = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 product = amountIn * sqrtPriceX96;

        // check not overflow use more precise formular
        if (product / amountIn == sqrtPriceX96) {
            uint256 denominator = product + numerator;
            if (denominator >= numerator) {
                return
                    uint160(
                        mulDivRoundingUp(sqrtPriceX96, numerator, denominator)
                    );
            }
        }

        // less precise but support when product overflow
        return
            uint160(
                divRoundingUp(numerator, amountIn + (numerator / sqrtPriceX96))
            );
    }

    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {
        return
            sqrtPriceX96 +
            uint160((amountIn << FixedPoint96.RESOLUTION) / liquidity);
    }
}
