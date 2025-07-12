# EcoCredit 🌱

A decentralized carbon credit trading platform built on Stacks blockchain, enabling transparent and verifiable carbon offset transactions.

## Overview

EcoCredit provides a trustless marketplace for carbon credits, allowing environmental projects to tokenize their carbon reduction efforts and enabling individuals and organizations to purchase verified carbon offsets directly on the blockchain.

## Features

- **Project Registration**: Environmental projects can register and create verified carbon credit programs
- **Credit Issuance**: Issue tokenized carbon credits with verification standards and vintage years
- **Peer-to-Peer Trading**: Direct transfer of credits between users without intermediaries
- **Credit Retirement**: Permanently retire credits to prevent double-counting
- **Transparent Pricing**: Dynamic pricing controlled by project owners
- **Verification Integration**: Support for multiple verification standards (VCS, Gold Standard, etc.)

## Smart Contract Functions

### Public Functions

- `register-project` - Register a new carbon credit project
- `issue-credits` - Issue carbon credits for verified environmental impact
- `transfer-credits` - Transfer credits between users
- `retire-credits` - Permanently retire credits for offset claims
- `update-project-price` - Update credit pricing (project owners only)
- `deactivate-project` - Deactivate a project (project owners only)

### Read-Only Functions

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

```clarity
;; Register a new reforestation project
(contract-call? .ecocredit register-project 
  "Amazon Reforestation Initiative"
  "Large-scale reforestation project in the Amazon rainforest"
  "Brazil, Amazon Basin"
  "VCS"
  u1000000) ;; 1 STX per credit

;; Issue 1000 carbon credits
(contract-call? .ecocredit issue-credits 
  u1 
  u1000 
  u2024 
  "hash123abc456def789")

;; Transfer 100 credits to another user
(contract-call? .ecocredit transfer-credits 
  u1 
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECQMD6K
  u100)
```

## Real-World Impact

EcoCredit addresses critical environmental challenges:

- **Climate Action**: Provides transparent mechanism for carbon offset transactions
- **Environmental Projects**: Enables direct funding for reforestation, renewable energy, and conservation
- **Corporate Sustainability**: Facilitates corporate carbon neutrality goals
- **Individual Offsetting**: Allows individuals to offset their carbon footprint
- **Verification**: Integrates with established carbon credit standards

## Security Features

- Input validation on all parameters
- Proper error handling with descriptive error codes
- Owner-only functions for project management
- Balance verification before transfers
- Prevention of double-spending through retirement mechanism

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add comprehensive tests
5. Submit a pull request


*Building a sustainable future through blockchain technology* 🌍