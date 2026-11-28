---
sidebar_position: 4
title: Staking & Delegation
description: Earn QSR rewards by staking ZNN and earn ZNN rewards by delegating to a Pillar without locking your coins.
---

# Staking & Delegation

Syrius offers two built-in ways to earn rewards with your **ZNN** — **Staking** (earns **QSR**) and **Delegation** (earns **ZNN**). They work very differently, and understanding both helps you choose the right balance of liquidity and yield.

| Feature | Staking | Pillar Delegation |
| --- | --- | --- |
| **Asset Used** | ZNN | ZNN |
| **Reward Earned** | **QSR** | **ZNN** |
| **Minimum Amount** | **1 ZNN** | **1 ZNN** per address |
| **Lockup Period** | **1 – 12 months** (30 days per month; locked until expiry) | **None** — your ZNN stays 100% liquid and spendable |
| **Penalty to Exit** | Cannot cancel before expiration date | Undelegate anytime with **zero penalty** |
| **Plasma Required** | `105,000` Plasma (or PoW fallback) | `84,000` Plasma (or PoW fallback) |

:::tip Can You Stake and Delegate the Same ZNN?
No — staked ZNN is locked in the Stake embedded contract, so it is no longer part of your liquid balance counted toward Pillar delegation. However, you can stake part of your ZNN on an address while delegating the remaining liquid ZNN on the same address (or use separate derived addresses for each).
:::

---

## Staking ZNN for QSR Rewards

Staking locks a chosen amount of ZNN for **1 to 12 months** (each month is 30 days) in exchange for ongoing **QSR** rewards. Longer durations receive a higher reward multiplier.

### How to Create a Stake

1. Open the **Staking** tab.
2. Confirm your active address has at least **1 ZNN** (and consider fusing QSR for Plasma if you want instant confirmation without PoW).
3. Click the **Stake** button in the top summary bar to expand the stake creation panel.
4. Select your lock **Duration**: choose **`1`**, **`2`**, **`3`**, **`6`**, **`9`**, or **`12 months`**. Syrius previews the estimated **Unlocks** date.
5. Enter the **Amount** of ZNN to stake (minimum `1 ZNN`, or click **Max**).
6. Click **Stake [Amount] ZNN** and confirm the transaction (Ledger users: approve on your device).

:::warning Staked ZNN Cannot Be Unlocked Early
Once confirmed on-chain, a staking entry cannot be canceled until its unlock date is reached. Double-check both the amount and duration before confirming.
:::

### Collecting Staking Rewards

- Staking rewards accumulate in **QSR** and appear under **To collect** in the **Staking** summary bar (and in the Dashboard **To Collect** card).
- Click **Collect** (or **Collect all** on the Dashboard) to claim your earned QSR.
- Reward collection blocks take at least **30 seconds** to update and appear in your available QSR balance.
- Click **Rewards** to view a chart of your historical staking payouts.

### Canceling an Expired Stake

1. When a stake reaches its expiration date, its status badge changes to **Unlocked**.
2. Click **Cancel** on that row in the **Stakes** table.
3. Your original ZNN principal is returned in full to your address once the cancel block confirms and is received.

---

## Delegating ZNN to a Pillar

Delegating assigns the voting/reward weight of your address's liquid ZNN balance to an active **Pillar** node. In return, that Pillar shares a portion of its **ZNN** rewards with its delegators.

- Your ZNN **never leaves your wallet** and is **never locked**.
- You can send, receive, or **Undelegate** at any time with zero penalties.
- Delegation applies to your **selected address's entire liquid ZNN balance**. As you add or spend ZNN on that address, your delegation weight automatically adjusts.

### How to Choose & Delegate to a Pillar

1. Open the **Pillars** (Nodes) tab.
2. Browse, search, or sort active Pillars by **Weight**, **Uptime**, or **Name**.
3. Click a Pillar row to inspect its details before delegating:
   - **Momentum / Delegation reward sharing percentages**: Higher percentages shared with delegators mean a larger share of rewards distributed to you.
   - **Uptime (Expected vs. Produced Momentums)**: Pillars that reliably produce momentums generate consistent rewards.
   - **Weight**: Total ZNN delegated to that Pillar.
4. Make sure your selected address holds at least **1 ZNN**.
5. Click **DELEGATE** on your chosen Pillar and confirm.

### Collecting Delegation Rewards & Undelegating

- Your delegated Pillar and current weight appear in the top bar of the **Pillars** tab.
- Click **Collect** in the top bar (or **Collect all** on the Dashboard) whenever ZNN rewards are ready. Allow ~30 seconds for the reward block to settle.
- To switch Pillars or stop delegating, click **UNDELEGATE** in the top bar — once confirmed, you can immediately delegate to a different Pillar if desired.

## Related Guides

- Learn how to fuse QSR for faster staking and delegation transactions in [Plasma & Feeless Transactions](./plasma-and-feeless-tx.md).
- Interested in operating your own network infrastructure? Read [Pillars & Sentinels](./pillars-and-sentinels.md).
