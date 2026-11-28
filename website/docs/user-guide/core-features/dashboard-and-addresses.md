---
sidebar_position: 1
title: Dashboard & Addresses
description: Navigate the Syrius Home dashboard, manage multiple addresses and contacts, understand auto-receive and notifications, and lock your wallet safely.
---

# Dashboard & Addresses

After unlocking Syrius, you land on the **Dashboard** (Home) screen — your command center for balances, Plasma status, recent activity, pending transactions, and claimable rewards.

## Dashboard Overview

The Dashboard is divided into three main areas:

1. **Top Hero Banner**:
   - **Active Address & Label**: Displays your currently selected address (e.g., `ADDRESS 1`), a shortened `z1...` preview, a one-click **Copy address** button, an **address switcher** dropdown (when you have multiple addresses), and a **Hide balances** privacy toggle (masks balances as `••••`).
   - **Dual-Coin Balances**: Shows your available **ZNN** and **QSR** balances for the active address.
   - **Plasma Gauge**: Displays your address's current Plasma level (`NONE`, `LOW`, `MED`, `HIGH`) and an estimate of how many standard sends it supports. Clicking it opens the [Plasma](./plasma-and-feeless-tx.md) tab.
   - **Quick Actions**: One-click **Send**, **Receive**, and **Zap** buttons.
2. **Activity Feed (Left Column)**:
   - Lists your recent transactions (ZNN, QSR, ZTS tokens, staking, delegation, and contract calls).
   - Toggle between **All addresses** and the currently selected address, refresh manually, open any transaction in your chosen block explorer, or inspect incoming **Zap** messages.
3. **Right Sidebar**:
   - **To Collect**: Aggregates claimable rewards from **Staking**, **Pillars**, and **Sentinels** for your selected address, with a single **Collect all** button.
   - **Tokens Accordion**: Quick summary of ZTS tokens held on the selected address.
   - **Pending Accordion**: Lists unreceived incoming transactions waiting to be received.

## Keyboard Shortcuts & Quick Navigation

Syrius includes desktop shortcuts to move around faster:

| Shortcut | Action |
| --- | --- |
| `Ctrl+K` (Windows/Linux) / `Cmd+K` (macOS) | Open **Quick Navigation** to jump to any screen, action, or contact |
| `Ctrl+1` – `Ctrl+8` | Switch between primary tabs (Dashboard, Transfer, Staking, Pillars, Plasma, Tokens, P2P Swaps, Accelerator-Z) |
| `Ctrl+R` | Refresh balances and transactions |
| `Ctrl+L` | Lock the wallet immediately |

## Managing Multiple Addresses

A single Syrius recovery seed phrase deterministically generates as many Zenon addresses (`z1...`) as you need. Separating addresses is great for organizing savings, staking, Pillar/Sentinel operations, and everyday spending.

To manage addresses, open **Settings → Addresses**:

- **Add a new address**: Click **Add address** to derive the next address in sequence (`Address 2`, `Address 3`, etc.).
- **Switch active address**: Click any address row in **Settings → Addresses** (marked with a `selected` badge), or use the address switcher on the Dashboard or Transfer screen.
- **Edit labels**: Click the pencil (**Edit**) icon next to any address to give it a memorable label (up to 80 characters, such as *Staking* or *Savings*).
- **Copy address**: Click the copy icon to copy the full `z1...` address to your clipboard.
- **Account-chain stats**: Expand the **Account chain** card at the bottom to inspect your selected address's block count and first block hash.

### Saved Contacts (Address Book)

In **Settings → Addresses → Contacts**, you can save frequently used recipient addresses with human-readable names:

1. Click **Add contact**.
2. Enter a **Name** and paste their `z1...` address, then click **Confirm**.
3. Saved contacts appear as quick-select pills on the **Send** screen, display their names in your **Activity** feed, and power Syrius's **lookalike address warning** against address-poisoning scams.

## Auto-Receiver & Unreceived Transactions

On Network of Momentum, every transfer consists of two separate blocks: a **send block** published by the sender and a **receive block** published by the recipient. Funds only appear in your spendable balance once the receive block is published.

- **Auto-receiver (On by default)**: While Syrius is unlocked and connected to a synced node, it automatically detects incoming transactions across all your derived wallet addresses and publishes receive blocks for you.
- **Manual receiving**: If you turn **Auto-receiver** off under **Settings → Wallet**, incoming funds wait safely in the **Pending / To Receive** card until you manually click to receive them.

:::tip Why Is an Incoming Transaction Still "Pending"?
Incoming transactions remain unreceived if:
- Your node has not finished syncing yet,
- **Auto-receiver** is turned off in **Settings → Wallet**, or
- Your address has no fused QSR Plasma and Syrius is momentarily generating Proof-of-Work to receive it.
:::

## Notifications & System Tray

- **In-app notifications**: Click the bell icon in the navigation rail to open the **Notifications** drawer showing transaction confirmations, reward collections, node changes, and any errors.
- **Desktop notifications**: Enable native OS alerts under **Settings → Wallet → Desktop notifications**.
- **System tray**: Closing or minimizing can be managed from the Syrius tray icon (**Show wallet**, **Hide wallet**, **Exit wallet**).

## Locking Your Wallet

Locking Syrius immediately closes your active wallet handle in memory and requires your password to reopen.

- **Manual lock**: Click the **Lock** icon in the navigation rail or press `Ctrl+L`.
- **Auto-lock**: By default, Syrius locks automatically after **15 minutes** of inactivity. Adjust this under **Settings → Security → Lock after** (`5 min`, `15 min`, `1 h`, or `On close`).

:::info Auto-Lock Pauses During Active P2P Swaps
To prevent you from missing an atomic swap completion window, Syrius intentionally suspends auto-locking while an incoming P2P swap is actively waiting to complete.
:::
