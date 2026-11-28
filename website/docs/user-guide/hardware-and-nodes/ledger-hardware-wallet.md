---
sidebar_position: 2
title: Ledger Hardware Wallet
description: Set up and use a Ledger hardware wallet with Syrius on macOS, Windows, and Linux, including step-by-step Linux udev rules configuration.
---

# Ledger Hardware Wallet

Using a **Ledger** hardware wallet with Syrius keeps your recovery phrase and private keys completely offline inside the device's secure element. Every address check and outgoing transaction must be physically reviewed and approved on your Ledger screen.

:::info Supported Platforms & Connection
Syrius communicates with Ledger devices directly over **USB** on **macOS**, **Windows**, and **Linux**. Bluetooth is not used on desktop.
:::

## Prerequisites

Before connecting your Ledger to Syrius:

1. Initialize your Ledger device and safely back up its 24-word recovery phrase offline (following Ledger's official setup instructions).
2. Update your Ledger firmware using **Ledger Live**.
3. Install the **Zenon** app onto your Ledger device via **Ledger Live** (if it does not appear in the standard catalog, enable **Developer mode** in Ledger Live under **Settings → Experimental features**).
4. **Close Ledger Live completely** before opening Syrius so both apps do not compete for the same USB HID connection.

---

## Linux `udev` Rules Setup

On **Linux**, unprivileged user accounts cannot access USB HID devices until you install Ledger's `udev` rules and add your user to the `plugdev` group. (macOS and Windows users can skip directly to [Connecting Your Ledger to Syrius](#connecting-your-ledger-to-syrius).)

1. Download the official Ledger `20-hw1.rules` file (also bundled in the Syrius repository under `udev/20-hw1.rules`):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/zenon-network/syrius/master/udev/20-hw1.rules -o 20-hw1.rules
   ```
   *(If you cloned the Syrius repository locally, you can copy directly from `udev/*.rules`.)*
2. Install the rules, reload `udev`, and add your account to the `plugdev` group:
   ```bash
   sudo cp 20-hw1.rules /etc/udev/rules.d/ && \
   sudo udevadm trigger && \
   sudo udevadm control --reload-rules && \
   sudo groupadd -f plugdev && \
   sudo usermod -aG plugdev "$(whoami)"
   ```
3. **Log out and log back in** (or reboot your Linux machine) so the new `plugdev` group membership takes effect.
4. Unplug your Ledger USB cable and plug it back in.

:::tip Why `groupadd -f`?
Some Linux distributions already have a `plugdev` group, while others do not. Adding `-f` ensures the command succeeds cleanly even if `plugdev` already exists.
:::

---

## Connecting Your Ledger to Syrius

### First-Time Setup

1. Plug your Ledger into your computer with a **data-capable USB cable** (avoid charge-only cables).
2. Enter your PIN on the Ledger and open the **Zenon** app on the device.
3. Launch Syrius. On the Welcome screen, click **Hardware wallet**.
   - *(Already have a software wallet in Syrius? You can add a Ledger wallet under **Settings → Wallet → Wallets on this computer → Add a wallet**.)*
4. Click **Scan devices**.
5. Select your **Ledger** device from the list.
6. Syrius prompts: *"Resolving address, please confirm the address on your hardware device"* for **account index `0`**.
7. Check your Ledger screen and physically approve the address confirmation.
8. Click **Continue** in Syrius, then create a strong **local Syrius password** (at least 8 characters with uppercase, lowercase, number, and symbol).
   - This password encrypts your local Ledger metadata file and swap database on this computer; your private keys remain exclusively on the Ledger.

### Unlocking Later

Whenever you reopen Syrius:

1. Enter your local Syrius password to unlock the interface and view balances/history.
2. Connect, unlock, and open the **Zenon** app on your Ledger whenever you need to sign a transaction, receive funds manually, derive a new address, or interact with contracts.

---

## Signing Transactions on Your Ledger

Whenever you send tokens, fuse Plasma, stake, delegate, or approve a WalletConnect request with a Ledger wallet:

1. Review the transaction summary in Syrius and click **Send / Confirm**.
2. Syrius displays a prompt reminding you to confirm on the Ledger.
3. Inspect the details directly on your **Ledger's physical screen** (destination address, amount, token/action) and press both buttons to approve — or reject to cancel safely.

:::warning Ledger Wallets Do Not Export Seeds in Syrius
Under **Settings → Security → Backup**, the **Show seed phrase** and **Export Seed Vault** options are intentionally unavailable for Ledger wallets because Syrius never possesses your recovery phrase. Your Ledger's own 24-word recovery sheet is your backup.
:::

---

## Ledger Troubleshooting

| Symptom | What to Check |
| --- | --- |
| **Ledger not detected when scanning** | Make sure the device is unlocked, the **Zenon** app is open on the Ledger, and **Ledger Live is closed**. Try a different USB port or data-capable USB cable. |
| **Device not detected on Linux** | Verify `/etc/udev/rules.d/20-hw1.rules` exists, confirm `groups` output includes `plugdev`, and log out/back in after adding your user to `plugdev`. |
| **Transaction fails or times out** | Check whether your Ledger screen auto-locked or exited the Zenon app. Unlock the device, reopen the Zenon app, and retry. |
| **Cannot receive incoming transactions automatically** | Because receiving requires signing a receive block on Network of Momentum, ensure your Ledger is connected with the Zenon app open when approving receives, or confirm them manually in **Pending / To Receive**. |

For more help, see [Troubleshooting & FAQ](../security-and-support/troubleshooting-and-faq.md).
