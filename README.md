# EcoCredit 🌱

A decentralized carbon credit trading platform built on Stacks blockchain with **Cross-Chain Bridge Implementation**, enabling transparent and verifiable carbon offset transactions across multiple blockchains (Ethereum, Polygon, BSC) for greater liquidity and accessibility.

## Overview

EcoCredit provides a trustless marketplace for carbon credits, allowing environmental projects to tokenize their carbon reduction efforts and enabling individuals and organizations to purchase verified carbon offsets directly on the blockchain. The platform features automated verification through IoT sensors and satellite data integration, plus seamless cross-chain bridging capabilities.

## 🚀 New Features: Cross-Chain Bridge

### Multi-Chain Support
- **Ethereum**: Access to the largest DeFi ecosystem
- **Polygon**: Fast, low-cost transactions for high-frequency trading
- **BSC (Binance Smart Chain)**: Integration with major CEX and growing DeFi protocols
- **Extensible Architecture**: Easy addition of new blockchain networks

### Bridge Capabilities
- **Seamless Transfers**: Move carbon credits between supported blockchains
- **Automated Validation**: Multi-validator consensus for secure cross-chain operations
- **Real-time Tracking**: Monitor bridge transactions and completion status
- **Fee Management**: Dynamic fee structure based on destination chain
- **Daily Limits**: Configurable volume limits for risk management
- **Emergency Controls**: Pause functionality for security incidents

## Features

- **Project Registration**: Environmental projects can register and create verified carbon credit programs
- **Credit Issuance**: Issue tokenized carbon credits with verification standards and vintage years
- **Oracle Integration**: Automated verification using IoT sensors and satellite data
- **Real-time Monitoring**: Continuous environmental impact tracking and validation
- **Cross-Chain Trading**: Transfer credits across Ethereum, Polygon, and BSC networks
- **Multi-Chain Liquidity**: Access broader market liquidity through cross-chain capabilities
- **Peer-to-Peer Trading**: Direct transfer of credits between users without intermediaries
- **Credit Retirement**: Permanently retire credits to prevent double-counting
- **Transparent Pricing**: Dynamic pricing controlled by project owners
- **Multi-Oracle Verification**: Requires multiple oracle confirmations for enhanced security
- **Reputation System**: Oracle providers are rated based on accuracy and reliability
- **Bridge Validation**: Multi-signature validation system for cross-chain transfers
- **Emergency Pause**: Platform-wide pause functionality for security

## Smart Contract Functions

### Public Functions

#### Core Platform
- `register-project` - Register a new carbon credit project
- `issue-credits` - Issue carbon credits for verified environmental impact
- `transfer-credits` - Transfer credits between users
- `retire-credits` - Permanently retire credits for offset claims
- `update-project-price` - Update credit pricing (project owners only)
- `deactivate-project` - Deactivate a project (project owners only)

#### Cross-Chain Bridge Functions
- `register-supported-chain` - Register a new blockchain for bridging (admin only)
- `initiate-bridge-transfer` - Start cross-chain credit transfer
- `complete-bridge-transfer` - Complete bridge transfer (validators only)
- `register-bridge-validator` - Register bridge validators (admin only)
- `set-bridge-pause` - Emergency pause bridge operations (admin only)
- `update-chain-status` - Enable/disable specific chains (admin only)

#### Oracle Functions
- `register-oracle` - Register IoT sensors or satellite data providers
- `submit-oracle-data` - Submit environmental measurement data
- `verify-oracle-data` - Verify submitted oracle data (admin only)
- `issue-credits-with-oracle-verification` - Issue credits with oracle verification
- `deactivate-oracle` - Deactivate unreliable oracle providers

### Read-Only Functions

#### Core Platform
- `get-project` - Retrieve project details
- `get-credit` - Get carbon credit information
- `get-balance` - Check user's credit balance for a project
- `get-next-project-id` - Get current project counter
- `get-next-credit-id` - Get current credit counter
- `get-platform-fee` - Get platform fee percentage
- `check-project-owner` - Verify project ownership
- `check-project-active` - Check if project is active

#### Cross-Chain Bridge
- `get-supported-chain` - Get blockchain configuration details
- `get-bridge-request` - Retrieve bridge transfer details
- `get-bridge-validator` - Get validator information
- `get-daily-bridge-volume-for-chain` - Check daily bridge volume
- `get-bridge-fee` - Get current bridge fee rate
- `get-bridge-daily-limit` - Get daily bridge limits
- `is-bridge-paused` - Check if bridge operations are paused
- `get-bridge-fee-for-amount` - Calculate bridge fee for specific amount
- `is-bridge-tx-processed` - Check if cross-chain transaction is processed

#### Oracle Functions
- `get-oracle-provider` - Get oracle provider details
- `get-oracle-data` - Get oracle measurement data
- `get-project-oracle-approvals` - Get oracle approval status
- `get-total-oracle-approvals` - Get total oracle approvals for project
- `get-oracle-threshold` - Get required oracle approval threshold

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Multi-chain wallet setup (MetaMask, etc.)

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `clarinet check` to verify contract syntax

### Testing

Run the test suite:
```bash
clarinet test
```

## Usage Examples

### Cross-Chain Bridge Operations

#### Register Supported Chains
```clarity
;; Register Ethereum mainnet for bridging
(contract-call? .ecocredit register-supported-chain 
  u1 ;; Ethereum chain ID
  "Ethereum"
  "0x742d35Cc6632C0532925a3b8D000d2EB658C0eb0" ;; Bridge contract address
  u100000 ;; Daily limit (100,000 credits)
  u10 ;; Minimum bridge amount
  u150) ;; 1.5% bridge fee

;; Register Polygon for bridging
(contract-call? .ecocredit register-supported-chain 
  u137 ;; Polygon chain ID
  "Polygon"
  "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"
  u500000 ;; Higher daily limit for Polygon
  u1 ;; Lower minimum for micro-transactions
  u50) ;; 0.5% bridge fee
```

#### Bridge Credits to Another Chain
```clarity
;; Check bridge fee first
(contract-call? .ecocredit get-bridge-fee-for-amount u1000 u1) ;; 1000 credits to Ethereum

;; Initiate bridge transfer to Ethereum
(contract-call? .ecocredit initiate-bridge-transfer
  u1 ;; project-id
  u1000 ;; credit amount
  u1 ;; target chain (Ethereum)
  "0x742d35Cc6632C0532925a3b8D000d2EB658C0eb0") ;; target address

;; Check bridge status
(contract-call? .ecocredit get-bridge-request u1)
```

### Traditional Credit Operations

#### Project Registration and Credit Issuance
```clarity
;; Register a new reforestation project
(contract-call? .ecocredit register-project 
  "Amazon Reforestation Initiative"
  "Large-scale reforestation project in the Amazon rainforest"
  "Brazil, Amazon Basin"
  "VCS"
  u1000000) ;; 1 STX per credit

;; Issue 1000 carbon credits (traditional method)
(contract-call? .ecocredit issue-credits 
  u1 
  u1000 
  u2024 
  "hash123abc456def789")
```

#### Oracle-Verified Credit Issuance
```clarity
;; Register an IoT sensor oracle
(contract-call? .ecocredit register-oracle 
  "IoT"
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Submit sensor data for carbon sequestration
(contract-call? .ecocredit submit-oracle-data
  u1 ;; project-id
  u1 ;; oracle-id
  "carbon-sequestration"
  u500 ;; 500 tons CO2
  "tons-co2"
  u95 ;; 95% confidence
  "lat:40.7128,lng:-74.0060")

;; Admin verifies the oracle data
(contract-call? .ecocredit verify-oracle-data u1)

;; Issue credits with oracle verification
(contract-call? .ecocredit issue-credits-with-oracle-verification
  u1 
  u500 
  u2024 
  "oracle-verified-hash123")
```

#### Credit Trading
```clarity
;; Transfer 100 credits to another user
(contract-call? .ecocredit transfer-credits 
  u1 
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECQMD6K
  u100)
```

## Cross-Chain Architecture

### Supported Blockchains
1. **Ethereum**: Primary DeFi integration, high value transactions
2. **Polygon**: High-frequency, low-cost trading, micro-transactions
3. **BSC**: Integration with Binance ecosystem, competitive fees

### Bridge Security
- **Multi-Validator Consensus**: Requires multiple validator signatures
- **Daily Volume Limits**: Configurable limits per blockchain
- **Emergency Pause**: Immediate halt capability for security incidents
- **Transaction Tracking**: Complete audit trail of all cross-chain movements
- **Fee Management**: Dynamic fee structure based on network congestion

### Bridge Process Flow
1. **Initiate Transfer**: User initiates bridge request on source chain
2. **Lock Credits**: Credits are locked in bridge contract
3. **Validator Confirmation**: Multiple validators confirm transaction
4. **Mint on Target**: Credits are minted on destination blockchain
5. **Complete Transfer**: Bridge request marked as completed

## Real-World Impact

EcoCredit with cross-chain capabilities addresses critical environmental challenges:

- **Climate Action**: Transparent mechanism for carbon offset transactions across multiple blockchains
- **Global Accessibility**: Multi-chain support increases market participation
- **Enhanced Liquidity**: Cross-chain capabilities provide access to broader DeFi ecosystems
- **Environmental Projects**: Direct funding for reforestation, renewable energy, and conservation with automated monitoring
- **Data Integrity**: IoT sensors and satellite data ensure accurate environmental impact measurement
- **Corporate Sustainability**: Facilitates corporate carbon neutrality goals across different blockchain preferences
- **Individual Offsetting**: Allows individuals to offset their carbon footprint on their preferred network
- **Scientific Accuracy**: Integrates with established carbon credit standards and modern measurement technologies
- **Fraud Prevention**: Multi-oracle verification and cross-chain validation prevents fraudulent carbon credit claims
- **Market Efficiency**: Cross-chain arbitrage opportunities improve price discovery
- **Transparency**: All environmental and bridge data recorded on-chain for complete transparency

## Security Features

### Core Platform Security
- Input validation on all parameters including oracle data
- Proper error handling with descriptive error codes
- Owner-only functions for project and oracle management
- Balance verification before transfers
- Prevention of double-spending through retirement mechanism
- Multi-oracle verification threshold for enhanced security
- Reputation scoring for oracle providers
- Confidence score validation for environmental measurements
- Geolocation verification for data integrity

### Cross-Chain Security
- **Multi-Validator Consensus**: Prevents single points of failure
- **Daily Volume Limits**: Risk management through configurable limits
- **Transaction Replay Protection**: Prevents double-spending across chains
- **Emergency Pause Mechanism**: Immediate response to security threats
- **Validator Staking**: Economic incentives for honest behavior
- **Bridge Fee Management**: Dynamic fees prevent spam attacks
- **Chain Status Controls**: Enable/disable specific chains as needed

## Gas Optimization

### Cross-Chain Efficiency
- **Batch Processing**: Group multiple small transfers
- **Optimized Data Structures**: Minimal storage for bridge operations
- **Event-Driven Architecture**: Efficient cross-chain communication
- **Configurable Parameters**: Adjust based on network conditions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add comprehensive tests for both core and bridge functionality
5. Test cross-chain scenarios
6. Submit a pull request

## Roadmap

### Phase 1: Core Bridge (Current)
- ✅ Ethereum, Polygon, BSC support
- ✅ Multi-validator consensus
- ✅ Emergency controls

### Phase 2: Advanced Features
- 🔄 Automated market makers (AMM) integration
- 🔄 Cross-chain yield farming
- 🔄 Layer 2 solutions (Arbitrum, Optimism)

### Phase 3: Enterprise Integration
- 🔄 Corporate dashboard
- 🔄 API for enterprise systems
- 🔄 Compliance reporting tools

*Building a sustainable future through blockchain technology across all major networks* 🌍🔗