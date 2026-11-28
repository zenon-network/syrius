---
sidebar_position: 6
title: ZTS Tokens
description: Browse, favorite, create, mint, burn, and manage Zenon Token Standard (ZTS) tokens directly in Syrius.
---

# ZTS Tokens

The **Zenon Token Standard (ZTS)** lets anyone issue native fungible tokens directly on Network of Momentum without writing or auditing custom smart contracts. Every ZTS token gets a unique on-chain identifier starting with **`zts1...`** and inherits Network of Momentum's feeless transfers and native P2P swap support.

## Exploring & Managing Your Token List

Open the **Tokens** tab to inspect the ZTS ecosystem:

- **Top Summary Bar**: Shows how many ZTS tokens you currently hold (**You hold**), how many you own/issued (**Issued by you**), the fixed **1 ZNN** issuance fee, and the **Create Token** button.
- **Filter Views**: Switch between **Held** (tokens you hold or own), **Favorites** (tokens you starred), and **All** (all ZTS tokens issued across the network).
- **Search**: Find any token by **name**, **symbol**, **owner address**, or **`zts1...` token standard**.
- **Favorites**: Click the star icon beside any token to add or remove it from your favorites. Favorite status also helps Syrius warn you during [P2P Swaps](./p2p-swaps.md) if you are receiving an unverified or unfamiliar token.
- **Expand Details**: Click any token row to see its decimals, website domain, full `zts1...` token standard, flags, explorer link, and (if you own or hold it) management actions.

:::warning Verify Token Standards, Not Just Symbols
Multiple tokens on the network can share similar names or symbols. Always verify the exact **`zts1...` token standard** before buying, swapping, or accepting a ZTS token.
:::

---

## Creating a New ZTS Token

Anyone can issue a ZTS token using Syrius's guided creation stepper.

### Requirements

- **Issue Fee**: **1 ZNN** — **permanently burned** upon token issuance.
- **Plasma Required**: `189,000` Plasma (High Plasma — 120+ QSR fused recommended).

### Step-by-Step Creation

1. In the **Tokens** tab, click **Create Token**.
2. **Plasma Check**: Verify your selected address has at least `189,000` Plasma.
3. **ZNN Check**: Confirm your issuance address holds at least **1 ZNN** (this address becomes the initial token owner).
4. **Details**:
   - **Token Name**: Up to **40 characters**; letters and numbers with optional single `-`, `.`, or `_` separators.
   - **Token Symbol**: Up to **10 characters**; **uppercase letters and numbers only** (`A–Z`, `0–9`). Cannot use reserved symbols (`ZNN`, `QSR`).
   - **Token Domain**: Your project's domain name **without protocol** (up to **128 characters**, e.g., `myproject.org` — omit `https://`).
5. **Mintable & Burnable Options**:
   - **Mintable**: Check this if you want the owner to be able to mint additional tokens later up to your Max Supply. Leave unchecked for a fixed supply.
   - **Burnable by any holder**: When checked, **any** holder can burn tokens from their own balance. When unchecked, **only the token owner** can burn tokens.
6. **Metrics**:
   - **Decimals**: Choose between **`0` and `18`** decimal places (ZNN and QSR use `8`).
   - **Max Supply**: Required when **Mintable** is enabled (must be greater than or equal to Total Supply). For non-mintable tokens, Max Supply equals your fixed supply.
   - **Total Supply**: The initial circulating supply minted directly to your issuance address upon creation (can be `0` if Mintable is enabled).
7. **Issue Token**: Review all settings carefully and click **Issue** to burn 1 ZNN and create your ZTS token on-chain.

:::caution Most Token Properties Are Permanent
Your token's **Name**, **Symbol**, **Domain**, **Decimals**, and **Max Supply** cannot be edited after issuance. Review every field carefully before submitting!
:::

---

## Managing Tokens You Own (or Hold)

Expand any token row in the **Tokens** tab to access available actions:

### Token Owner Actions

When your currently selected address is the token's **owner**, you see four owner tabs:

1. **Mint** *(Mintable tokens only)*: Mint new tokens (up to the remaining allowance under **Max supply**) to any `z1...` destination address.
2. **Burn**: Permanently destroy tokens from your balance, reducing total supply.
3. **Transfer Ownership**: Transfer owner privileges to a new `z1...` address.
4. **Flags**: Permanently update token flags (for example, revoking mintability to lock supply forever, or toggling burnability/utility flags).

:::danger Ownership Transfers Are Irreversible
Once you transfer ownership of a ZTS token to another address, only the new owner can mint, update flags, or transfer ownership again.
:::

### Token Holder Burn

If a token has **Burnable by any holder** enabled and you hold a non-zero balance, expanding the token row lets you burn tokens directly from your own balance.
