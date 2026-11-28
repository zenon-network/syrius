---
sidebar_position: 1
title: Security & Backups
description: Protect your Zenon assets with non-custodial best practices, offline seed phrase storage, Seed Vault and keystore backups, exact OS file paths, and anti-phishing tips.
---

# Security & Backups

Syrius is a **100% non-custodial** wallet. Your keys are generated and encrypted exclusively on your own machine (or stay inside your Ledger hardware wallet). No server, developer, or support agent has access to your wallet — which gives you complete ownership and makes good backup habits essential.

:::danger Golden Rule of Self-Custody
**If you lose both your recovery seed phrase and your encrypted backups/passwords, your funds are permanently unrecoverable.** Conversely, **anyone who obtains your seed phrase can steal all of your funds immediately** from anywhere in the world.
:::

---

## Two Ways to Back Up a Software Wallet

You can view or export backups anytime under **Settings → Security → Backup** (software wallets only):

### 1. Recovery Seed Phrase (12 or 24 Words) — Primary Backup

Your BIP-39 mnemonic seed phrase can restore your entire wallet (all derived addresses) on any computer running Syrius — even if your computer fails completely.

- **Write it on paper or stamp it into fire/water-resistant metal.**
- **Store copies in at least two physically separate, secure offline locations** (for example, a home safe and a safe-deposit box).
- **Never** photograph, screenshot, print to a networked printer, email, or store your seed phrase in cloud storage or chat apps.
- To view your seed phrase later in Syrius: go to **Settings → Security → Backup → Seed phrase → Show** (*Dump Mnemonic*) and enter your wallet password in a private setting.

### 2. Encrypted Seed Vault (`.json`) — Secondary Convenience Backup

Syrius can export your seed as an Argon2-encrypted JSON file called a **Seed Vault** (named `zenon-syrius-wallet-backup-YYYY-MM-DD-HHmm.json`), encrypted with a **Seed Vault Key** that you choose.

- Go to **Settings → Security → Backup → Seed Vault → Export**.
- Choose a strong **Seed Vault Key** and save the `.json` file to encrypted or offline storage (such as an offline USB drive).
- **Store the Seed Vault file and the Seed Vault Key in separate offline locations.** Without the Seed Vault Key, the encrypted file cannot be decrypted.

---

## Where Syrius Stores Your Files

Knowing where Syrius keeps its wallet keystores, cache, node data, and logs is essential for backing up files, migrating to a new machine, or troubleshooting.

| Operating System | Main Data & Embedded Node | Wallet Keystores | Cache, Preferences & Swap DB | Log Files |
| --- | --- | --- | --- | --- |
| **macOS** | `~/Library/znn/` | `~/Library/znn/wallet/` | `~/Library/znn/syrius/` | `~/Library/znn/syrius/log/` |
| **Windows** | `%APPDATA%\znn\` | `%APPDATA%\znn\wallet\` | `%APPDATA%\znn\syrius\` | `%APPDATA%\znn\syrius\log\` |
| **Linux** | `~/.znn/` | `~/.znn/wallet/` | `~/.znn/syrius/` | `~/.znn/syrius/log/` |

*(On Windows, `%APPDATA%` normally resolves to `C:\Users\<YourUsername>\AppData\Roaming`.)*

:::tip Open These Folders Directly from Syrius
You don't need to hunt for hidden directories manually! Open **Settings → About → This computer** to copy or open your **Zenon main data path**, **Syrius cache path**, and **Syrius wallet path** with one click.
:::

### What Each Folder Contains

- **`wallet/`**: Your Argon2-encrypted software keystore file(s) and Ledger metadata files. **Back these up — never delete unless you have a verified seed phrase backup!**
- **`syrius/`**: Local app cache files (address labels, contacts, favorite tokens, custom nodes, notifications), encrypted P2P swap database (`htlc_swaps.sqlite`), and the `log/` directory (`syrius-<timestamp>.log`).
- **Main data root (`znn/` / `.znn/`)**: Embedded Node (`go-zenon`) blockchain database (`nom/`, `consensus/`, `network/`, etc.).

---

## Built-In Wallet Security Controls

Configure your daily defense layers under **Settings → Security**:

- **Strong Wallet Password**: Syrius enforces at least **8 characters** with uppercase, lowercase, a number, and a symbol. Use a unique password not reused on any website. You can update it anytime under **Settings → Security → Password → Change** (Syrius automatically re-encrypts both your keystore and local HTLC swap database).
- **Auto-Lock Wallet**: Defaults to **15 minutes** of inactivity. Choose **`5 min`**, **`15 min`**, **`1 h`**, or **`On close`** depending on how you use your computer. Press `Ctrl+L` anytime to lock immediately.
- **Auto-Erase Wallet**: Defaults to **3** consecutive failed password attempts (configurable to **`3`**, **`5`**, **`10`**, or **`Off`**). If the limit is reached, Syrius permanently erases local wallet files to deter brute-force attacks.
- **Sign & Verify Messages**: Under **Settings → Security**, you can cryptographically **Sign a message** with your active address to prove address ownership without moving funds, or **Verify a signature** from someone else.
- **Privacy Mode (Hide Balances)**: Toggle the eye icon on the Dashboard or enable **Hide balances** under **Settings → Display** when screen-sharing or working in public.
- **Hardware Wallet Upgrade**: For large balances, consider moving funds to a [Ledger hardware wallet](../hardware-and-nodes/ledger-hardware-wallet.md).

:::warning Verify Your Backup Before Relying on Auto-Erase
If auto-erase triggers, you will need your **12- or 24-word seed phrase** (or **Seed Vault + Key**) to restore access to your funds!
:::

---

## Recognizing Scams & Phishing

Protect yourself from the most common cryptocurrency attacks:

1. **Fake "Support" DMs**: After posting a question in Telegram, Discord, or a forum, scammers often direct-message you pretending to be official Zenon or Syrius support and ask you to "validate", "sync", or "rectify" your wallet on a website. **Block and report them immediately.**
2. **Fake Wallet Downloads**: Always download Syrius solely from [github.com/zenon-network/syrius/releases/latest](https://github.com/zenon-network/syrius/releases/latest) and verify `SHA256CHECKSUMS.txt`.
3. **Address Poisoning (Lookalike Addresses)**: Never copy a destination address blindly from your transaction history — always copy from a trusted source or saved contact, and pay attention if Syrius warns *"Looks like [Contact], but is not"*.
4. **Malicious Zap Messages & Fake Tokens**: Ignore unsolicited links embedded in incoming Zap messages, and verify exact `zts1...` token standards before accepting or swapping ZTS tokens.
5. **Suspicious WalletConnect Prompts**: Never approve a `znn_send` or `znn_sign` dialog you did not actively initiate yourself.
