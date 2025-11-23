// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {Script, console2} from "forge-std/Script.sol";
import {BaseScript} from "../base/BaseScript.sol";

import {AntiSandwichHook} from "../../src/AntiSandwichHook.sol";

/// @notice Deployment script for AntiSandwichHook
/// @dev Mines the hook address with correct flags and deploys using CREATE2
/// @dev Configures initial parameters (baseFee, maxFee) after deployment
contract DeployAntiSandwichHookScript is BaseScript {
    // ============================================================
    // Configuration (can be overridden via environment variables)
    // ============================================================

    /// @notice Initial base fee in basis points (default: 5 bps = 0.05%)
    uint24 public constant DEFAULT_BASE_FEE = 5;

    /// @notice Initial max fee in basis points (default: 60 bps = 0.60%)
    uint24 public constant DEFAULT_MAX_FEE = 60;

    // ============================================================
    // Main Deployment Function
    // ============================================================

    function run() public {
        console2.log("==========================================");
        console2.log("Deploying AntiSandwichHook");
        console2.log("==========================================");
        console2.log("Chain ID:", block.chainid);
        console2.log("Deployer:", deployerAddress);
        console2.log("PoolManager:", address(poolManager));

        // Step 1: Determine hook flags
        // AntiSandwichHook uses BEFORE_SWAP_FLAG and AFTER_SWAP_FLAG
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        console2.log("Hook flags:", flags);
        console2.log("  - BEFORE_SWAP_FLAG: enabled");
        console2.log("  - AFTER_SWAP_FLAG: enabled");

        // Step 2: Prepare constructor arguments
        bytes memory constructorArgs = abi.encode(poolManager);

        // Step 3: Mine a salt that will produce a hook address with the correct flags
        console2.log("\nMining hook address with correct flags...");
        console2.log("This may take a few minutes...");
        
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            flags,
            type(AntiSandwichHook).creationCode,
            constructorArgs
        );

        console2.log("Hook address found:", hookAddress);
        console2.log("Salt:", vm.toString(salt));

        // Step 4: Deploy the hook using CREATE2
        console2.log("\nDeploying hook...");
        vm.startBroadcast();
        
        AntiSandwichHook hook = new AntiSandwichHook{salt: salt}(poolManager);
        
        vm.stopBroadcast();

        // Step 5: Verify deployment
        require(
            address(hook) == hookAddress,
            "DeployAntiSandwichHook: Hook Address Mismatch"
        );
        console2.log("Hook deployed successfully at:", address(hook));

        // Step 6: Configure initial parameters
        // Note: Configuration is done per-pool, so we'll log the default values
        // Actual configuration happens when creating a pool (see CreatePoolAndAddLiquidity.s.sol)
        console2.log("\nDefault configuration:");
        console2.log("  - Base Fee:", DEFAULT_BASE_FEE, "bps (0.05%)");
        console2.log("  - Max Fee:", DEFAULT_MAX_FEE, "bps (0.60%)");
        console2.log("  - Formula: fee = baseFee + k1*deltaTick + k2*deltaTick^2");
        console2.log("  - k1 = 5 (0.5 scaled x10)");
        console2.log("  - k2 = 2 (0.2 scaled x10)");

        // Step 7: Log deployment information
        console2.log("\n==========================================");
        console2.log("Deployment Summary");
        console2.log("==========================================");
        console2.log("Hook Address:", address(hook));
        console2.log("PoolManager:", address(poolManager));
        console2.log("Owner:", hook.owner());
        console2.log("Chain ID:", block.chainid);
        console2.log("==========================================");

        // Step 8: Save deployment info (for verification script)
        // This will be used by the verification script
        console2.log("\nNext steps:");
        console2.log("1. Save the hook address for pool creation");
        console2.log("2. Configure pool-specific parameters when creating pools");
        console2.log("3. Verify contract on Etherscan/BaseScan (optional)");
        console2.log("\nTo verify the contract, run:");
        console2.log("forge verify-contract \\");
        console2.log("  --rpc-url $RPC_URL \\");
        console2.log("  --chain <chain_name> \\");
        console2.log("  --verifier etherscan \\");
        console2.log("  --etherscan-api-key $ETHERSCAN_API_KEY \\");
        console2.log("  ", address(hook), " \\");
        console2.log("  src/AntiSandwichHook.sol:AntiSandwichHook");
    }

    // ============================================================
    // Helper Functions
    // ============================================================
    // Note: CREATE2_FACTORY is available from forge-std/Base.sol
    // No need to redeclare it here
}

