// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

/// @title AntiSandwichHook
/// @notice Uniswap v4 Hook that detects sandwich attack patterns in stable asset markets
/// @dev Implements risk score calculation and dynamic fee adjustment to protect LPs and users
contract AntiSandwichHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // ============================================================
    // Constants
    // ============================================================

    /// @notice Weights for risk score calculation
    /// @dev These weights determine the importance of each metric in the risk score
    uint8 private constant W1_RELATIVE_SIZE = 50;      // Weight for relative trade size
    uint8 private constant W2_DELTA_PRICE = 30;       // Weight for price delta
    uint8 private constant W3_SPIKE_COUNT = 20;       // Weight for consecutive spikes

    /// @notice Threshold for considering a trade as a "spike"
    /// @dev If relativeSize > SPIKE_THRESHOLD, increment recentSpikeCount
    uint256 private constant SPIKE_THRESHOLD = 5;

    // ============================================================
    // Storage Structure
    // ============================================================

    /// @notice Storage structure per pool
    /// @dev Each pool has its own risk tracking and configuration
    struct PoolStorage {
        uint160 lastPrice;              // Last pool price (sqrtPriceX96)
        uint256 lastTradeSize;           // Size of the previous swap
        uint256 avgTradeSize;            // Simple moving average of trade sizes
        uint8 recentSpikeCount;          // Counter of consecutive large trades
        uint24 lowRiskFee;               // Fee for low risk (default: 5 bps = 0.05%)
        uint24 mediumRiskFee;            // Fee for medium risk (default: 20 bps = 0.20%)
        uint24 highRiskFee;              // Fee for high risk (default: 60 bps = 0.60%)
        uint8 riskThresholdLow;          // Low risk threshold (default: 50)
        uint8 riskThresholdHigh;         // High risk threshold (default: 150)
    }

    /// @notice Storage mapping per pool
    mapping(PoolId => PoolStorage) public poolStorage;

    // ============================================================
    // Events
    // ============================================================

    /// @notice Emitted when pool configuration is updated
    event PoolConfigUpdated(
        PoolId indexed poolId,
        uint24 lowRiskFee,
        uint24 mediumRiskFee,
        uint24 highRiskFee,
        uint8 riskThresholdLow,
        uint8 riskThresholdHigh
    );

    /// @notice Emitted when dynamic fee is applied based on risk score
    event DynamicFeeApplied(
        PoolId indexed poolId,
        uint8 riskScore,
        uint24 appliedFee,
        uint256 relativeSize,
        uint160 deltaPrice,
        uint8 recentSpikeCount
    );

    /// @notice Emitted when metrics are updated after a swap
    event MetricsUpdated(
        PoolId indexed poolId,
        uint160 newPrice,
        uint256 newAvgTradeSize,
        uint8 newSpikeCount
    );

    // ============================================================
    // Constructor
    // ============================================================

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    // ============================================================
    // Hook Permissions
    // ============================================================

    /// @notice Returns the hook permissions
    /// @dev Only beforeSwap and afterSwap are enabled for MVP
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ============================================================
    // Hook Functions (Placeholders - to be implemented in next steps)
    // ============================================================

    /// @notice Hook called before a swap
    /// @dev Will implement risk score calculation and dynamic fee in Paso 1.4
    /// @param sender The address initiating the swap
    /// @param key The pool key
    /// @param params Swap parameters including amountIn/amountOut
    /// @param hookData Additional hook data (unused for now)
    /// @return selector The function selector
    /// @return delta The swap delta (zero for now)
    /// @return fee The dynamic fee to apply (to be calculated)
    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // TODO: Implement in Paso 1.4
        // 1. Get current price from pool using poolManager.getSlot0(poolId)
        // 2. Get tradeSize from params (amountIn or amountSpecified)
        // 3. Call _calculateRiskScore() (to be implemented in Paso 1.2)
        // 4. Call _calculateDynamicFee() (to be implemented in Paso 1.3)
        // 5. Return (selector, BeforeSwapDelta, dynamicFee)
        // 6. Emit DynamicFeeApplied event
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    /// @notice Hook called after a swap
    /// @dev Will implement metrics update in Paso 1.5
    /// @param sender The address that initiated the swap
    /// @param key The pool key
    /// @param params Swap parameters
    /// @param delta The balance delta from the swap
    /// @param hookData Additional hook data (unused for now)
    /// @return selector The function selector
    /// @return amount The amount to return (zero for now)
    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        // TODO: Implement in Paso 1.5
        // 1. Get current price from pool after swap
        // 2. Get tradeSize from params
        // 3. Update lastPrice = currentPrice
        // 4. Update avgTradeSize = (avgTradeSize * 9 + tradeSize) / 10
        // 5. Calculate relativeSize = tradeSize / avgTradeSize
        // 6. Update recentSpikeCount:
        //    - If relativeSize > 5: recentSpikeCount++
        //    - Else: recentSpikeCount = 0
        // 7. Emit MetricsUpdated event
        
        return (BaseHook.afterSwap.selector, 0);
    }

    // ============================================================
    // Internal Helper Functions (Placeholders - to be implemented)
    // ============================================================

    /// @notice Calculates the risk score based on trade size, price delta, and consecutive spikes
    /// @dev To be implemented in Paso 1.2
    /// @param poolId The pool identifier
    /// @param currentPrice The current pool price (sqrtPriceX96)
    /// @param tradeSize The size of the current trade
    /// @return riskScore The calculated risk score (0-255)
    function _calculateRiskScore(
        PoolId poolId,
        uint160 currentPrice,
        uint256 tradeSize
    ) internal view returns (uint8 riskScore) {
        // TODO: Implement in Paso 1.2
        // Formula: riskScore = (W1 * relativeSize) + (W2 * deltaPrice) + (W3 * recentSpikeCount)
        // Where:
        // - relativeSize = tradeSize / avgTradeSize (handle division by zero)
        // - deltaPrice = abs(currentPrice - lastPrice)
        // - recentSpikeCount from storage
        return 0;
    }

    /// @notice Calculates the dynamic fee based on risk score
    /// @dev To be implemented in Paso 1.3
    /// @param poolId The pool identifier
    /// @param riskScore The calculated risk score
    /// @return fee The dynamic fee in basis points
    function _calculateDynamicFee(
        PoolId poolId,
        uint8 riskScore
    ) internal view returns (uint24 fee) {
        // TODO: Implement in Paso 1.3
        // if (riskScore < riskThresholdLow) return lowRiskFee;
        // else if (riskScore < riskThresholdHigh) return mediumRiskFee;
        // else return highRiskFee;
        return 0;
    }

    // ============================================================
    // Configuration Functions (Placeholders - to be implemented in Paso 1.6)
    // ============================================================

    /// @notice Sets the configuration for a pool
    /// @dev Only owner can call (to be implemented with access control in Paso 1.6)
    /// @param key The pool key
    /// @param _lowRiskFee Fee for low risk swaps (in basis points)
    /// @param _mediumRiskFee Fee for medium risk swaps (in basis points)
    /// @param _highRiskFee Fee for high risk swaps (in basis points)
    /// @param _riskThresholdLow Low risk threshold
    /// @param _riskThresholdHigh High risk threshold
    function setPoolConfig(
        PoolKey calldata key,
        uint24 _lowRiskFee,
        uint24 _mediumRiskFee,
        uint24 _highRiskFee,
        uint8 _riskThresholdLow,
        uint8 _riskThresholdHigh
    ) external {
        // TODO: Implement in Paso 1.6
        // 1. Add onlyOwner modifier
        // 2. Validate parameters:
        //    - Fees > 0 and <= 10000 (100%)
        //    - lowRiskFee < mediumRiskFee < highRiskFee
        //    - riskThresholdLow < riskThresholdHigh
        // 3. Update poolStorage[key.toId()]
        // 4. Emit PoolConfigUpdated event
    }

    /// @notice Gets the current configuration for a pool
    /// @param poolId The pool identifier
    /// @return config The pool configuration
    function getPoolConfig(PoolId poolId) external view returns (PoolStorage memory config) {
        return poolStorage[poolId];
    }

    /// @notice Gets the current metrics for a pool
    /// @param poolId The pool identifier
    /// @return lastPrice The last recorded price
    /// @return avgTradeSize The current average trade size
    /// @return recentSpikeCount The current spike count
    function getPoolMetrics(PoolId poolId)
        external
        view
        returns (uint160 lastPrice, uint256 avgTradeSize, uint8 recentSpikeCount)
    {
        PoolStorage storage storage_ = poolStorage[poolId];
        return (storage_.lastPrice, storage_.avgTradeSize, storage_.recentSpikeCount);
    }
}

