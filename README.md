# Auction Smart Contract

A decentralized auction system written in Solidity.  
Users can place ETH bids, automatically track the highest bid, withdraw if they are outbid, and the auction owner can finalize the auction to claim funds.

## Features
- Payable bids (`msg.value` used to send ETH with each bid)
- Tracks highest bid and highest bidder
- Refunds for outbid users via **withdraw pattern** (safe against reentrancy)
- Auction duration configurable at deployment
- Owner-only finalization (`endAuction`) to transfer funds
- Events for all key actions: `BidPlaced`, `Withdrawn`, `AuctionEnded`

## Tech Stack
- Solidity ^0.8.20
- Remix IDE
- Deployable on Sepolia testnet

## How it Works
1. **Deploy** contract with an auction duration (in seconds).
2. **Users bid** by calling `bid()` and sending ETH (`msg.value`).
3. If outbid, users can call `withdraw()` to reclaim their ETH.
4. When auction time ends, the **owner calls `endAuction()`** to transfer the highest bid to their address.
---
