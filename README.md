# EcoCredit 🌱

A decentralized carbon credit trading platform built on Stacks blockchain, enabling transparent and verifiable carbon offset transactions with automated oracle verification.

## Overview

EcoCredit provides a trustless marketplace for carbon credits, allowing environmental projects to tokenize their carbon reduction efforts and enabling individuals and organizations to purchase verified carbon offsets directly on the blockchain. The platform now features automated verification through IoT sensors and satellite data integration.

## Features

- **Project Registration**: Environmental projects can register and create verified carbon credit programs
- **Credit Issuance**: Issue tokenized carbon credits with verification standards and vintage years
- **Oracle Integration**: Automated verification using IoT sensors and satellite data
- **Real-time Monitoring**: Continuous environmental impact tracking and validation
- **Peer-to-Peer Trading**: Direct transfer of credits between users without intermediaries
- **Credit Retirement**: Permanently retire credits to prevent double-counting
- **Transparent Pricing**: Dynamic pricing controlled by project owners
- **Multi-Oracle Verification**: Requires multiple oracle confirmations for enhanced security
- **Reputation System**: Oracle providers are rated based on accuracy and reliability

## Smart Contract Functions

### Public Functions

- `register-project` - Register a new carbon credit project
- `issue-credits` - Issue carbon credits for verified environmental impact
- `transfer-credits` - Transfer credits between users
- `retire-credits` - Permanently retire credits for offset claims
- `update-project-price` - Update credit pricing (project owners only)
- `deactivate-project` - Deactivate a project (project owners only)

### Oracle Functions

- `register-oracle` - Register IoT sensors or satellite data providers
- `submit-oracle-data` - Submit environmental measurement data
- `verify-oracle-data` - Verify submitted oracle data (admin only)
- `issue-credits-with-oracle-verification` - Issue credits with oracle verification
- `deactivate-oracle` - Deactivate unreliable oracle providers

### Traditional Read-Only Functions

- `get-project` - Retrieve project details
- `get-credit` - Get carbon credit information
- `get-balance` - Check user's credit balance for a project
- `get-next-project-id` - Get current project counter
- `get-next-credit-id` - Get current credit counter
- `get-platform-fee` - Get platform fee percentage
- `check-project-owner` - Verify project ownership
- `check-project-active` - Check if project is active

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `clarinet check` to verify contract syntax

### Testing

Run the test suite:
```bash
clarinet test
```

## Usage Example

### Traditional Credit Issuance
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

### Oracle-Verified Credit Issuance
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
(contract-call? .ecocredit verify-oracle-data u1001)

;; Issue credits with oracle verification
(contract-call? .ecocredit issue-credits-with-oracle-verification
  u1 
  u500 
  u2024 
  "oracle-verified-hash123")
```

### Credit Trading
```clarity
;; Transfer 100 credits to another user
(contract-call? .ecocredit transfer-credits 
  u1 
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECQMD6K
  u100)
```

## Real-World Impact

EcoCredit with oracle integration addresses critical environmental challenges:

- **Climate Action**: Provides transparent mechanism for carbon offset transactions with real-time verification
- **Environmental Projects**: Enables direct funding for reforestation, renewable energy, and conservation with automated monitoring
- **Data Integrity**: IoT sensors and satellite data ensure accurate environmental impact measurement
- **Corporate Sustainability**: Facilitates corporate carbon neutrality goals with verifiable, real-time data
- **Individual Offsetting**: Allows individuals to offset their carbon footprint with confidence in verification
- **Scientific Accuracy**: Integrates with established carbon credit standards and modern measurement technologies
- **Fraud Prevention**: Multi-oracle verification prevents fraudulent carbon credit claims
- **Transparency**: All environmental data is recorded on-chain for complete transparency

## Security Features

- Input validation on all parameters including oracle data
- Proper error handling with descriptive error codes
- Owner-only functions for project and oracle management
- Balance verification before transfers
- Prevention of double-spending through retirement mechanism
- Multi-oracle verification threshold for enhanced security
- Reputation scoring for oracle providers
- Confidence score validation for environmental measurements
- Geolocation verification for data integrity

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add comprehensive tests
5. Submit a pull request

*Building a sustainable future through blockchain technology* 🌍