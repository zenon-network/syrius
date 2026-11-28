---
sidebar_position: 7
title: P2P Swaps
description: Conduct feeless, trustless peer-to-peer ZTS token swaps using HTLCs in Syrius, including step-by-step walkthroughs, timing safety rules, and reclaiming deposits.
---

# P2P Swaps

**P2P Swaps** let you trade **ZNN, QSR, or any ZTS token** directly with another person on Network of Momentum — **with zero fees and zero intermediaries**. Swaps use on-chain **Hash Time-Locked Contracts (HTLCs)** so neither party can run off with the other's funds if someone backs out.

:::warning Experimental Feature — Read Before Swapping
P2P Swaps are marked **experimental** in Syrius. Failing to follow the timing rules below can result in **permanent loss of funds**. Start with a small test amount and consider **splitting large trades into multiple smaller swaps**.
:::

## Before You Start a Swap

1. **Agree on terms off-chain**: Connect with your counterparty (for example, in a chat or community channel) and agree on:
   - Which tokens and exact amounts you are trading (e.g., `100 ZNN` for `1,000 QSR`),
   - Who is the **Starting Party** and who is the **Joining Party**, and
   - The Joining Party's `z1...` address (shared with the Starting Party).
2. **Verify your computer's clock**: When you open the **P2P Swaps** tab, Syrius checks whether your OS clock is within 5 minutes of the network. Fix any clock discrepancy before starting.
3. **Check your Plasma**: Make sure you have sufficient Plasma (fused QSR) or wait if Syrius is currently generating PoW Plasma.
4. **Plan to stay on this computer**: The swap secret is stored locally in Syrius's encrypted swap database on your machine, so you must complete the swap on the **same computer** you started it on.
5. **Use a trusted node (or verify on a block explorer)**: Prefer the **Embedded Node** or your own **Local Node** when running P2P swaps. A remote node controls the chain data Syrius sees — a malicious remote node colluding with your counterparty could show a fake counter-deposit so you publish your secret and lose your initial deposit. If you are connected to a remote node, independently verify your counterparty's counter-deposit on a block explorer before completing the swap (see [Node Modes](../hardware-and-nodes/node-modes.md)).

---

## Step-by-Step Swap Walkthrough

Suppose **Alice** (Starting Party) wants to swap **100 ZNN** for **Bob's** (Joining Party) **1,000 QSR**.

### Step 1: Alice Starts the Swap

1. Alice opens the **P2P Swaps** tab and clicks **Start swap** (acknowledging the experimental warning on first use).
2. Alice selects her sending address, picks the token and amount she is sending (`100 ZNN`), and pastes **Bob's `z1...` address** as the **Counterparty address**.
3. Alice confirms to lock her `100 ZNN` in an initial HTLC deposit (locked for **8 hours**).
4. Once started, Alice expands her new swap row and clicks **Copy deposit ID** (or **Copy for them**), then sends that **Deposit ID** to Bob via chat.

### Step 2: Bob Joins the Swap

1. Bob opens the **P2P Swaps** tab and clicks **Join swap**.
2. Bob pastes **Alice's Deposit ID** so Syrius fetches the on-chain details of Alice's locked deposit.
3. **Bob carefully verifies the token standard (`zts1...`) and exact amount** Alice deposited for him.
   - If the token is not in Bob's Favorites, Syrius explicitly reminds him to verify the `zts1...` token standard!
4. Bob enters the agreed counter-deposit (`1,000 QSR`) and clicks to join, locking his QSR in a counter HTLC (locked for **1 hour**).

:::info Joining Time Window
Bob has approximately **1 hour** after Alice starts the swap to join safely. Syrius blocks joining if Alice's deposit has less than **7 hours** remaining (or if an external HTLC's duration exceeds **24 hours**) so Bob always has at least **6 hours** of safety margin to claim his funds.
:::

### Step 3: Alice Completes the Swap

1. Alice's Syrius detects Bob's counter-deposit and shows the exact token and amount Bob deposited.
2. Alice verifies that Bob deposited the agreed `1,000 QSR` (if connected to a remote node rather than her Embedded or Local Node, she also confirms Bob's counter-deposit on a block explorer).
   - *Wrong token or amount?* **Do not complete the swap!** Wait until your deposit expires and reclaim your funds safely.
3. Alice clicks to **complete the swap** within **50 minutes** of Bob joining.
4. Alice receives her `1,000 QSR` immediately.

### Step 4: Bob's Syrius Automatically Unlocks His Funds

1. When Alice completes the swap, her transaction reveals the cryptographic secret on-chain.
2. **Bob's running Syrius automatically spots that secret on-chain and unlocks the `100 ZNN` for Bob** — no manual click required!

---

## Critical Timing & Safety Rules

Understanding these exact timers keeps your funds safe:

| Timer / Rule | Duration | What It Means for You |
| --- | --- | --- |
| **Initial deposit lock** (Starting Party) | **8 hours** | If the counterparty never joins (or the swap fails), the Starting Party can reclaim their deposit after 8 hours. |
| **Time to join** (Joining Party) | **~1 hour** | The Joining Party should join promptly within ~1 hour of swap start. |
| **Counter deposit lock** (Joining Party) | **1 hour** | If the Starting Party never completes the swap, the Joining Party can reclaim their deposit after 1 hour. |
| **Time to complete** (Starting Party) | **~50 minutes** | Completion must start at least **10 minutes** before the 1-hour counter deposit expires so the unlock confirms safely on-chain. |
| **Time to detect & unlock** (Joining Party) | **At least 6 hours** | Keep Syrius open after joining! If Syrius closes, you must reopen it within 6 hours so it can unlock your funds before the 8-hour initial deposit expires. |

### Built-In Protections in Syrius

- **Wakelock**: While you are waiting as the Joining Party, Syrius requests an OS display wakelock while monitoring the chain. Because a display wakelock does not guarantee that your computer stays awake under all OS power policies, disable system sleep in your OS power settings and keep Syrius running and connected until the swap completes.
- **No Auto-Lock During Active Swaps**: Syrius temporarily pauses automatic wallet locking while an incoming swap is active so automatic unlocking is never blocked.
- **HTLC Watchtowers**: Community members can run open-source [HTLC Watchtowers](https://github.com/hypercore-one/htlc-watchtower) that watch the chain for revealed secrets and automatically submit unlock transactions on your behalf as an extra safety net.

:::danger What Happens If the Joining Party Never Unlocks Before Expiration?
If you are the **Joining Party**, Alice completes the swap (taking your deposit), and your Syrius remains closed for more than 6 hours until Alice's 8-hour initial deposit expires, **Alice can reclaim her deposit too and your funds will be lost**. Always stay online with Syrius open until the swap status shows **Completed**!
:::

---

## Reclaiming Expired Deposits

If either party backs out and a swap does not complete, your funds remain safe until your HTLC timer expires:

1. Wait until the swap's expiration countdown reaches `0` (status changes to **To reclaim**).
2. Filter the Swaps table by **To reclaim**, expand the swap row, and click **Reclaim funds**.

### Lost Access to the Original Computer?

If you need to reclaim an expired deposit from a different machine (after restoring your wallet with your seed phrase):

1. Open **P2P Swaps**, click the **`...`** options menu in the swaps table header, and choose **Reclaim deposit**.
2. Paste your **Deposit ID** (you can also find it via a block explorer if you didn't save it) and click to reclaim.

:::tip Swap History Limit
Syrius stores up to **500** local P2P swap records. When the history is full, starting a new swap removes the oldest history entry.
:::

---

## Technical Deep Dive

Curious about the exact SHA3-256 HTLC contract parameters, state transitions, and sequence flow under the hood? Read the [HTLC P2P Swaps Protocol Specification](/docs/developers/architecture/p2p-swaps-protocol).
