---
sidebar_position: 8
title: Accelerator-Z
description: Explore ecosystem proposals in Accelerator-Z, donate to the community fund, submit projects and phases, and cast Pillar votes.
---

# Accelerator-Z

**Accelerator-Z** is Zenon Network's built-in, decentralized funding engine. Builders submit open-source and ecosystem project proposals directly on-chain, and active **Pillar** operators vote on whether each project and its milestone phases receive funding from the Accelerator-Z treasury.

## Exploring the Accelerator-Z Workspace

Open the **Accelerator** tab to view:

- **Top Summary Bar**:
  - **Fund**: Current available **ZNN** and **QSR** balance held by the Accelerator-Z treasury.
  - **Voting**: Number of projects or phases currently open for Pillar votes (if your active address controls a Pillar, it highlights proposals waiting for your Pillar's vote).
  - **Donate** and **Create project** action buttons.
- **Project List & Filters**:
  - Filter by **Voting**, **Active** (accepted/paid), **Mine** (projects owned by your wallet), or **All**.
  - Pillar operators also see quick filter pills for **Needs voting** and **Already voted**.
  - Search by project ID, owner, name, description, or URL, and toggle sorting between **Newest** and **Oldest**.
- **Project Details**: Click any project row to read its full description, link to the project article, budget breakdown, voting progress bar, quorum status, and list of **Phases**.

## Donating to Accelerator-Z

Anyone can strengthen the ecosystem treasury directly from Syrius:

1. Click **Donate** in the Accelerator-Z summary bar.
2. Enter the **ZNN** and/or **QSR** amount you wish to contribute (must be greater than zero).
3. Review the donation summary and click **Submit donation**. All donated funds go directly into the Accelerator-Z on-chain fund.

---

## Submitting a Project Proposal

If you are building something for Zenon Network, you can request ZNN and/or QSR funding directly through Syrius.

### Requirements & Limits

| Parameter | Requirement / Limit |
| --- | --- |
| **Creation Fee** | **1 ZNN** (consumed and sent directly into the Accelerator fund) |
| **Project Name** | Up to **30 characters** |
| **Project Description** | Up to **240 characters** |
| **Project URL** | Valid URL linking to your full proposal/article (e.g., Zenon forum post or repository) |
| **ZNN Budget Range** | **10 ZNN** minimum — **5,000 ZNN** maximum |
| **QSR Budget Range** | **100 QSR** minimum — **50,000 QSR** maximum |

### Step-by-Step Submission

1. Select the address you want to be the **project owner** (this address receives phase payouts and submits phases).
2. Click **Create project** in the Accelerator-Z tab.
3. **Project Creation**: Confirm your owner address and ensure you have at least **1 ZNN** available for the submission fee, then click **Continue**.
4. **Project Details**: Fill in your **Project name**, **Project description**, **Project URL**, and **Total project budget** (ZNN and QSR amounts), then click **Continue**.
5. **Submit Project**: Confirm that **1 ZNN** will be consumed and click **Submit**.

Once submitted, your project enters a **14-day voting window** for Pillars.

---

## Creating & Updating Project Phases

Projects do not pay out their entire budget upfront. Once a project is **Accepted**, you unlock funds incrementally by submitting **Phases** representing concrete milestones:

1. Open your accepted project from the **Mine** filter and click **Create phase**.
2. Enter the **Phase name**, **Phase description**, **Phase URL** (showcasing your deliverable, such as a GitHub PR or release), and the **Phase budget** (within your project's remaining ZNN/QSR budget).
3. Submit the phase — each phase goes through its own **14-day Pillar voting period**.
4. Once a phase passes voting, its budget is paid out automatically to your project owner address.

:::caution Updating a Phase Resets Its Votes
You can update an active phase to reflect progress or link updated deliverables, but **updating a phase resets all votes cast on that phase so far**.
:::

---

## Pillar Voting Rules

Active Pillars govern Accelerator-Z funding by voting **Yes**, **No**, or **Abstain** on each project and phase.

- **Voting Period**: **14 days** from submission.
- **Approval Requirements**: To pass, a project or phase must meet **both** conditions:
  1. **Quorum achieved**: More than **33%** of active Pillars must cast a vote (`Yes`, `No`, or `Abstain`).
  2. **Majority Yes**: There must be **more Yes votes than No votes**.
- **How to Vote as a Pillar**:
  1. Switch your active wallet address to your Pillar's owner or producer address.
  2. Open **Accelerator** and click **Needs voting** to list open items.
  3. Open any project or phase and choose **Yes**, **No**, or **Abstain** under **Vote as [Your Pillar Name]**.
