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

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Contracts](#contracts)
- [Tokenomics](#tokenomics)
- [Getting Started](#getting-started)
- [Usage Flow](#usage-flow)
- [Developer Workflow](#developer-workflow)
- [Contributing](#contributing)

---

## Overview

Treee is a decentralized protocol for tree planting and verification. Organizations can register, propose tree-planting initiatives, and mint NFTs representing planted trees. Community members verify these trees through on-chain proofs, earning rewards while ensuring transparency.

Key features:
- **Organization Management**: Create and manage tree-planting organizations with member voting
- **Tree NFTs**: ERC721 tokens representing individual planted trees with metadata
- **Verification System**: Community-driven verification with proof submission
- **Incentive Tokens**: Multiple ERC20 tokens rewarding different ecosystem activities
- **User Profiles**: On-chain user registration and reputation tracking

---

## Architecture

### Core Components

```text
├── OrganisationFactory.sol     # Factory for creating organizations
├── Organisation.sol           # Organization logic and governance
├── TreeNft.sol               # ERC721 NFT contract for trees
└── token-contracts/          # Incentive ERC20 tokens
    ├── CareToken.sol
    ├── LegacyToken.sol
    └── PlanterToken.sol
```

### Deployment Flow

1. **Token Deployment**: Deploy CareToken and LegacyToken
2. **TreeNft Deployment**: Deploy TreeNft with token addresses, transfer token ownership
3. **Factory Deployment**: Deploy OrganisationFactory with TreeNft address

---

## Contracts

### OrganisationFactory
- **Purpose**: Central registry for all organizations
- **Features**:
  - Create new organizations
  - Track organization memberships and ownerships
  - Paginated queries for organizations
  - Role-based access (owner/member)

### Organisation
- **Purpose**: Individual organization logic
- **Features**:
  - Member management (add/remove/promote)
  - Tree planting proposals with voting
  - Verification requests for planted trees
  - Governance via majority owner voting

### TreeNft
- **Purpose**: NFT representation of planted trees
- **Features**:
  - Mint NFTs for approved tree planting proposals
  - Verification system with proof submission
  - User profile management
  - Tree lifecycle tracking (planting/death)
  - Metadata storage (coordinates, species, photos)

### Token Contracts
- **CareToken (CRT)**: Token for tree care activities
- **LegacyToken (LT)**: Earned when marking trees as deceased
- **PlanterToken (PRT)**: Earned by verifiers for each verified tree

---

## Tokenomics

### Reward Mechanisms

| Action | Token | Amount | Conditions |
|--------|-------|--------|------------|
| Verify Tree | PlanterToken | 1 PRT per tree | Must not be tree owner |
| Mark Tree Dead | LegacyToken | 1 LT | Owner only, after 365 days |
| Tree Care | CareToken | TBD | Future implementation |

### PlanterToken Specifics
- Unique token per verifier
- Minted to tree owner upon verification
- Can be burned if verification is revoked
- Tracks verification history

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Rust toolchain (`rustup`)
- Node.js (optional, for deployment scripting)

---

### Quickstart

#### 1. Clone the repository
```bash
git clone https://github.com/StabilityNexus/Treee-Solidity.git
cd Treee-Solidity
```

#### 2. Install dependencies
```bash
make install
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

#### 6. Deploy (example)
```bash
forge script script/DeployAllContracts.s.sol:DeployAllContractsAtOnce \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

---

## Usage Flow

### 1. Organization Creation
```solidity
// Deployer creates OrganisationFactory with TreeNft address
OrganisationFactory factory = new OrganisationFactory(treeNftAddress);

// User creates organization
(uint256 orgId, address orgAddress) = factory.createOrganisation(
    "Green Earth Org", 
    "Tree planting initiative", 
    "ipfs://photo-hash"
);
```

### 2. Tree Planting Proposal
```solidity
// Organization member proposes tree planting
Organisation org = Organisation(orgAddress);
uint256 proposalId = org.plantTreeProposal(
    40723456,  // latitude * 1e6
    -74012345, // longitude * 1e6
    "Oak",
    "ipfs://image",
    "ipfs://qr",
    "Tree metadata",
    photos,
    geoHash,
    5  // number of trees
);
```

### 3. Voting and Minting
```solidity
// Owners vote on proposal
org.voteOnTreePlantingProposal(proposalId, 1); // 1 = yes

// Upon majority approval, NFT is minted automatically
// TreeNft.mintNft() called with proposal data
```

### 4. Verification
```solidity
// Community member verifies planted tree
TreeNft treeNft = TreeNft(treeNftAddress);
uint256 verificationId = treeNft.verify(
    tokenId,
    proofHashes,
    "Verification description"
);

// Verifier earns PlanterTokens
```

### 5. User Registration
```solidity
// Users register profiles
treeNft.registerUserProfile("John Doe", "ipfs://profile-photo");
```

---

## Developer Workflow

### Local Development
```bash
# Start local blockchain
make anvil

# Run tests in watch mode
forge test --watch

# Format code
forge fmt

# Generate gas snapshots
forge snapshot
```

### Testing
```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Organisation.t.sol

# Run with gas reporting
forge test --gas-report
```

### Deployment
```bash
# Deploy to local anvil
make deploy

# Deploy to Sepolia (requires env vars)
forge script script/DeployAllContracts.s.sol:DeployAllContractsAtOnce \
  --network sepolia
```

### Interaction Examples
```bash
# Get organization count
cast call $ORG_FACTORY "getOrganisationCount()()" --rpc-url http://127.0.0.1:8545

# Get user's organizations
cast call $ORG_FACTORY "getMyOrganisations(uint256,uint256)" 0 10 --rpc-url http://127.0.0.1:8545
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
| `make install`   | Install dependencies        |
| `make clean`     | Clean build artifacts       |

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

