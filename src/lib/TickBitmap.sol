// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library TickBitmap {
    error TickNotSpaced();

    function position(int24 tick)
        private
        pure
        returns (int16 wordPosition, uint8 bitPosition)
    {
        // divide with 2^8 = 256
        wordPosition = int16(tick >> 8);
        bitPosition = uint8(uint24(tick % 256));
    }

    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        if (tick % tickSpacing != 0) revert TickNotSpaced();
        (int16 wordPosition, uint8 bitPosition) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPosition;
        self[wordPosition] = self[wordPosition] ^ mask;
    }

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (lte) {
            (int16 wordPosition, uint8 bitPosition) = position(compressed);
            uint256 mask = (1 << bitPosition) - 1 + (1 << bitPosition);
            uint256 masked = self[wordPosition] & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed -
                    int24(
                        uint24(bitPosition - BitMath.mostSignificantBit(masked))
                    )) * tickSpacing
                : (compressed - int24(uint24(bitPosition))) * tickSpacing;
        } else {
            (int16 wordPosition, uint8 bitPosition) = position(compressed + 1);
            uint256 mask = ~((1 << bitPosition) - 1);
            uint256 masked = self[wordPosition] & mask;

            initialized = mask != 0;
            next = initialized
                ? (compressed +
                    1 +
                    int24(
                        uint24(
                            (BitMath.leastSignificantBit(masked) - bitPosition)
                        )
                    )) * tickSpacing
                : (compressed +
                    1 +
                    int24(uint24((type(uint8).max - bitPosition)))) *
                    tickSpacing;
        }
    }
}
