---
sidebar_position: 5
title: Pillars & Sentinels
description: Requirements and step-by-step guide for registering, managing, updating, collecting rewards from, and disassembling Pillars and Sentinels in Syrius.
---

# Pillars & Sentinels

**Pillars** and **Sentinels** are the core infrastructure nodes that secure and observe Network of Momentum. Syrius handles the on-chain **registration, collateral management, reward collection, updates, and disassembly**, while the actual server node software is deployed separately using **`znn-controller`**.

:::info Syrius Registers On-Chain — `znn-controller` Runs the Node
Registering a Pillar or Sentinel in Syrius creates its on-chain slot, but you will **not** earn rewards until you also deploy and keep a live node running using [`znn-controller`](https://github.com/zenon-network/znn_controller_dart/releases/latest):
- **Pillars** must actively produce momentums.
- **Sentinels** must maintain **>90% daily uptime**.
:::

## Requirements at a Glance

| Requirement | Pillar | Sentinel |
| --- | --- | --- |
| **ZNN Collateral** | **15,000 ZNN** (locked; returned on disassemble) | **5,000 ZNN** (locked; returned on disassemble) |
| **QSR Requirement** | **150,000 QSR** base slot fee (increases dynamically per slot) — **BURNED** permanently on registration | **50,000 QSR** — **locked** (returned on disassemble) |
| **Plasma Required** | `252,000` Plasma (High Plasma — 120+ QSR fused recommended) | `252,000` Plasma (High Plasma — 120+ QSR fused recommended) |
| **Rewards Earned** | **ZNN** (momentum + delegation rewards) | **ZNN & QSR** (requires >90% daily uptime) |
| **Governance Voting** | Votes on **Accelerator-Z** projects & phases | No voting rights |

---

## Managing Pillars

Open the **Pillars** tab (inside the unified **Nodes** workspace) to view active network Pillars, manage your delegation, or spawn and manage a Pillar you own.

### Registering (Spawning) a Pillar

1. Fuse enough QSR to reach **High Plasma** (`252,000` Plasma; 120+ QSR fused recommended) on your Pillar owner address.
2. In the **Pillars** tab, open the **`...`** menu in the top bar and select **Spawn a pillar**.
3. Follow the guided registration stepper:
   - **Step 1 — Plasma Check**: Verifies your address has at least `252,000` Plasma.
   - **Step 2 — ZNN Management**: Confirms your selected address holds at least **15,000 ZNN**. This ZNN is locked for the life of the Pillar and unlocked if you disassemble it later.
   - **Step 3 — QSR Management**: Displays the **Current Pillar Slot fee** (starting at 150,000 QSR). Deposit QSR in one or more transactions until your deposit covers the slot fee.
     - You can click **Withdraw** to take back deposited QSR *before* finalizing Pillar registration.
     - Once you complete registration, **all deposited QSR is permanently burned**.
   - **Step 4 — Deploy / Register Pillar**:
     - **Pillar name**: Unique name up to **40 characters** (letters, numbers, and single `-`, `.`, or `_` separators).
     - **Pillar reward address**: The `z1...` address that will be authorized to collect Pillar rewards (defaults to your selected address).
     - **Pillar producer address**: The `z1...` address generated from a **different seed** via `znn-controller` that produces momentums on your Pillar server.
     - **Reward sharing sliders**: Set the percentage of **Momentum rewards** and **Delegation rewards** you share with your delegators (0% – 100%).
4. Click **Register** and confirm the transaction.
5. Complete node deployment on your server using `znn-controller`.

:::danger Pillar QSR Is Burned Permanently
Double-check every detail before clicking **Register**. Unlike your 15,000 ZNN collateral (which can be unlocked by disassembling the Pillar), the QSR deposited for a Pillar slot is **burned** and cannot be recovered after registration.
:::

### Updating, Collecting Rewards & Disassembling a Pillar

When your active address owns a Pillar, click your Pillar's button (or **Your pillar** from the **`...`** menu) to open **Your Pillar**:

- **Collect rewards**: Click **Collect** to claim pending ZNN rewards (allow ~30 seconds to update). Click **Rewards** to inspect historical payouts.
- **Update Pillar**: Click **Update** to change your Pillar's **Producer address**, **Reward address**, or **Momentum / Delegation reward-sharing percentages**.
- **Disassemble (Revoke) Pillar**: Pillars have a revocation cooldown window shown under **REVOCABLE**. Once the revocation window opens (badge shows **Unlocked**), the **DISASSEMBLE** button appears so you can revoke the Pillar and unlock your **15,000 ZNN** collateral.

---

## Managing Sentinels

In the **Nodes** workspace, switch to the **Sentinels** sub-tab (or open **Sentinels** from navigation) to view active Sentinels and manage your own.

### Registering (Spawning) a Sentinel

:::warning Never Reuse a Previously Revoked Sentinel Address
If an address has **previously revoked (disassembled) a Sentinel**, it **cannot** be used to create a new Sentinel again. Always switch to a fresh derived address before depositing QSR for a Sentinel!
:::

1. Ensure your chosen fresh address has **High Plasma** (`252,000` Plasma), **5,000 ZNN**, and **50,000 QSR**.
2. Click **Spawn** in the **Sentinels** tab to launch the Sentinel registration stepper:
   - **Step 1 — Plasma Check**: Confirms `252,000` Plasma.
   - **Step 2 — ZNN Management**: Verifies **5,000 ZNN** available.
   - **Step 3 — QSR Management**: Deposit **50,000 QSR** (unlike Pillars, Sentinel QSR is **locked, not burned**, and returns to you if you disassemble the Sentinel). You can withdraw unspent deposits before registering.
   - **Step 4 — Register Sentinel**: Confirm registration on-chain.
3. Deploy and monitor your Sentinel server with `znn-controller` to keep daily uptime above **90%**.

### Collecting Sentinel Rewards & Disassembling

- **Collect rewards**: Claim accumulated **ZNN and QSR** rewards via **Collect** in the Sentinel top bar (or **Collect all** on the Dashboard).
- **Disassemble Sentinel**: Check the **REVOCABLE** badge to see when the revocation window is open. When revocable, you can disassemble the Sentinel to unlock and recover both your **5,000 ZNN** and **50,000 QSR** collateral.

## Related Guides

- Need more Plasma before registering? See [Plasma & Feeless Transactions](./plasma-and-feeless-tx.md).
- Want to vote on ecosystem proposals with your Pillar? See [Accelerator-Z](./accelerator-z.md).
