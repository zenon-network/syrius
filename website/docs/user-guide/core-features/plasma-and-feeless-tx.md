---
sidebar_position: 3
title: Plasma & Feeless Transactions
description: Understand how Plasma enables feeless transactions on Network of Momentum, how to fuse QSR, when PoW fallback is used, and how to cancel fuses.
---

# Plasma & Feeless Transactions

Unlike traditional blockchains that charge a gas fee on every transfer, **Network of Momentum transactions are feeless**. To prevent network spam while keeping transfers free, Zenon uses a regenerating resource called **Plasma**.

## How Plasma Works

Every transaction on Network of Momentum consumes a small amount of Plasma from the sending (or receiving) address. You can obtain Plasma in two ways:

1. **Fuse QSR (Recommended)**: Temporarily lock **QSR** (minimum **10 QSR**) to generate continuous, regenerating Plasma for any Zenon address.
   - Your fused QSR is **never spent or burned** — you can cancel the fusion after **10 hours** and recover **100% of your QSR**.
   - You can fuse QSR for your own address *or* for another beneficiary address (for example, funding Plasma for a friend's wallet or a hardware wallet address).
2. **Proof-of-Work (PoW) Fallback**: If an address does not have enough fused Plasma for an operation, Syrius automatically computes a lightweight local Proof-of-Work puzzle using your CPU.
   - PoW takes a few seconds per transaction and is limited to **1 transaction per momentum** (10 seconds).
   - Complex embedded contract actions require more Plasma and are much smoother with fused QSR.

## Plasma Levels & Requirements

Each type of wallet operation requires a specific amount of Plasma:

| Operation | Plasma Required |
| --- | --- |
| Standard send / receive transfer | `21,000` Plasma |
| Delegate to a Pillar | `84,000` Plasma |
| Create a ZNN Stake | `105,000` Plasma |
| Issue a ZTS Token | `189,000` Plasma |
| Register or manage a Pillar or Sentinel | `252,000` Plasma |

As a rule of thumb inside Syrius:

| Plasma Tier | Fused QSR Guidance | Best For |
| --- | --- | --- |
| **Insufficient** | Under `10 QSR` | Relies on local PoW fallback (max 1 transaction per momentum). |
| **Low Plasma** | `10 – 89 QSR` | Occasional sends and receives without waiting on PoW. |
| **Average Plasma** | `90 – 119 QSR` | Frequent everyday transfers, swaps, and staking/delegation. |
| **High Plasma** | `120+ QSR` | Recommended for complex operations: registering Pillars or Sentinels, issuing ZTS tokens, and high-frequency activity. |

:::tip Plasma Regenerates Automatically
As you send transactions, your address's available Plasma dips temporarily and regenerates back up to its maximum capacity over subsequent momentums — as long as your QSR remains fused.
:::

## How to Fuse QSR for Plasma

1. Open the **Plasma** tab.
   - The left panel displays your active address's current Plasma gauge, fused QSR total, and estimated number of sends. Expand **Other addresses** to inspect Plasma levels across all your wallet addresses.
2. Click the **Fuse** button in the top summary bar to open the inline Fuse drawer.
3. Enter the **Amount** of QSR to fuse (at least **10 QSR**, or click **Max**).
4. In the **For** field, confirm the **Beneficiary address** (`z1...`):
   - It defaults to your currently selected address.
   - Use the **Another address** dropdown to choose another one of your wallet addresses, or paste any external `z1...` address.
5. Click **Fuse [Amount] QSR**.
6. Wait a moment for the fusion transaction to confirm — your Plasma bar updates shortly afterward.

:::info 10-Hour Lockup Window
Once fused, QSR remains locked for **10 hours** before it becomes eligible to cancel. During those 10 hours, the beneficiary address enjoys instant Plasma immediately, and you retain full ownership of the QSR.
:::

## Managing & Canceling Fused QSR

Every fusion you create appears in the **Fused** table on the right side of the **Plasma** tab, showing the QSR amount, beneficiary address, and expiration/lockup countdown.

### Cancel a Single Fusion

1. Wait until the entry's 10-hour lockup has elapsed (the entry becomes cancelable).
2. Click **Cancel** on that row and confirm the dialog.
3. Your QSR returns to your available balance once the cancel transaction settles and is received.

### Cancel Multiple Fusions Together

If you have several mature fusion entries:

1. Select the checkboxes next to each cancelable fusion row.
2. Click **Cancel [N] fuses** in the table header to submit the cancellations together.

:::caution Canceling Removes Plasma for the Beneficiary
Canceling a fusion immediately stops generating Plasma from that QSR for the beneficiary address. Keep at least 10 QSR fused on addresses you use frequently so future transactions remain instant.
:::
