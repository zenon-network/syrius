# P2P Swaps in Syrius

The P2P Swap feature in Syrius offers users an easy and censorship resistant way of exchanging value, peer-to-peer, without intermediaries on Network of Momentum. With no fees, users can trade any ZTS token with any counterparty.

P2P Swaps use HTLCs to facilitate the swaps.

## Conducting a P2P Swap in Syrius
P2P Swaps have two parties, the starting party and the joining party. The two parties will first have to find each other (in a chatroom for example) and agree upon the amounts they want to swap. After this, they can use Syrius to conduct a trustless swap with no fees directly with each other.

### Example

Alice is the starting party for the swap and she wants to swap 100 ZNN for 1,000 QSR. Bob is the joining party and has agreed to be Alice's counterparty for the swap. Bob has provided Alice with his NoM address.

1. Alice starts a P2P swap in Syrius and deposits 100 ZNN for Bob. She then sends her deposit's ID to Bob via a messaging service (e.g. Telegram).
2. Bob uses the deposit ID to get the swap's details in Syrius and he can see that Alice has deposited 100 ZNN for him.
3. Bob joins the swap by depositing 1,000 QSR for Alice.
4. Alice sees that Bob has deposited the QSR and proceeds to complete the swap. Once Alice completes the swap, she receives 1,000 QSR.
5. Bob's Syrius sees that Alice has completed the swap and Syrius automatically proceeds to unlock the 100 ZNN For Bob.
6. The swap has now been successfuly completed.

The deposits are timelocked, so if either party backs out of the swap before it is completed, both parties can reclaim their deposits.

## Technical overview

The P2P swaps use the embedded HTLC contract to facilitate the swaps with HTLCs. A swap requires two HTLCs - the initial HTLC and the counter HTLC.

The following constants are used for HTLC based P2P swaps in Syrius:

```
kInitialHtlcDuration = Duration(hours: 8)
kCounterHtlcDuration = Duration(hours: 1)
kMaxAllowedInitialHtlcDuration = Duration(hours: 24)
kMinSafeTimeToFindPreimage = Duration(hours: 6)
kMinSafeTimeToCompleteSwap = Duration(minutes: 10)
```

### Starting the swap

When the starting party starts a swap in Syrius, depositing 100 ZNN, an HTLC is created with the following inputs:

```
hashLocked: ${joiningPartyAddress}
expirationTime: ${frontierMomentumTime} + ${kInitialHtlcDuration}
tokenStandard: zts1znnxxxxxxxxxxxxx9z4ulx
amount: 100000000000
hashType: 0
keyMaxSize: 255
hashLock: [A 32-byte hash of a preimage generated by Syrius]
```
The initial HTLC's expiration time is always set to 8 hours into the future. The preimage is stored into an encrypted database locally. Syrius hashes the preimage with the SHA3-256 hash function, so the `hashType` parameter is set to `0`.

### Joining the swap
The joining party has 1 hour to join the swap. The `kMinSafeTimeToFindPreimage` ensures that the joining party will have at least 6 hours to find the swap's preimage. Since the `kCounterHtlcDuration` makes sure that the counter HTLC's duration is 1 hour, the user cannot join the swap if the initial HTLC's time until expiration is less than the combined duration of `kMinSafeTimeToFindPreimage` and `kCounterHtlcDuration`.

Syrius will not allow the user to join a swap if the initial HTLC's duration exceeds the `kMaxAllowedInitialHtlcDuration` constant.

When the joining party joins the swap, depositing 1,000 QSR, an HTLC is created with the following inputs:
```
hashLocked: ${startingPartyAddress}
expirationTime: ${frontierMomentumTime} + ${kCounterHtlcDuration}
tokenStandard: zts1qsrxxxxxxxxxxxxxmrhjll
amount: 1000000000000
hashType: 0
keyMaxSize: 255
hashLock: ${initialHtlcHashlock}
```

In case the joining party does not join the swap, the starting party will have to wait until the initial HTLC expires. After the HTLC has expired, the funds can be reclaimed.

### Completing the swap
After both parties have deposited their funds, the swap can be completed.

#### The starting party

When the starting party completes the swap, the embedded HTLC contract's `Unlock` method is called with the following inputs:
```
id: ${counterHtlcId}
preimage: ${preimageFromLocalStorage}
```

The starting party has 50 minutes to complete the swap. Although the counter HTLCs duration is 1 hour, the unlock transaction sending has to be started at least 10 minutes (`kMinSafeTimeToCompleteSwap`) before the counter HTLC expires. This is to ensure that the transaction has enough time to get published and processed by the network so that the counter HTLC does not expire in between the time the user sends the transaction and the HTLC contract processes the transaction. This could lead to a situation where the preimage is published on-chain, but the starting party doesn't have access to the hashlocked funds anymore.

If the starting party does not complete the swap, both parties will have to wait for their HTLCs to expire to reclaim their funds.

#### The joining party
Once the starting party has unlocked the counter HTLC, the joining party's Syrius will actively monitor the chain to find the preimage the starting party published on chain when calling the HTLC contract's `Unlock` method.

The joining party should keep Syrius running until either the swap is completed, or the counter HTLC expires. This is to ensure that Syrius can find the preimage and unlock the funds deposited to the joining party. If Syrius is closed during this time, the joining party has at least 6 hours (`kMinSafeTimeToFindPreimage`) to reopen Syrius, so that the preimage can be found.

Once the preimage has been found, the embedded HTLC contract's `Unlock` method is automatically called by Syrius with the following inputs:

```
id: ${initialHtlcId}
preimage: ${preimageFoundOnChain}
```

### What if the joining party fails to find the preimage?
If the joining party fails to find the preimage and unlock the initial HTLC before it expires, access to the funds will be lost and the starting party will be able to reclaim the funds.

To reduce the risk of this happening, Syrius enables the computer's wakelock, so that the computer doesn't go into sleep mode while Syrius is monitoring the chain for the preimage after the joining party has joined the swap. Since the counter HTLC's duration is 1 hour, that is the maximum time that the joining party has to stay vigiliant during the swap. If Syrius is not running during this time and the starting party completes the swap, the joining party will have at least 6 hours to reopen Syrius.

[HTLC Watchtowers](https://github.com/hypercore-one/htlc-watchtower) can also be deployed by community members to further reduce the chance of users losing funds.


## The future of P2P swaps
HTLCs are the only way right now to facilitate trustless trading on Network of Momentum, but they are not necessarily the most convenient way to facilitate same chain P2P swaps. Superior ways to facilitate trading will hopefully be available in the future.

The Syrius implementation for P2P swaps has been designed in such a way, that the underlying primitives that the swaps are based upon can be changed, but the experience for the user can remain more or less the same.

While only ZTS to ZTS swaps are currently supported, HTLCs can be used to facilitate cross-chain swaps as well and supporting cross-chain swaps could be a future goal.  