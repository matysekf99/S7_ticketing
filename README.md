# Ticketing Smart Contract System

A blockchain-based ticketing system built with Solidity, using ERC-20 tokens for payments and ERC-721 NFTs for tickets.

## Architecture

The project consists of three main contracts:

- **Token.sol**: ERC-20 token used as payment currency
- **NftTicket.sol**: ERC-721 NFT representing concert tickets
- **Ticketing.sol**: Main contract orchestrating the ticketing system

## Features

### Artist & Venue Management
- `createArtist()` / `updateArtist()`: Manage artist profiles (name, type, tickets sold)
- `createVenue()` / `updateVenue()`: Manage venues (name, capacity, revenue percentage)

### Concert Management
- `createConcert()`: Create concerts with date, artist, and venue

### Ticket Operations
- `emitTicket()`: Artists emit tickets for their concerts
- `buyTicket()`: Purchase tickets using ERC-20 tokens
- `sellTicket()`: List tickets for resale (capped at original price)
- `transferTicket()`: Transfer tickets to another address
- `useTicket()`: Use tickets within 24h before the concert

### Revenue Distribution
- `cashOut()`: Artists withdraw revenue after concerts, automatically splitting with venues based on percentage

### Ticket Redemption
- `emitRedeemableTicket()`: Create free tickets with redemption codes
- `redeemTicket()`: Claim tickets using secret codes

## Technical Implementation

### ERC-20 Token Payment
Buyers approve the Ticketing contract to spend tokens, enabling atomic swaps between ERC-20 and ERC-721.

### ERC-721 NFT Tickets
Each ticket is a unique NFT with metadata:
- Concert ID
- Purchase price
- Used status
- Redeemable flag & code hash

### Security Features
- Ownership verification for all operations
- Price cap enforcement for resales
- Time-based validation for ticket usage
- Hash-based secret codes for redemption

## Test Results

All tests passing successfully:

```
❯ forge test -vvv
[⠊] Compiling...
[⠔] Compiling 1 files with Solc 0.8.30
[⠒] Solc 0.8.30 finished in 427.38ms
Compiler run successful!

Ran 10 tests for test/Ticketing.t.sol:TicketingTest
[PASS] test_BuyTicket() (gas: 521566)
[PASS] test_CashOut() (gas: 563154)
[PASS] test_CreateArtist() (gas: 113677)
[PASS] test_CreateConcert() (gas: 251440)
[PASS] test_CreateVenue() (gas: 108277)
[PASS] test_EmitTicket() (gas: 434480)
[PASS] test_RedeemTicket() (gas: 466886)
[PASS] test_RevertWhen_RedeemTicketWrongCode() (gas: 394614)
[PASS] test_RevertWhen_SellTicketTooExpensive() (gas: 437022)
[PASS] test_UseTicket() (gas: 475390)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 2.72ms (1.82ms CPU time)

Ran 1 test suite in 5.27ms (2.72ms CPU time): 10 tests passed, 0 failed, 0 skipped (10 total tests)
```

## Technologies

- Solidity ^0.8.13
- Foundry (testing & deployment)
- OpenZeppelin Contracts (ERC-20, ERC-721)

## Project Structure

```
contracts/
├── src/
│   ├── Ticketing.sol       # Main contract
│   ├── Token.sol           # ERC-20 payment token
│   └── NftTicket.sol       # ERC-721 ticket NFT
└── test/
    └── Ticketing.t.sol     # Comprehensive test suite
```
