---
sidebar_position: 1
title: Installation & Verification
description: Safely download Syrius from official GitHub Releases, verify SHA-256 checksums, and install on macOS, Windows, or Linux.
---

# Installation & Verification

Before you create or restore a wallet, make sure you install an authentic copy of Syrius directly from the official Zenon Network GitHub repository.

## Step 1: Download from Official GitHub Releases

1. Open the official Syrius releases page in your browser:
   **[https://github.com/zenon-network/syrius/releases/latest](https://github.com/zenon-network/syrius/releases/latest)**
2. Confirm the URL in your browser's address bar begins with `https://github.com/zenon-network/syrius/`.
3. Under **Assets**, download the release package for your operating system **and** the `SHA256CHECKSUMS.txt` file:

| Operating System | Official Release File | Notes |
| --- | --- | --- |
| **macOS** | `syrius-alphanet-macos-universal.dmg` | Universal build supporting both Apple Silicon and Intel Macs. |
| **Windows** | `syrius-alphanet-windows-amd64.zip` | 64-bit Windows build. Requires Microsoft Visual C++ Redistributable. |
| **Linux** | `syrius-alphanet-linux-amd64.zip` | 64-bit Linux build (`x86_64`). |

:::warning Avoid Unofficial Sources
Do not download Syrius from third-party download sites, social media links, or unsolicited messages. Malicious wallet copies can steal your recovery seed phrase the moment you enter it.
:::

## Step 2: Verify the Download Checksum (Recommended)

Every official Syrius release publishes a `SHA256CHECKSUMS.txt` file so you can confirm that your downloaded archive was not corrupted or tampered with.

Open a terminal in the folder where you downloaded both the Syrius file and `SHA256CHECKSUMS.txt`, then run the command for your operating system:

### macOS

```bash
shasum -a 256 syrius-alphanet-macos-universal.dmg
cat SHA256CHECKSUMS.txt
```

Compare the output hash character-by-character against the `syrius-alphanet-macos-universal.dmg` line in `SHA256CHECKSUMS.txt`.

### Windows (PowerShell)

```powershell
Get-FileHash .\syrius-alphanet-windows-amd64.zip -Algorithm SHA256
Get-Content .\SHA256CHECKSUMS.txt
```

Compare the `Hash` value (case-insensitive) against the `syrius-alphanet-windows-amd64.zip` entry in `SHA256CHECKSUMS.txt`.

### Linux

```bash
sha256sum --ignore-missing -c SHA256CHECKSUMS.txt
```

You should see `syrius-alphanet-linux-amd64.zip: OK`.

:::danger If the Checksum Does Not Match
Delete the downloaded file immediately and do not run it. Re-download from [official GitHub Releases](https://github.com/zenon-network/syrius/releases/latest) and verify again.
:::

## Step 3: Install Syrius

### macOS

1. Double-click `syrius-alphanet-macos-universal.dmg` to mount the disk image.
2. Drag **`s y r i u s.app`** into your **Applications** folder.
3. Eject the mounted `syrius` volume.
4. Launch Syrius from **Applications**.
   - If macOS Gatekeeper warns that the app is from an unidentified developer, **Control-click** (or right-click) `s y r i u s.app` in Applications, choose **Open**, and confirm **Open** in the dialog (or allow it under **System Settings → Privacy & Security**).

### Windows

1. Install the **Microsoft Visual C++ Redistributable (x64)** if it is not already present on your PC (linked directly in the official Syrius release notes: [vc_redist.x64.exe](https://aka.ms/vs/16/release/vc_redist.x64.exe)).
2. Right-click `syrius-alphanet-windows-amd64.zip` and choose **Extract All...** to extract the folder to a permanent location (such as `C:\Users\<YourName>\Syrius\`).
3. Open the extracted folder and launch **`syrius.exe`** (or **`s y r i u s.exe`**).
   - If Windows SmartScreen displays a "Windows protected your PC" prompt, verify that your SHA-256 checksum matched in Step 2, then click **More info → Run anyway**.

:::tip Do Not Run from Inside the ZIP File
Always extract the entire Windows archive before launching Syrius. Running directly from inside the `.zip` preview breaks native libraries required for the Embedded Node, PoW Plasma generation, and Ledger support.
:::

### Linux

1. Extract `syrius-alphanet-linux-amd64.zip` into a directory of your choice:
   ```bash
   mkdir -p ~/syrius
   unzip syrius-alphanet-linux-amd64.zip -d ~/syrius
   cd ~/syrius
   ```
2. Launch Syrius from that directory (making sure the main executable has execute permissions if needed):
   ```bash
   ./syrius
   ```
3. **Using a Ledger hardware wallet on Linux?** You must install Ledger `udev` rules so unprivileged Linux accounts can access USB HID devices. Follow the step-by-step instructions in [Ledger Hardware Wallet — Linux udev Setup](../hardware-and-nodes/ledger-hardware-wallet.md#linux-udev-rules-setup).

## Upgrading Syrius Safely

Your wallet keystore files, settings, and node data are stored separately from the Syrius application folder (see [Security & Backups — Wallet File Locations](../security-and-support/security-and-backups.md#where-syrius-stores-your-files)).

To upgrade to a newer release:

1. Close Syrius completely and wait for the Embedded Node (if running) to shut down cleanly.
2. Confirm you have a verified backup of your recovery seed phrase or Seed Vault before upgrading.
3. Download, checksum-verify, and replace the application binaries with the new version.
4. Launch the new version and unlock your existing wallet with your password.

You can also check for new versions anytime inside Syrius under **Settings → About → Check update**.

## Next Step

Once Syrius opens to the Welcome screen, continue to [Create or Restore a Wallet](./create-or-restore-wallet.md).
