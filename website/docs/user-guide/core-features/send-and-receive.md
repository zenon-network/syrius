---
sidebar_position: 2
title: Send, Receive & Zap
description: How to send and receive ZNN, QSR, and ZTS tokens feelessly on Network of Momentum, use QR codes, and send Zaps with optional notes.
---

# Send, Receive & Zap

The **Transfer** tab brings together **Send**, **Receive**, and **Zap** in one clean workspace, along with a **To Receive** card for any pending incoming transactions.

## Zenon Address Format (`z1...`)

Every account on Network of Momentum uses a Bech32-encoded address starting with **`z1`** (for example, `z1qq...`). Syrius automatically validates every address you enter so typos and incompatible addresses from other blockchains are caught before you can send.

## Sending ZNN, QSR, or ZTS Tokens

Transactions on Network of Momentum have **zero gas fees**. They use your address's **Plasma** (from fused QSR) or automatic local Proof-of-Work when Plasma is low.

1. Open the **Transfer** tab and make sure **Send** is selected.
2. Confirm the **sending address** in the top-right address pill (click it to switch to another derived address).
3. Enter or paste the **Recipient Address** (`z1...`), or click one of your **Recent** / saved contact pills.
4. Select the asset to send (**ZNN**, **QSR**, or any **ZTS token** held on that address) from the token selector.
5. Enter the **Amount** (or click **Max** to send your full available balance of that asset).
6. Click **Send** to open the confirmation modal.
7. Carefully double-check the recipient address, sender address, and amount, then click **Send** to broadcast.
   - **Ledger users**: After clicking **Send**, review and physically approve the transaction details on your Ledger device screen.

:::warning Watch for Lookalike Address Warnings
If the address you paste shares the same starting and ending characters as one of your saved contacts or wallet addresses — but has different characters in the middle — Syrius displays a yellow warning banner (*"Looks like [Contact], but is not"*). This protects you against **address-poisoning** scams. Always verify the full address before clicking **Send to the typed address anyway**.
:::

:::info Node Sync Check
If your connected node is more than 2 momentums behind the network, Syrius displays a warning banner and pauses sending until the node catches up. Check [Node Modes](../hardware-and-nodes/node-modes.md) if syncing is taking longer than expected.
:::

## Receiving Funds

1. Open the **Transfer** tab and select **Receive** (or copy your address directly from the Dashboard hero banner).
2. Choose which of your wallet addresses should receive the funds using the top-right address selector.
3. Click **Copy address** to share your `z1...` address, or click **Show QR** to display a scannable QR code.
   - You can also click **Save QR** or **Share QR** to export the QR image.
   - Optionally toggle **Request a specific amount** to pick a token and amount embedded in the QR request.
4. Once the sender broadcasts the transaction:
   - If **Auto-receiver** is enabled (default), Syrius automatically creates the receive block and updates your balance shortly after confirmation.
   - If **Auto-receiver** is disabled, the transfer appears in the **To Receive** card below the transfer form — click it to receive the funds manually.

## Using Zap (Transfer with a Note)

**Zap** lets you quickly send **ZNN**, **QSR**, or both together with an optional short on-chain message attached to the transaction.

1. Open the **Transfer** tab and select **Zap**.
2. Enter the recipient's `z1...` address.
3. Specify the **ZNN** and/or **QSR** amounts.
4. *(Optional)* Enter a brief message.
5. Review and confirm to send.

:::caution On-Chain Messages Are Public & Unverified
- Any message attached to a Zap is written permanently on the public ledger — never include private or sensitive information.
- When reading a Zap message received from someone else on your Dashboard, remember that messages are **written by the sender, not by Syrius**. Treat unsolicited links or "support" claims inside incoming messages as potential phishing.
:::

## Viewing Transactions on a Block Explorer

Click the external-link icon on any row in your Dashboard **Activity** feed to inspect its on-chain confirmation details. You can switch between `explorer.zenon.network` and `zenonhub.io/explorer` under **Settings → Display → Explorer**.

## Related Guides

- Speed up transactions and unlock complex contract calls in [Plasma & Feeless Transactions](./plasma-and-feeless-tx.md).
- Swap ZTS tokens trustlessly with another user in [P2P Swaps](./p2p-swaps.md).
