# BitServe: Decentralized Marketplace on Stacks

**BitServe** is a feature-rich, decentralized marketplace built on the **Stacks blockchain**, leveraging **Bitcoin** for settlement and trustless commerce. This Clarity smart contract enables direct product sales, auctions, and verified brand listings in a secure and transparent environment.

## Features

### Brand Verification

- Users can register brands on-chain.
- Marketplace owner can verify brands to establish trust and credibility.

### Direct Product Sales

- Sellers can list fixed-price items.
- Payments are made in STX with automatic fee deduction.
- Transactions are atomic and trustless.

### Auction System

- Time-bound auctions with customizable duration and minimum bid.
- Outbidding system with refund mechanism for previous highest bidders.
- Automatic transfer of funds post-auction and product delisting.

### Review & Reputation

- Buyers can leave ratings (0–5) and textual feedback on products.
- Reviews are publicly queryable to support informed decisions.

### Platform Fees

- A configurable platform fee (default: 2.5%) supports sustainability.
- Fees are collected by the contract owner upon each sale or auction conclusion.

## Smart Contract Security Considerations

- **Ownership enforcement**: Only the contract owner can verify brands.
- **Validation checks**: Ensures minimum input lengths and value sanity (e.g., non-zero prices, minimum bid rules).
- **Secure fund transfers**: Uses Clarity's `stx-transfer?` with robust error handling.
- **Auction safeguards**: Handles timeouts, duplicate bids, and refund logic securely.

## Built On

- **Stacks Blockchain** – Brings smart contracts to Bitcoin.
- **Clarity Language** – Secure, decidable language for predictable smart contracts.
- **Bitcoin Settlement Layer** – Leverages BTC as the ultimate settlement guarantee.

## Contract Interface Overview

### Public Functions

| Function | Description |
|---------|-------------|
| `register-brand(name)` | Register a new brand |
| `verify-brand(brand)` | Verify a brand (owner-only) |
| `list-product(name, description, price)` | List a fixed-price product |
| `purchase-product(product-id)` | Purchase a listed product |
| `create-auction(name, description, min-price, duration)` | Create a new auction |
| `place-bid(product-id, bid-amount)` | Bid on an active auction |
| `end-auction(product-id)` | Settle an auction and transfer funds |
| `add-review(product-id, rating, comment)` | Submit a product review |

### Read-Only Functions

| Function | Description |
|---------|-------------|
| `get-product(product-id)` | Retrieve product details |
| `get-brand(brand)` | Fetch brand info |
| `get-review(product-id, reviewer)` | Read a specific review |
| `get-auction(product-id)` | Fetch auction details |

## Constants & Parameters

- `platform-fee`: `u25` (2.5%)
- `min-name-length`: `u1`
- `min-description-length`: `u1`
- Minimum auction duration: `u10` blocks

## File Structure

```bash

contracts/
└── bitserve.clar     # Main smart contract
```

## Deployment & Testing

1. Deploy on the **Stacks testnet** using Clarinet:

   ```bash
   clarinet check
   clarinet test
   clarinet deploy
   ```

2. Interact via Clarity console or frontend dApp integration.

## Future Enhancements

- Escrow-based settlement with time-locked releases
- Dispute resolution with DAO arbitration
- Product categories and search indexing
- Analytics dashboard for sellers and admins

## License & Contributors

This project is open-source under the **MIT License**. Contributions, issues, and feature suggestions are welcome!
