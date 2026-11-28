---
sidebar_position: 9
title: WalletConnect & dApps
description: Connect Syrius securely to Zenon web dApps using WalletConnect (Reown), review signing requests safely, and manage active sessions.
---

# WalletConnect & dApps

Syrius includes built-in **WalletConnect v2** (powered by Reown) support so you can connect your desktop wallet to Zenon Network web applications (dApps) without ever exposing your seed phrase or private keys to a browser.

## How WalletConnect Works in Syrius

Connecting to a dApp happens in two stages:

1. **Pairing**: Establishes an encrypted relay channel between Syrius and the dApp using a WalletConnect link (`wc:...`) or QR code.
2. **Session**: Once you approve the dApp's connection proposal, a live session lets the dApp request information or ask you to approve signatures and transactions.

Syrius supports three WalletConnect request methods on Network of Momentum (`zenon` namespace):

| Request Method | What the dApp Is Asking For |
| --- | --- |
| `znn_info` | Read your wallet address, node connection, and chain details. |
| `znn_sign` | Cryptographically sign a text message with your address (does not move funds). |
| `znn_send` | Broadcast an on-chain transaction (transfer, stake, contract call, etc.). |

:::info You Always Stay in Control
A connected dApp can **never** move funds silently. Every `znn_sign` and `znn_send` request opens an approval dialog inside Syrius so you can **Approve** or **Decline**. For `znn_send`, Syrius displays the recipient, amount, token, source address, and network—plus the decoded method and arguments for recognized embedded contract calls; unrecognized or custom call data is shown only as a truncated raw hex preview, so never approve unfamiliar raw data you do not trust.
:::

---

## Connecting Syrius to a dApp

Open **Settings → Apps** to manage dApp connections. You can pair with a dApp in several convenient ways:

### Method 1: Connect by Link (Paste URI)

1. In the dApp in your web browser, click **Connect Wallet** and choose **WalletConnect**.
2. Copy the WalletConnect link (`wc:...`) from the dApp's modal.
3. In Syrius, open **Settings → Apps** and click **Connect by link**.
4. Paste the `wc:...` URI (or click the paste icon) and click **Connect**.
5. Review the dApp's name, URL, and requested permissions in the confirmation prompt, then click **Approve**.

### Method 2: Clipboard Watcher (Automatic Detection)

If you frequently connect to dApps, you can let Syrius detect copied WalletConnect links automatically:

1. Open **Settings → Apps**, expand the **WalletConnect** section, and turn on **Enable clipboard watcher**.
2. Whenever you copy a `wc:...` URI from a dApp, Syrius notifies you and pre-fills the URI so you can connect in one click.

### Method 3: Deep Links & QR Scanning

- **Deep links**: On supported platforms, clicking a WalletConnect or Syrius link in your browser brings Syrius to the foreground and prompts you to connect.
- **QR scanning**: Syrius also supports camera QR scanning and an **On-screen QR Scanner** (scanning a QR code displayed on your desktop screen requires granting **Screen Recording** permission on macOS).

### Local Web Apps Setting

Under **Settings → Apps**, you will also find the **Web apps** toggle (`127.0.0.1:35996`) for local browser bridge integrations when enabled. Leave this off unless you specifically use a local web app that requires it.

---

## Reviewing & Approving Requests Safely

Whenever a connected dApp asks Syrius to sign a message or send a transaction:

1. **Check the dApp identity**: Confirm the site name and domain match the dApp you actually have open.
2. **Verify the request type**:
   - For **`znn_sign`**: Read the message text carefully to ensure you intend to sign it.
   - For **`znn_send`**: Double-check the recipient address, token standard (`zts1...`), amount, and contract action.
3. **Approve or Decline**: Click **Approve** only if everything matches your intent; otherwise click **Decline**.
   - **Ledger users**: After approving in Syrius, confirm the action physically on your Ledger device screen.

:::danger Watch Out for Phishing dApps
- Bookmark trusted Zenon dApps instead of clicking links from search ads or DMs.
- Never approve unexpected transaction prompts that pop up when you did not just initiate an action in the dApp.
- Remember that no legitimate dApp will **ever** ask you to type your seed phrase or Seed Vault Key into a webpage.
:::

---

## Managing & Disconnecting Sessions

When you finish using a dApp, it is good security hygiene to disconnect active sessions:

1. Open **Settings → Apps**.
2. Under **Connected**, review all active WalletConnect sessions along with their expiry times.
3. Click **Disconnect** next to any session you no longer need.
4. Expand the **WalletConnect** section below to view stored **pairings** and click **Delete** to remove old pairings.
