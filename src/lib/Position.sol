// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "prb-math/PRBMath.sol";

import "./LiquidityMath.sol";

library Position {
    struct Info {
        uint128 liquidity;
        uint256 feeGrowthInsideLast0X128;
        uint256 feeGrowthInsideLast1X128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function update(
        Info storage self,
        uint128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        // reverse of fee per liquidity in swap.
        uint128 tokensOwed0 = uint128(
            PRBMath.mulDiv(
                feeGrowthInside0X128 - self.feeGrowthInside0LastX128,
                self.liquidity,
                FiexedPoint128.Q128
            )
        );

        uint128 tokensOwed1 = uint128(
            PRBMath.mulDiv(
                feeGrowthInside1X128 - self.feeGrowthInside1LastX128,
                self.liquidity,
                FixedPoint128.Q128
            )
        );

        self.liquidity = LiquidityMath.addLiquidity(
            self.liquidity,
            liquidityDelta
        );
        self.feeGrowthInsideLast0X128 = feeGrowthInside0X128;
        self.feeGrowthInsideLast1X128 = feeGrowthInside1X128;

        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }
    }

    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 lowerTick,
        int24 upperTick
    ) internal view returns (Position.Info storage position) {
        position = self[
            keccak256(abi.encodePacked(owner, lowerTick, upperTick))
        ];
    }
}
