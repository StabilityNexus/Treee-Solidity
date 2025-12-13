<!-- Don't delete it -->
<div name="readme-top"></div>


<!-- Organization Logo -->
<div align="center" style="display: flex; align-items: center; justify-content: center; gap: 16px;">
  <img width="175" height="175" alt="image" src="https://github.com/user-attachments/assets/1f77b71c-f96a-4f2b-bed2-7a7170f839f0" />
  <img width="175" height="175" alt="image" src="https://github.com/user-attachments/assets/8c5008a3-6c2e-4050-9206-031bbd44cf06" />

</div>

&nbsp;

<!-- Organization Name -->
<div align="center">

[![Static Badge](https://img.shields.io/badge/Stability_Nexus-/Treee-228B22?style=for-the-badge&labelColor=FFC517)](https://treee.stability.nexus/)

</div>

<!-- Organization/Project Social Handles -->
<p align="center">
<a href="https://t.me/StabilityNexus">
<img src="https://img.shields.io/badge/Telegram-black?style=flat&logo=telegram&logoColor=white&color=24A1DE" alt="Telegram Badge"/></a>
&nbsp;&nbsp;
<a href="https://x.com/StabilityNexus">
<img src="https://img.shields.io/twitter/follow/StabilityNexus" alt="X (formerly Twitter) Badge"/></a>
&nbsp;&nbsp;
<a href="https://discord.gg/YzDKeEfWtS">
<img src="https://img.shields.io/discord/995968619034984528?style=flat&logo=discord&logoColor=white&label=Discord&labelColor=5865F2&color=57F287" alt="Discord Badge"/></a>
&nbsp;&nbsp;
<a href="https://news.stability.nexus/">
  <img src="https://img.shields.io/badge/Medium-black?style=flat&logo=medium&logoColor=black&color=white" alt="Medium Badge"></a>
&nbsp;&nbsp;
<a href="https://linkedin.com/company/stability-nexus">
  <img src="https://img.shields.io/badge/LinkedIn-black?style=flat&logo=LinkedIn&logoColor=white&color=0A66C2" alt="LinkedIn Badge"></a>
&nbsp;&nbsp;
<a href="https://www.youtube.com/@StabilityNexus">
  <img src="https://img.shields.io/youtube/channel/subscribers/UCZOG4YhFQdlGaLugr_e5BKw?style=flat&logo=youtube&logoColor=white&labelColor=FF0000&color=FF0000" alt="Youtube Badge"></a>
</p>

---

<div align="center">
<h1>Treee — Solidity Contracts (Foundry)</h1>
</div>

**Treee** is the smart contract layer of the *Treee tree-planting protocol*, enabling on-chain verification, organization management, and NFT issuance for planted trees.  
It powers transparent and auditable sustainability tracking within the **Stability Nexus** ecosystem.

## 📋 Table of Contents

- [Tech Stack](#tech-stack)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
- [Developer Workflow](#developer-workflow)
- [Testing](#testing)
- [Deployment](#deployment)
- [Common Commands](#common-commands)
- [Project Structure](#project-structure)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

---

## Tech Stack

### Core

- **Solidity (v0.8.28)** — Smart contract development  
- **Foundry (forge, anvil, cast)** — Testing, simulation & deployment  
- **OpenZeppelin Contracts** — Token standards and access control  

### Libraries & Dependencies

- **foundry-devops** — Deployment utilities  
- **forge-std** — Foundry standard library for testing  

---

## Architecture Overview

### Core Contracts

#### 🌳 TreeNft.sol
The main NFT contract representing planted trees. Each NFT contains:
- **Metadata** — Tree species, location, planting date
- **Verification status** — On-chain proof of planting
- **Organization tracking** — Links to the planting organization

#### 🏢 Organisation.sol
Manages individual organizations that plant trees:
- **Role management** — Admin, verifier, and planter roles
- **Tree tracking** — Records trees planted by the organization
- **Token distribution** — Manages incentive token allocation

#### 🏭 OrganisationFactory.sol
Factory contract for deploying and managing organizations:
- **Organization deployment** — Creates new organization contracts
- **Registry** — Maintains a list of all active organizations
- **Access control** — Manages who can create organizations

### Token Contracts

#### 💚 CareToken.sol
ERC-20 token rewarding tree care and maintenance activities.

#### 🌱 PlanterToken.sol
ERC-20 token incentivizing tree planting activities.

#### 🏆 LegacyToken.sol
ERC-20 token for long-term sustainability contributions.

### Utilities

- **errors.sol** — Custom error definitions for gas-efficient reverts
- **structs.sol** — Shared data structures across contracts

---

## Getting Started

### Prerequisites

Ensure you have the following installed:

- **[Foundry](https://book.getfoundry.sh/getting-started/installation)** — Ethereum development toolkit
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- **Git** — Version control
- **Rust toolchain** — Required by Foundry (`rustup`)
- **Node.js** (optional) — For additional tooling

### Environment Setup

Create a `.env` file in the root directory:
Install dependencies

```bash
forge install
```

#### 3. Build contracts

```bash
forge build
```

#### 4. Run tests

```bash
forge test
```

#### 5. Start a local node

```bash
anvil
```

#### 6. Deploy locally

```bash
# In a new terminal, deploy to local Anvil node
forge script script/DeployAllContracts.s.sol:DeployAllContractsAtOnce \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
### Local Development

#### Start local blockchain:

```bash
anvil
```

#### Test in watch mode:

```bash
forge test --watch
```

#### Run specific tests:

```bash
# Test a specific contract
forge test --match-contract TreeNftTest

# Test a specific function
forge test --match-test testMintTree

# Verbose output
forge test -vvv
```

#### Gas reporting:

```bash
forge test --gas-report
```

#### Check test coverage:

```bash
forge coverage
```

### Interacting with Contracts

#### Using Cast (Command Line):

```bash
# Call a view function
cast call <CONTRACT_ADDRESS> "getOrganisationCount()(uint256)" --rpc-url http://127.0.0.1:8545

# Send a transaction
cast send <CONTRACT_ADDRESS> "mintTree(address,string)" <RECIPIENT> "ipfs://metadata" \
  --private-key <YOUR_KEY> \
  --rpc-url http://127.0.0.1:8545
          | Description                              |
| -------------------------- | ---------------------------------------- |
| `forge build`              | Compile contracts                        |
| `forge test`               | Run all tests                            |
| `forge test -vvvv`         | Run tests with detailed traces           |
| `forge fmt`                | Format Solidity code                     |
| `forge clean`              | Remove build artifacts                   |
| `forge snapshot`           | Create gas usage snapshot                |
| `forge coverage`           | Generate test coverage report            |
| `anvil`                    | Start local blockchain node              |
| `cast call`                | Call a contract function (read-only)     |
| `cast send`                | Send a transaction to a contract         |
| `forge script <script>`    | Execute Whether it's bug fixes, new features, documentation improvements, or feedback.

### How to Contribute

1. **Fork the repository** and create a feature branch:

   ```bash
   git checkout -b feature/AmazingFeature
   ```

2. **Make your changes** following our coding standards:
   - Write clear, documented code
   - Follow Solidity style guide
   - Add tests for new functionality
   - Update documentation as needed

3. **Run all checks** before committing:

   ```bash
   forge build && forge test && forge fmt
   ```

4. **Commit your changes** with descriptive messages:

   ```bash
   git commit -m "feat: Add tree verification mechanism"
   ```

5. **Push to your fork** and open a Pull Request:

   ```bash
   git push origin feature/AmazingFeature
   ```

### Development Guidelines

- ✅ Write tests for all new features
- ✅ Maintain or improve test coverage
- ✅ Follow existing code style and patterns
- ✅ Add NatSpec comments to public functions
- ✅ Update README if adding new features
- ✅ Keep commits atomic and well-described

### Getting Help

- 💬 [Discord](https://discord.gg/YzDKeEfWtS) — Ask questions and get help
- 🐛 [GitHub Issues](https://github.com/StabilityNexus/Treee-Solidity/issues) — Report bugs
- 💡 [GitHub Discussions](https://github.com/StabilityNexus/Treee-Solidity/discussions) — Feature requests and ideas

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Resources

### Documentation

- [Foundry Book](https://book.getfoundry.sh/) — Official Foundry documentation
- [Solidity Docs](https://docs.soliditylang.org/) — Solidity language reference
- [OpenZeppelin Docs](https://docs.openzeppelin.com/) — Smart contract libraries

### Community

- 🌐 [Website](https://treee.stability.nexus/)
- 📰 [Blog](https://news.stability.nexus/)
- 🐦 [Twitter/X](https://x.com/StabilityNexus)
- 💼 [LinkedIn](https://linkedin.com/company/stability-nexus)
- 📺 [YouTube](https://www.youtube.com/@StabilityNexus)

---

<div align="center">

**Built with 💚 by the Treee Team**

© 2025 **Treee Project** · Part of the [Stability Nexus](https://stability.nexus/) ecosystem

</div>
│   ├── DeployAllContracts.s.sol
│   ├── DeployOrganisationFactory.s.sol
│   └── DeployTreeNftContract.s.sol
├── test/                         # Test files
│   ├── Organisation.t.sol
│   ├── OrganisationFactory.t.sol
│   └── TreeNft.t.sol
├── lib/                          # External dependencies
│   ├── forge-std/                # Foundry standard library
│   ├── foundry-devops/           # Deployment tools
│   └── openzeppelin-contracts/   # OpenZeppelin libraries
├── foundry.toml                  # Foundry configuration
├── remappings.txt                # Import remappings
└── README.md                     # This file
```

---

## Security

### Best Practices

- 🔒 All contracts use **OpenZeppelin** audited libraries
- ✅ Access control via **role-based permissions**
- 🛡️ **Custom errors** for gas-efficient reverts
- 🔍 **Comprehensive test coverage** required
- 📝 **NatSpec documentation** for all public functions

### Security Considerations

1. **Private Keys**: Never commit private keys or `.env` files
2. **Audits**: Production contracts should be professionally audited
3. **Testing**: Achieve high test coverage before deployment
4. **Upgradability**: Consider using proxy patterns for critical contracts
5. **Rate Limiting**: Implement appropriate safeguards against spam

### Reporting Vulnerabilities

If you discover a security vulnerability, please email:  
**security@stability.nexus**

Do not open public issues for security concerns.
```bash
# Deploy Organisation Factory
forge script script/DeployOrganisationFactory.s.sol:DeployOrganisationFactory \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast

# Deploy TreeNft Contract
forge script script/DeployTreeNftContract.s.sol:DeployTreeNft \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

---

## Testing

### Test Structure

```
test/
├── Organisation.t.sol       # Organisation contract tests
├── OrganisationFactory.t.sol # Factory contract tests
└── TreeNft.t.sol            # TreeNft contract tests
```

### Running Tests

```bash
# Run all tests
forge test

# Run with different verbosity levels
forge test -v     # Show stack traces for failing tests
forge test -vv    # Show stack traces for all tests
forge test -vvv   # Show execution traces for failing tests
forge test -vvvv  # Show execution traces for all tests
forge test -vvvvv # Show execution and setup traces for all tests

# Filter tests by name pattern
forge test --match-test testMint

# Filter tests by contract
forge test --match-contract TreeNft

# Run tests on specific file
forge test --match-path test/TreeNft.t.sol

# Generate gas snapshot
forge snapshot

# Compare gas usage
forge snapshot --diff
```

---

## Deployment

### Testnet Deployment (Sepolia)

#### 1. Configure environment variables in `.env`:

```env
SEPOLIA_RPC_URL=<your_rpc_url>
PRIVATE_KEY=<your_private_key>
ETHERSCAN_API_KEY=<your_api_key>
```

#### 2. Deploy all contracts:

```bash
forge script script/DeployAllContracts.s.sol:DeployAllContractsAtOnce \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

#### 3. Deploy individual contracts:

```bash
# Deploy Organisation Factory
forge script script/DeployOrganisationFactory.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# Deploy TreeNft
forge script script/DeployTreeNftContract.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Mainnet Deployment

⚠️ **Critical**: Before mainnet deployment:

1. ✅ Complete security audit
2. ✅ Test extensively on testnet
3. ✅ Verify all contract addresses
4. ✅ Use hardware wallet or secure key management
5. ✅ Double-check constructor parameters

```bash
forge script script/DeployAllContracts.s.sol:DeployAllContractsAtOnce \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Verify Contracts Manually

If automatic verification fails:

```bash
forge verify-contract <CONTRACT_ADDRESS> \
  src/TreeNft.sol:TreeNft \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string)" "TreeNFT" "TREE")

#### 4. Start a local node

```bash
anvil
```

#### 5. Deploy (example)

```bash
forge script script/Deploy.s.sol:DeployAllContractsAtOnce \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

---

## Developer Workflow

Run a local node:

```bash
anvil
```

Test in watch mode:

```bash
forge test --watch
```

Interact manually:

```bash
cast call <contract-address> "getOrganisationCount()()" --rpc-url http://127.0.0.1:8545
```

---

## Common Commands

| Command          | Description                 |
| ---------------- | --------------------------- |
| `forge build`    | Compile contracts           |
| `forge test`     | Run tests                   |
| `forge fmt`      | Format Solidity code        |
| `forge snapshot` | Create gas usage reports    |
| `anvil`          | Start local blockchain node |

---

## Contributing

We welcome contributions of all kinds!

1. Fork the repo & create a feature branch:

   ```bash
   git checkout -b feature/AmazingFeature
   ```
2. Commit your changes:

   ```bash
   git commit -m "Add some AmazingFeature"
   ```
3. Run checks:

   ```bash
   forge build && forge test && forge fmt
   ```
4. Push & open a PR 

For bugs, suggestions, or questions — open an issue or reach us on [Discord](https://discord.gg/YzDKeEfWtS).

---

© 2025 **Treee Project** · [Stability Nexus](https://stability.nexus/) ecosystem.

