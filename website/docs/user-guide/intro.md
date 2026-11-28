---
sidebar_position: 1
title: Welcome to Syrius
description: Learn what Syrius is, how Zenon Network's dual-coin system works, and how to safely navigate this desktop wallet guide.
---

# Welcome to Syrius

**Syrius** (`s y r i u s`) is the official cross-platform, open-source desktop wallet for **Zenon Network** — the Network of Momentum (NoM) Phase 1 (Alphanet). It gives you direct, self-custodial control over your ZNN, QSR, and custom ZTS tokens, along with built-in access to feeless transactions, staking, Pillar delegation, trustless peer-to-peer swaps, Accelerator-Z governance, and dApp connections.

:::danger Security First — Syrius Is Non-Custodial
**Only you control your recovery seed phrase, Seed Vault, and wallet password.** Zenon Network contributors, moderators, and support volunteers will **never** ask for your 12- or 24-word seed phrase, Seed Vault file, Seed Vault Key, or password. Anyone asking for them is trying to steal your funds.
:::

## What Makes Zenon & Syrius Different

Network of Momentum uses a **dual-coin architecture** designed for fast, feeless everyday transactions:

| Asset | Symbol | Role in Syrius |
| --- | --- | --- |
| **Zenon** | **ZNN** | Primary network asset used for transfers, **Staking** (to earn QSR), **Delegating** to Pillars (to earn ZNN), issuing ZTS tokens, submitting Accelerator-Z proposals, and Pillar/Sentinel collateral. |
| **Quasar** | **QSR** | Fused to generate **Plasma** — the anti-spam resource that makes transactions **feeless** and instant — and used for Pillar slot fees and Sentinel collateral. |
| **Zenon Token Standard** | **ZTS** | Custom fungible tokens issued directly on Network of Momentum (`zts1...`). You can hold, send, receive, swap, and create ZTS tokens natively in Syrius. |

Key capabilities built into Syrius include:

- **Feeless Transactions via Plasma**: Fuse QSR (minimum 10 QSR) to send transactions with zero fees, or fall back to built-in local Proof-of-Work (PoW) when you have no Plasma.
- **Built-In Full Node**: Run the integrated **Embedded Node** (`go-zenon`) directly inside Syrius for maximum privacy, connect to your own local full node, or connect to a community node to get started immediately.
- **Hardware Wallet Support**: Pair a **Ledger** device over USB so your private keys never leave hardware.
- **Native DeFi & Governance**: Stake ZNN, delegate to Pillars without locking your coins, conduct trustless peer-to-peer HTLC swaps, create ZTS tokens, connect to web dApps via WalletConnect, and participate in Accelerator-Z.

## Supported Platforms

Syrius is a desktop application built for:

- **macOS** (Universal Apple Silicon & Intel `.dmg`)
- **Windows** (64-bit `.zip`, requires Microsoft Visual C++ Redistributable)
- **Linux** (64-bit `.zip`, with optional `udev` setup for Ledger hardware wallets)

:::info Official Downloads Only
Always download Syrius exclusively from the official GitHub Releases page: [github.com/zenon-network/syrius/releases/latest](https://github.com/zenon-network/syrius/releases/latest). Never install wallet binaries shared via direct messages, unofficial mirrors, or search engine ads.
:::

## How This Guide Is Organized

Use the sidebar or jump directly to what you need:

1. **[Getting Started](./getting-started/installation.md)** — Download, verify checksums, install Syrius on macOS/Windows/Linux, and create, restore, or connect a Ledger wallet.
2. **[Core Features](./core-features/dashboard-and-addresses.md)** — Master your Dashboard, Send/Receive/Zap, Plasma fusion, Staking & Delegation, Pillars & Sentinels, ZTS Tokens, P2P Swaps, Accelerator-Z, and WalletConnect dApps.
3. **[Hardware & Nodes](./hardware-and-nodes/node-modes.md)** — Choose between Embedded, Local, and Remote/Community nodes, and configure your Ledger hardware wallet.
4. **[Security & Support](./security-and-support/security-and-backups.md)** — Protect your seed phrase and keystore backups, locate wallet data folders, and troubleshoot common issues.

:::tip Looking for Developer Documentation?
If you want to build Syrius from source, understand the BLoC architecture, or contribute code, head over to the [Developer Overview](/docs/developers/intro).
:::
