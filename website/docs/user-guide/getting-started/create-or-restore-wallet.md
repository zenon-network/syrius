---
sidebar_position: 2
title: Create or Restore a Wallet
description: Step-by-step instructions for creating a new Syrius wallet, importing an existing seed phrase or Seed Vault, or connecting a Ledger hardware wallet.
---

# Create or Restore a Wallet

When you launch Syrius for the first time, you are greeted by the **Welcome** screen with three ways to access your wallet:

- **Create wallet** — Generate a brand-new 12- or 24-word recovery seed phrase.
- **Import wallet** — Restore an existing wallet from a seed phrase or an encrypted Seed Vault / keystore `.json` file.
- **Hardware wallet** — Connect a **Ledger** device so your keys remain offline on hardware.

---

## Option 1: Create a New Wallet

Creating a new wallet generates your master secret locally on your computer.

### 1. Choose Your Seed Length & Back It Up

1. Click **Create wallet** on the Welcome screen.
2. Choose between a **24-word** seed phrase (default and recommended for maximum entropy) or a **12-word** seed phrase.
3. **Write down every word in exact numbered order on paper** (or stamp it into metal). Double-check your spelling carefully.
4. *(Optional)* Click **Export Seed** to save an encrypted **Seed Vault** file (`zenon-syrius-wallet-backup-YYYY-MM-DD-HHmm.json`) protected with a **Seed Vault Key**. Store the file and the Seed Vault Key in separate offline locations.
5. Check both confirmation boxes:
   - *I have backed up my seed in a safe location*
   - *I have written down my seed*
6. Click **Continue**.

:::danger Never Store Your Seed Phrase Digitally in Plain Text
Do **not** take a screenshot, email your seed words to yourself, paste them into a cloud notes app, or share them with anyone. Anyone who obtains these words can take all funds across every address in your wallet.
:::

### 2. Confirm Your Seed Phrase

To verify that your backup is accurate, Syrius quizzes you on **3 random word positions** from your newly generated seed phrase (for example, *Word 4*, *Word 11*, *Word 19*).

1. For each prompted word position, click the matching word from the choices shown (or drag and drop it onto the row).
2. Click **Verify** to confirm your answers.
3. Once verified, click **Continue**.

### 3. Set Your Wallet Password

Your wallet password encrypts the local keystore file on your computer and is used every time you unlock Syrius.

1. Enter a strong password that meets all requirements:
   - At least **8 characters**
   - At least **1 uppercase letter**
   - At least **1 lowercase letter**
   - At least **1 number**
   - At least **1 symbol**
2. Re-enter the password in **Confirm password**.
3. Click **Continue** to encrypt and create your wallet.

:::info Password vs. Seed Phrase
- Your **wallet password** only protects the encrypted wallet file on *this computer*. You can change it later in **Settings → Security**, or reset and re-import your wallet if you forget it.
- Your **seed phrase** is the master key to your funds on the blockchain. It can **never** be recovered or reset if lost.
:::

### 4. Select Your Node & Finish

After your wallet is created, Syrius lets you choose a node connection (or starts with the default **Embedded Node**). See [Node Modes](../hardware-and-nodes/node-modes.md) to decide whether to wait for the Embedded Node to sync or switch to a Community Node right away.

---

## Option 2: Import or Restore an Existing Wallet

Use this option if you are migrating to a new computer, recovering after a wallet reset, or importing a wallet created earlier in Syrius.

### Restore from a Seed Phrase (12 or 24 Words)

1. Click **Import wallet** on the Welcome screen.
2. Select **12 words** or **24 words** at the bottom of the card to match your recovery phrase.
3. Type or paste your words separated by spaces into the seed input box. Watch the word counter (e.g., `24 of 24`) confirm all words are entered.
4. Click **Continue**.
5. Create and confirm a strong local **wallet password** for this computer.
6. Wait briefly while Syrius encrypts your keystore and initializes your wallet.

### Restore from a Seed Vault or Keystore File (`.json`)

1. Click **Import wallet** on the Welcome screen.
2. Click the file drop zone to browse for your `.json` **Seed Vault** or keystore file — or drag and drop the file directly onto it.
3. Click **Continue**.
4. Enter your **Seed Vault Key** (or original keystore password) to decrypt the file.
5. Set a local wallet password for this installation if prompted, then complete setup.

:::tip Missing Addresses After Restoring?
When you restore a wallet from a seed phrase, Syrius starts with your primary address (**Address 1**, index `0`). If you previously used multiple addresses (`Address 2`, `Address 3`, etc.), open **Settings → Addresses** and click **Add address** to re-derive them in the exact same order.
:::

---

## Option 3: Set Up with a Ledger Hardware Wallet

If you prefer hardware-backed key storage, your private keys stay inside your Ledger device and never touch your computer.

1. Connect your Ledger device via USB, unlock it with your PIN, and open the **Zenon** app on the device.
2. On the Syrius Welcome screen, click **Hardware wallet**.
3. Click **Scan devices** if your Ledger does not appear automatically.
4. Select your Ledger from the list.
5. Verify and approve the address prompt (**account index `0`**) on your Ledger's physical screen.
6. Click **Continue**, then create a local Syrius password (this password unlocks the Syrius app and protects local metadata/swap data — it does *not* replace your Ledger PIN or Ledger recovery phrase).

For OS-specific tips and Linux `udev` rules, see the full [Ledger Hardware Wallet Guide](../hardware-and-nodes/ledger-hardware-wallet.md).

---

## Adding Multiple Wallets on One Computer

Syrius lets you maintain more than one wallet file on the same computer. After unlocking a wallet, you can view existing wallet files or launch onboarding for an additional wallet under **Settings → Wallet → Wallets on this computer → Add a wallet**.

## Next Steps

- Explore your balances, addresses, and notifications in [Dashboard & Addresses](../core-features/dashboard-and-addresses.md).
- Learn how node syncing affects sending and receiving in [Node Modes](../hardware-and-nodes/node-modes.md).
