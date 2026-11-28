---
sidebar_position: 1
title: Node Modes (Embedded, Local & Remote)
description: Compare Syrius's three node modes — Embedded Node, Local Node, and Remote/Community Nodes — learn what to expect during initial sync, and switch nodes safely.
---

# Node Modes

Syrius connects to Network of Momentum through a Zenon full node. Depending on whether you prioritize maximum privacy or instant setup, you can choose between **three node modes** at any time.

## Comparing the Three Modes

| Mode | How It Works | Setup Time | Privacy & Trust | Best For |
| --- | --- | --- | --- | --- |
| **Embedded Node** *(Default)* | Runs a full `go-zenon` node bundled directly inside Syrius (`ws://127.0.0.1:35998`). | Initial sync takes **several hours (up to 24 hours)** | **Highest** — validates every block locally on your machine | Users who want maximum sovereignty and privacy with zero extra software |
| **Local Node** | Connects to a standalone `go-zenon` (`znnd`) full node you already run on `ws://127.0.0.1:35998` or your local network. | Instant (once your standalone node is synced) | **Highest** — you control the full node | Power users running an always-on full node, Pillar, or Sentinel |
| **Remote / Community Nodes** | Connects over WebSockets (`wss://` or `ws://`) to a public third-party Zenon RPC node. | **Immediate** — ready in seconds | **Medium** — the remote node sees your IP address and balance queries (it can **never** access your private keys or move funds) | New users who want to send/receive right away or laptops with limited storage |

:::info Your Private Keys Never Leave Syrius
Even when connected to a Remote or Community Node, **all transaction signing happens locally inside Syrius (or on your Ledger)**. A remote node cannot spend your funds or read your seed phrase — it only relays signed transactions and serves blockchain data.
:::

---

## Embedded Node: What to Expect

By default, Syrius launches its built-in **Embedded Node** (`go-zenon`) on `ws://127.0.0.1:35998`.

- **Initial Sync Time**: Syncing from genesis can take **several hours — up to 24 hours** depending on your internet speed and disk performance.
- **No Sending or Receiving While Syncing**: Until your node catches up to the network frontier, you cannot broadcast transactions or receive incoming blocks. Watch the bottom status strip in Syrius for the green sync indicator and current **Momentum** height.
- **Wakelock While Running**: Syrius keeps your computer awake while the Embedded Node is running so syncing is not interrupted by sleep mode.
- **Clean Shutdown**: When you close Syrius while running the Embedded Node, give the app a moment to stop the node cleanly before shutting down your computer.
- **Disk Usage & Location**: Embedded node blockchain data is stored inside your Zenon main data folder (`~/Library/znn` on macOS, `%APPDATA%\znn` on Windows, `~/.znn` on Linux). You can open this folder directly from **Settings → Node → Embedded node → Data**.

:::tip Want to Get Started Immediately?
If you don't want to wait for the Embedded Node's initial sync, switch temporarily to a **Community Node** under **Settings → Node**. You can always switch back to the Embedded Node later when you have time to let it sync overnight.
:::

---

## Switching Nodes in Settings

You can view your current connection, momentum height, and switch nodes at any time:

1. Open **Settings → Node** (or click the node status indicator in the bottom status strip).
2. In the **Nodes** card, review the available options:
   - **Embedded node** (`ws://127.0.0.1:35998`)
   - **Localhost** (`ws://127.0.0.1:35998` — for an external standalone local node)
   - **Community Nodes** (preloaded in official Syrius releases from the Zenon community node database)
   - Any custom nodes you have added
3. Click **Connect** beside the node you want to use.
4. Once connected, the row displays a green **Connected** badge and Syrius refreshes your balances and transactions from that node.

### Adding a Custom Remote or Local Node

1. In **Settings → Node**, click **Add node**.
2. Enter the node's WebSocket URL **including the protocol and port**, for example:
   - Encrypted remote node (recommended): `wss://my-node.zenon.org:35998`
   - Local network node: `ws://192.168.1.50:35998`
   - Standalone local node on default port: `ws://127.0.0.1:35998`
3. Click **Add node**, then click **Connect** on the newly added entry.
4. To remove a custom node later, click its trash (**Delete**) icon.

:::tip Prefer `wss://` (Encrypted Connection) for Remote Nodes
When connecting to a remote node over the internet, prefer an encrypted **`wss://`** endpoint over unencrypted `ws://` so traffic between Syrius and the node is TLS-encrypted in transit.
:::

---

## Chain Identifier & Advanced Node Info

Inside **Settings → Node**, you will also find three collapsible advanced cards:

- **Chain identifier**: Protects your transactions against cross-network replay attacks. The default for Network of Momentum Alphanet (mainnet) is **`1`** (Testnet uses `3`).
- **Peers**: Displays the IP addresses and public keys of network peers connected to your active node.
- **Sporks**: Controls visibility of protocol spork tools (`Auto`, `On`, `Off`) — most everyday users can leave this on `Auto`.

:::warning Chain Identifier Mismatch Warnings
If you attempt to connect to a node whose chain identifier does not match your wallet's client chain identifier, Syrius displays a **Chain identifier mismatch** warning. Unless you intentionally switched to a testnet or local devnet, cancel the connection and verify the node URL.
:::
