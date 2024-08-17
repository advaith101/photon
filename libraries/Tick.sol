// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import './TickMath.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {

    /// Tick indexed state
    struct Info {
        uint256 tokenXAmount;
        uint256 tokenYAmount;
        uint256 lastInitializationTimestamp;
        uint128 multiplier; //Q64.64 multiplier
        bool initialized;
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tokenXDelta The amount of tokenX to be added/removed from tick
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tokenXDelta,
        uint256 tokenYDelta,
        bool isRemove
    ) internal returns (bool flipped, uint128 tickMultiplier) {
        require(tokenXDelta != 0);
        Tick.Info storage info = self[tick];
        uint256 prevTokenXAmount = info.tokenXAmount;

        if (isRemove) {
            require(tokenXDelta <= prevTokenXAmount, 'E');
            info.tokenXAmount -= tokenXDelta;
            info.tokenYAmount -= tokenYDelta;
        } else {
            info.tokenXAmount += tokenXDelta;
        }

        if (prevTokenXAmount == 0) {
            info.initialized = true;
            info.lastInitializationTimestamp = block.timestamp;
            flipped = true;
        } else if (isRemove && tokenXDelta == prevTokenXAmount) {
            delete self[tick];
            flipped = true;
        }
        tickMultiplier = info.multiplier;
    }

    /// @notice Executes a tick (with given tokenX) and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenXDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function execute(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenXDelta
    ) internal returns (bool flipped, uint256 requiredTokenYAmount, uint256 usedTokenXAmount) {
        Tick.Info storage info = self[tick];
        uint256 prevTokenXAmount = info.tokenXAmount;
        if (prevTokenXAmount == 0) return (true, 0, 0);

        usedTokenXAmount = tokenXDelta;
        if (usedTokenXAmount >= prevTokenXAmount) {
            usedTokenXAmount = prevTokenXAmount;
            delete self[tick];
            flipped = true;
        } else {
            uint128 currRatio = ABDKMath64x64.divuu(prevTokenXAmount, prevTokenXAmount - usedTokenXAmount); //rounds towards -infinity
            uint128 currTickMultiplier = info.multiplier;
            if (currTickMultiplier == 0) {
                info.multiplier = currRatio;
            } else {
                info.multiplier = uint128(ABDKMath64x64.mul(int128(currTickMultiplier), int128(currRatio))); //rounds towards +infinity
            }
            info.tokenXAmount -= usedTokenXAmount;
        }
        requiredTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, usedTokenXAmount);
        if (!flipped && usedTokenXAmount == tokenXDelta) {
            //partial execution on last tick in swap
            info.tokenYAmount += requiredTokenYAmount;
        }
    }

    /// @notice Executes a tick (with given tokenY) and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenYDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function executeWithTokenY(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenYDelta
    ) internal returns (bool flipped, uint256 requiredTokenXAmount, uint256 usedTokenYAmount) {
        Tick.Info storage info = self[tick];
        uint256 prevTokenXAmount = info.tokenXAmount;
        if (prevTokenXAmount == 0) return (true, 0, 0);

        requiredTokenXAmount = TickMath.getOutputTokenXAmount(tick, tickMode, tokenYDelta);
        if (requiredTokenXAmount >= prevTokenXAmount) {
            requiredTokenXAmount = prevTokenXAmount;
            delete self[tick];
            flipped = true;
        } else {
            uint128 currRatio = ABDKMath64x64.divuu(prevTokenXAmount, prevTokenXAmount - requiredTokenXAmount);
            uint128 currTickMultiplier = info.multiplier;
            if (currTickMultiplier == 0){
                info.multiplier = currRatio;
            } else {
                info.multiplier = uint128(ABDKMath64x64.mul(int128(currTickMultiplier), int128(currRatio)));
            }
            info.tokenXAmount -= requiredTokenXAmount;
        }
        usedTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, requiredTokenXAmount);
        if (!flipped && usedTokenYAmount == tokenYDelta) {
            //partial execution on last tick in swap
            info.tokenYAmount += usedTokenYAmount;
        }
    }



    /// @notice Simulates execution of a tick and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenXDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function simulateExecute(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenXDelta
    ) internal view returns (uint256 requiredTokenYAmount, uint256 usedTokenXAmount) {
        uint256 prevTokenXAmount = self[tick].tokenXAmount;
        if (prevTokenXAmount == 0) return (0, 0);
        usedTokenXAmount = (tokenXDelta > prevTokenXAmount) ? prevTokenXAmount : tokenXDelta;
        requiredTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, usedTokenXAmount);
    }

    /// @notice Simulates execution of a tick (with tokenY) and returns if the tick is to be flipped and the required tokenYAmount for execution (partial or full)
    /// @dev can only be called on an initialized tick
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be executed
    /// @param tokenYDelta The amount of tokenX to be executed from tick (amount tokenX remaining in swap loop)
    function simulateExecuteWithTokenY(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 tickMode,
        uint256 tokenYDelta
    ) internal view returns (uint256 requiredTokenXAmount, uint256 usedTokenYAmount) {
        uint256 prevTokenXAmount = self[tick].tokenXAmount;
        if (prevTokenXAmount == 0) return (0, 0);
        requiredTokenXAmount = TickMath.getOutputTokenXAmount(tick, tickMode, tokenYDelta);
        if (requiredTokenXAmount > prevTokenXAmount) {
            requiredTokenXAmount = prevTokenXAmount;
        }
        usedTokenYAmount = TickMath.getOutputTokenYAmount(tick, tickMode, requiredTokenXAmount);
    }
}
