// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(int8(tick % 256)); //TODO: double check this
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }


    /// @notice Sets initialized state of tick to true
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to initialize
    function initializeTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] |= mask;
    }


    /// @notice Flips the initialized state for a given tick to false
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function resetTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] &= ~mask;
    }


    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal view returns (int24 next, bool initialized) {
        // start from the word of the next tick, since the current tick state doesn't matter
        (int16 wordPos, uint8 bitPos) = position(tick + 1);
        // all the 1s at or to the left of the bitPos
        uint256 mask = ~((1 << bitPos) - 1);
        uint256 masked = self[wordPos] & mask;

        // if there are no initialized ticks to the left of the current tick, return leftmost in the word
        initialized = masked != 0;
        // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
        next = initialized
            ? (tick + 1 + int24(uint24((BitMath.leastSignificantBit(masked) - bitPos))))
            : (tick + 1 + int24(uint24((type(uint8).max - bitPos))));
    }
}
