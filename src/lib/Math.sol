// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./FixedPoint96.sol";
import "prb-math/PRBMath.sol";

// TODO: Math rounding in milestone 5
library Math {
    error PriceX96LessThanOrEqualZero();

    function calcAmount0Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
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

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtPriceBX96 - sqrtPriceAX96;

        if (roundUp) {
            amount0 = divRoundingUp(
                mulDivRoundingUp(numerator1, numerator2, sqrtPriceBX96),
                sqrtPriceAX96
            );
        } else {
            amount0 =
                PRBMath.mulDiv(numerator1, numerator2, sqrtPriceBX96) /
                sqrtPriceAX96;
        }
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
            uint160(
                uint256(sqrtPriceX96) +
                    PRBMath.mulDiv(amountIn, FixedPoint96.Q96, liquidity)
            );
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    function divRoundingUp(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := add(
                div(numerator, denominator),
                gt(mod(numerator, denominator), 0)
            )
        }
    }
}
