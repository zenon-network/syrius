---
sidebar_position: 2
title: Troubleshooting & FAQ
description: Practical answers and troubleshooting steps for Syrius node sync issues, pending transactions, Plasma and PoW, Ledger detection, logs, and migrating to a new computer.
---

# Troubleshooting & FAQ

Having trouble with Syrius? Find quick fixes for the most common issues below.

:::danger Protect Yourself While Asking for Help
When asking for help in community channels ([Zenon Forum](https://forum.zenon.org), [Discord](https://discord.gg/zenonnetwork), or [Telegram](https://t.me/zenonnetwork)), **never share your seed phrase, Seed Vault file, Seed Vault Key, or wallet password** — even with someone claiming to be an admin or developer.
:::

---

## Node Connection & Sync Issues

### My Embedded Node is stuck syncing or taking a long time

- **Initial sync is naturally slow**: Syncing a full `go-zenon` node from scratch can take **several hours — up to 24 hours**. Keep Syrius open and your computer connected to power and internet.
- **Need to transact right away?** Open **Settings → Node** and click **Connect** on a **Community Node** to send and receive immediately while you wait.
- **Check the bottom status strip**: Look at the sync dot and **Momentum** height. If the height is increasing steadily, your node is syncing normally.

### "Node is X momentums behind" banner on the Send screen

Syrius pauses sending when your connected node is more than 2 momentums behind the network so your transaction is not rejected. Wait a few seconds for the node to catch up, or switch to another synced node under **Settings → Node**.

### "Connection could not be established" or "Node is not synced"

1. Confirm your internet connection is active and your firewall/VPN is not blocking WebSocket traffic on port `35998`.
2. In **Settings → Node**, try connecting to a different **Community Node**.
3. If connecting to a custom node, verify the URL includes both protocol (`wss://` or `ws://`) and port (typically `:35998`).
4. Check for a **Chain identifier mismatch** warning — Network of Momentum Alphanet uses Chain ID **`1`**.

---

## Transactions & Balances

### My incoming transaction is "Pending" and not in my balance

On Network of Momentum, incoming funds require a **receive block** before they become spendable:

1. Confirm your node is fully synced (green indicator in the bottom status strip).
2. Open **Settings → Wallet** and make sure **Auto-receiver** is turned **On**.
3. If **Auto-receiver** is turned off (or you use a Ledger hardware wallet), open the **Transfer** tab, look in the **To Receive** card (or the **Pending** card on Dashboard), and click the transaction to receive it manually.
4. Wait a few moments if your address has no fused QSR Plasma — Syrius may be computing Proof-of-Work in the background to publish the receive block.

### I restored my wallet, but my balance shows `0` or an address is missing

1. Confirm your node is **fully synced** (unsynced nodes cannot display recent balances).
2. If you previously used multiple derived addresses (`Address 2`, `Address 3`, etc.), open **Settings → Addresses** and click **Add address** repeatedly until all of your previous addresses are re-derived.
3. Double-check that you restored the exact 12- or 24-word seed phrase (and word count) for that wallet.

### Reward collection succeeded, why hasn't my balance updated yet?

Collecting Staking, Pillar, or Sentinel rewards creates a claim block that takes **at least 30 seconds** to settle and generate the incoming reward block. Wait ~30–60 seconds and press `Ctrl+R` (or click refresh) to see the updated balance.

---

## Plasma & Proof-of-Work

### Transactions feel slow or fail with "More Plasma is required"

- **Slow everyday transfers**: Without fused QSR, Syrius falls back to CPU Proof-of-Work (limited to 1 transaction per 10-second momentum). Fuse at least **10 QSR** (or **90–120+ QSR** for frequent use) under the **Plasma** tab to make transfers instant and feeless.
- **Complex operations failing**: Registering a Pillar or Sentinel (`252,000` Plasma), issuing a ZTS token (`189,000` Plasma), staking (`105,000` Plasma), or delegating (`84,000` Plasma) work best with **High Plasma** (**120+ QSR** fused). See [Plasma & Feeless Transactions](../core-features/plasma-and-feeless-tx.md).

### Can I get my fused QSR back?

Yes! Fused QSR is never spent or burned. After **10 hours**, open the **Plasma** tab, locate your entry in the **Fused** table, and click **Cancel** (or select multiple entries to cancel together).

---

## Hardware Wallets & P2P Swaps

### My Ledger is not detected on Linux

Linux requires Ledger `udev` rules and `plugdev` group membership before Syrius can communicate with the device over USB HID. Follow the exact commands in [Ledger Hardware Wallet — Linux udev Setup](../hardware-and-nodes/ledger-hardware-wallet.md#linux-udev-rules-setup), then **log out and log back in** and reconnect your USB cable. Also ensure **Ledger Live is closed** and the **Zenon** app is open on your Ledger.

### "Local time discrepancy detected" in P2P Swaps

P2P HTLC swaps rely on accurate timestamps to enforce expiration safety margins. Enable automatic network time sync (NTP) in your operating system's Date & Time settings before starting or joining a P2P swap.

### How do I reclaim an expired P2P Swap if I lost access to my original computer?

Restore your wallet using your seed phrase on a new machine, open **P2P Swaps**, click the **`...`** menu in the swaps header, select **Reclaim deposit**, and paste your **Deposit ID** (recoverable from a block explorer if needed).

---

## Cache, Resetting, Logs & Migrating Computers

### How do I clear corrupted cache without deleting my wallet?

Go to **Settings → Wallet → Delete cache → Delete**.

- **Safe for your funds**: Deleting the cache clears local app cache files (labels, cached nodes, notifications, preferences) and closes Syrius, while **keeping your encrypted wallet keystore intact**.
- Note that custom address labels, saved contacts, and custom node URLs will need to be re-entered afterward.

### I forgot my Syrius wallet password

Because Syrius is non-custodial, passwords cannot be recovered or reset by email.

- If you have your **12- or 24-word seed phrase** (or **Seed Vault + Seed Vault Key**), you can reset the local wallet (**Forgot the password** on the lock screen or **Settings → Security → Remove wallet**) and [re-import your wallet](../getting-started/create-or-restore-wallet.md#option-2-import-or-restore-an-existing-wallet) with a new password.

:::warning Wait Before Erasing
Never erase your wallet unless you have physically verified that you possess the correct seed phrase or Seed Vault + Key!

Resetting also deletes local P2P swap records (`htlc_swaps.sqlite`) without checking for active swaps, and Syrius does not recreate active swap records from chain blocks afterward. Finish or reclaim every active P2P swap before resetting so automatic unlocking is not interrupted.
:::

### Where do I find Syrius log files for bug reports?

Syrius writes diagnostic logs to:

- **macOS**: `~/Library/znn/syrius/log/syrius-<timestamp>.log`
- **Windows**: `%APPDATA%\znn\syrius\log\syrius-<timestamp>.log`
- **Linux**: `~/.znn/syrius/log/syrius-<timestamp>.log`

You can also jump directly to your cache folder via **Settings → About → This computer → Syrius cache path**. Review log files before posting them publicly to ensure you are comfortable with any addresses or local paths shown (logs never contain your seed phrase or password).

### How do I migrate Syrius to a new computer?

1. **Before switching**, verify you have your **12- or 24-word seed phrase** (and optionally export a **Seed Vault** under **Settings → Security → Backup**).
2. Make sure you have **no active in-progress P2P swaps** (active swaps must finish on the machine where they were started).
3. Install and checksum-verify Syrius on your new computer ([Installation Guide](../getting-started/installation.md)).
4. Choose **Import wallet** (or **Hardware wallet** for Ledger) on the new machine and enter your seed phrase or Seed Vault file.
5. Re-derive any additional addresses you used under **Settings → Addresses → Add address**.
6. Once you confirm all balances and addresses appear properly on the new machine, you can safely remove Syrius from the old machine via **Settings → Security → Remove wallet**.

---

## Frequently Asked Questions

**Are Zenon transactions really feeless?**
Yes. Instead of paying gas fees, addresses use **Plasma** generated by temporarily fusing QSR (minimum 10 QSR, 100% refundable after 10 hours) or automatic local Proof-of-Work.

**Does Syrius have a mobile app?**
Syrius (`zenon-network/syrius`) is a desktop wallet built for **macOS**, **Windows**, and **Linux**.

**Do I lose my ZNN if I delegate to a Pillar?**
No. Delegation is non-custodial and does not lock your ZNN. Your coins remain in your own address, and you can spend them or undelegate at any time without penalty.

**What happens to the QSR I use for a Pillar vs. a Sentinel?**
- **Pillar**: Deposited QSR (starting at 150,000 QSR) is **permanently burned** when you register the Pillar (your 15,000 ZNN collateral is locked and returned if you disassemble).
- **Sentinel**: Both the **5,000 ZNN** and **50,000 QSR** are **locked** as collateral and returned when you disassemble the Sentinel. (Note: an address that previously revoked a Sentinel cannot register a new Sentinel again.)

**Where can I report a bug or check for updates?**
Check for new releases under **Settings → About → Check update** or visit [github.com/zenon-network/syrius/issues](https://github.com/zenon-network/syrius/issues) to report bugs.
