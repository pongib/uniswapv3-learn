// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Math.sol";

library SwapMath {
    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 fee
    )
        internal
        pure
        returns (
            uint160 sqrtPriceNextX96,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        uint256 amountRemainingLessFee = PRBMath.mulDiv(
            amountRemaining,
            1e6 - fee,
            1e6
        );

        bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;

        amountIn = zeroForOne
            ? Math.calcAmount0Delta(
                sqrtPriceCurrentX96,
                sqrtPriceTargetX96,
                liquidity
            )
            : Math.calcAmount1Delta(
                sqrtPriceCurrentX96,
                sqrtPriceTargetX96,
                liquidity
            );

        if (amountRemainingLessFee >= amountIn) {
            sqrtPriceNextX96 = sqrtPriceTargetX96;
        } else {
            sqrtPriceNextX96 = Math.getNextSqrtPrictFromInput(
                sqrtPriceCurrentX96,
                liquidity,
                amountRemainingLessFee,
                zeroForOne
            );
        }

        bool max = sqrtPriceNextX96 == sqrtPriceTargetX96;

        if (!max) {
            //  the current price range has enough liquidity to fulfill the swap
            feeAmount = amountRemaining - amountIn;
        } else {
            feeAmount = Math.mulDivRoundingUp(amountIn, fee, 1e6 - fee);
        }

        amountIn = Math.calcAmount0Delta(
            sqrtPriceCurrentX96,
            sqrtPriceNextX96,
            liquidity
        );

        amountOut = Math.calcAmount1Delta(
            sqrtPriceCurrentX96,
            sqrtPriceNextX96,
            liquidity
        );

        if (!zeroForOne) {
            (amountIn, amountOut) = (amountOut, amountIn);
        }
    }
}
