# 🪝 Anti-Sandwich Hook for Uniswap v4 (Stable Assets)

> **A Uniswap v4 Hook that detects sandwich attack patterns in stable asset markets and dynamically adjusts fees based on risk score, protecting LPs and users without blocking swaps.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Stable-green.svg)](https://getfoundry.sh/)

---

## 🎯 Problem Statement

Users and Liquidity Providers (LPs) in stable asset markets suffer from **Sandwich Attacks** (MEV) when:
- Bots detect pending large swaps
- Execute swaps before (front-run) and after (back-run) the victim's swap
- Users pay more and LPs lose due to exploited arbitrage
- This is especially problematic in stable pairs (USDC/USDT, DAI/USDC, etc.)

## 💡 Solution

This Uniswap v4 Hook:
1. **Detects risk patterns** typical of sandwich attacks
2. **Calculates a riskScore** based on trade size, price volatility, and consecutive patterns
3. **Dynamically adjusts fees** according to detected risk
4. **Never blocks swaps** - maintains UX and composability
5. **Protects LPs and users** without external oracles

---

## 🏗️ How It Works

### Risk Score Calculation

The hook tracks multiple metrics and calculates a risk score:

```solidity
riskScore = 
    50 * relativeSize +           // Trade size vs average
    30 * deltaPrice +             // Price movement
    20 * recentSpikeCount;        // Consecutive large trades
```

Where:
- `relativeSize = tradeSize / avgTradeSize` (if > 5x → high risk)
- `deltaPrice = abs(P_current - lastPrice)`
- `recentSpikeCount` tracks consecutive large trades

### Dynamic Fee Adjustment

Fees increase with detected risk to discourage sandwich attacks:

```solidity
if (riskScore < 50) {
    fee = 5;    // 0.05% - Low risk
} else if (riskScore < 150) {
    fee = 20;   // 0.20% - Medium risk
} else {
    fee = 60;   // 0.60% - High risk (anti-sandwich mode)
}
```

### Implementation

- **`beforeSwap()`** - Calculates riskScore and applies dynamic fee
- **`afterSwap()`** - Updates historical metrics (lastPrice, avgTradeSize, recentSpikeCount)

---

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) (stable version)
- Git

### Installation

```bash
# Clone the repository
git clone <YOUR_REPO_URL>
cd ethglobal-uniswap-template-nov-2025

# Install dependencies
forge install

# Run tests
forge test
```

### Local Development

1. **Start Anvil** (local blockchain):

```bash
anvil
```

Or fork a testnet:

```bash
anvil --fork-url <YOUR_RPC_URL>
```

2. **Deploy the hook**:

```bash
forge script script/deploy/DeployAntiSandwichHook.s.sol \
  --rpc-url http://localhost:8545 \
  --private-key <PRIVATE_KEY> \
  --broadcast
```

### Testing

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run fork tests (requires RPC_URL)
forge test --fork-url $RPC_URL

# Test sandwich detection
forge test --match-test test_SandwichPatternDetection
```

---

## 📋 Configuration

The hook can be configured with the following parameters:

- **`lowRiskFee`**: Fee for low risk (default: 5 bps = 0.05%)
- **`mediumRiskFee`**: Fee for medium risk (default: 20 bps = 0.20%)
- **`highRiskFee`**: Fee for high risk (default: 60 bps = 0.60%)
- **`riskThresholdLow`**: Low risk threshold (default: 50)
- **`riskThresholdHigh`**: High risk threshold (default: 150)
- **Risk score weights**: `w1 = 50`, `w2 = 30`, `w3 = 20` (adjustable constants)

### Setting Parameters

```solidity
// Only owner can update
hook.setPoolConfig(
    poolKey,
    5,    // lowRiskFee: 5 bps
    20,   // mediumRiskFee: 20 bps
    60,   // highRiskFee: 60 bps
    50,   // riskThresholdLow
    150   // riskThresholdHigh
);
```

---

## 🧪 Testing

The project includes comprehensive tests:

- **Unit tests**: Core logic (riskScore calculation, fee adjustment)
- **Integration tests**: Full swap flow with Uniswap v4
- **Sandwich detection tests**: Pattern detection and fee adjustment
- **Edge cases**: Zero price, extreme volatility, reentrancy
- **Security tests**: Access control, parameter validation

### Running Tests

```bash
# All tests
forge test

# Specific test
forge test --match-test test_CalculateRiskScore
forge test --match-test test_SandwichPatternDetection

# Fork tests
forge test --fork-url $RPC_URL
```

---

## 📊 Expected Results

### Metrics

- **MEV Reduction**: 30-50% in stable pairs (estimated)
- **Dynamic Fee**: 5 bps (normal) → 60 bps (high risk)
- **Gas Cost**: <100k gas per swap (target)
- **Pattern Detection**: >80% accuracy in sandwich detection

### Use Cases

1. **Normal Swap (USDC/USDT)**
   - Normal trade size, stable price
   - riskScore < 50 → fee = 5 bps
   - Normal behavior, no penalty

2. **Suspicious Large Swap (Possible Sandwich)**
   - Trade size 10× larger than average
   - Price jumps suddenly
   - riskScore > 150 → fee = 60 bps
   - Discourages sandwich, protects LPs

3. **Sandwich Pattern Detected**
   - Multiple consecutive large swaps
   - recentSpikeCount increases
   - Fee increases progressively
   - Protects users and LPs

---

## 🔒 Security

- ✅ Input validation on all configuration functions
- ✅ Access control (onlyOwner) for parameter updates
- ✅ Reentrancy protection
- ✅ Edge case handling
- ✅ Overflow/underflow protection
- ✅ Comprehensive test coverage

---

## 📚 Documentation

- **Internal Docs**: See `docs-internos/` for detailed architecture and roadmap
- **Project Context**: See `.cursor/project-context.md` for technical details
- **Uniswap v4 Docs**: [docs.uniswap.org](https://docs.uniswap.org/contracts/v4/overview)

---

## 🛠️ Tech Stack

- **Solidity**: ^0.8.0
- **Foundry**: Testing and deployment
- **Uniswap v4**: Official hook template
- **Testnet**: Sepolia or Base Sepolia

---

## 📝 Project Structure

```
.
├── src/
│   └── AntiSandwichHook.sol      # Main hook contract
├── test/
│   ├── AntiSandwichHook.t.sol   # Unit tests
│   └── integration/             # Integration tests
├── script/
│   └── deploy/
│       └── DeployAntiSandwichHook.s.sol
├── docs-internos/               # Internal documentation
└── README.md                    # This file
```

---

## 🎯 Hackathon Submission

**Event**: ETHGlobal Buenos Aires (Nov 2025)  
**Track**: Track 1 - Stable-Asset Hooks ($10,000 prize pool)  
**Organizer**: Uniswap Foundation

### Deliverables

- ✅ TxIDs of transactions (testnet/mainnet)
- ✅ Public GitHub repository
- ✅ Complete README.md
- ✅ Functional demo or installation instructions
- ✅ Demo video (max 3 minutes, English with subtitles)

### Track Alignment

This hook aligns with Track 1 requirements:
- **Optimized stable AMM logic** ✅ (dynamic fee anti-sandwich)
- **Credit-backed trading** (indirect - protects traders)
- **Synthetic lending** (future - can be extended)

---

## 🤝 Contributing

This is a hackathon project. Contributions and feedback are welcome!

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Uniswap Foundation](https://www.uniswapfoundation.org/) for the v4 template and hackathon
- [ETHGlobal](https://ethglobal.com/) for organizing the event
- Uniswap v4 community for documentation and resources

---

## 📞 Contact

For questions or feedback, please open an issue in the repository.

---

**Built with ❤️ for ETHGlobal Buenos Aires 2025**
