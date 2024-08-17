// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './ABDKMath64x64.sol';

/// @title Math library for computing prices from ticks and vice versa
/// @notice Computes price for ticks of size 1.0001, i.e. (1.0001^tick) as fixed point Q64.64 numbers. Supports
/// prices between 2**-64 and 2**63, with a resolution of 2**-64
library TickMath {
    /// @dev The minimum tick that may be passed to #getPriceRatioAtTick computed from log base 1.0001 of 2**-64
    int24 internal constant MIN_TICK = -443646;
    /// @dev The maximum tick that may be passed to #getPriceRatioAtTick computed from log base 1.0001 of 2**63
    int24 internal constant MAX_TICK = 436704;

    // /// TODO: FIGURE THIS SHIT OUT
    // /// @dev The minimum value that can be returned from #getPriceRatioAtTick. Equivalent to getPriceRatioAtTick(MIN_TICK)
    // uint128 internal constant MIN_PRICE_RATIO = 4295128739;
    // /// @dev The maximum value that can be returned from #getPriceRatioAtTick. Equivalent to getPriceRatioAtTick(MAX_TICK)
    // uint128 internal constant MAX_PRICE_RATIO = 1461446703485210103287273052203988822378723970342;


    /// @notice Calculates 1.0001^tick * 2^64
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return priceX64 A Fixed point Q64.64 number representing the ratio of the two assets (tokenY/tokenX)
    /// at the given tick
    function getPriceRatioAtTick(int24 tick, uint256 tickMode) internal pure returns (int128 priceX64) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

        if (tickMode == 0) {
            // Q64.64 equivalent of 1.0001 => 1.0001 * 2**64 (with correct precision) = 18448588748116922571
            priceX64 = ABDKMath64x64.pow(18448588748116922571, absTick);
        } else if (tickMode == 1) {
            // Q64.64 equivalent of 1.001 => 1.001 * 2**64 (with correct precision) = 18465190817783261167
            priceX64 = ABDKMath64x64.pow(18465190817783261167, absTick);
        } else {
            // Q64.64 equivalent of 1.01 => 1.01 * 2**64 (with correct precision) = 18631211514446647132
            priceX64 = ABDKMath64x64.pow(18631211514446647132, absTick);
        }

        if (tick < 0) priceX64 = ABDKMath64x64.inv(priceX64);
    }


    /// @notice Calculates output amount of tokenY for given tick and tokenXAmount
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return tokenYAmount A Fixed point Q64.64 number representing the ratio of the two assets (tokenY/tokenX)
    /// at the given tick
    function getOutputTokenYAmount(int24 tick, uint256 tickMode, uint256 tokenXAmount) internal pure returns (uint256 tokenYAmount) {
        int128 priceX64 = getPriceRatioAtTick(tick, tickMode);
        tokenYAmount = ABDKMath64x64.mulu(priceX64, tokenXAmount);
    }


    /// @notice Calculates output amount of tokenX for given tick and tokenYAmount
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return tokenXAmount A Fixed point Q64.64 number representing the ratio of the two assets (tokenY/tokenX)
    /// at the given tick
    function getOutputTokenXAmount(int24 tick, uint256 tickMode, uint256 tokenYAmount) internal pure returns (uint256 tokenXAmount) {
        int128 priceY64 = getPriceRatioAtTick(-tick, tickMode);
        tokenXAmount = ABDKMath64x64.mulu(priceY64, tokenYAmount);
        if (getOutputTokenYAmount(tick, tickMode, tokenXAmount) < tokenYAmount) ++tokenXAmount; //round up if necessary
    }
}
