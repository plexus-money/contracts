---
title: Plexus - Bancor Integration
author: terminator0x 
created: 2021-03-25
---

## Summary

This spec is a detailed write-up of the proposed Plexus integration with Bancor v2.1.

## Abstract

The single-sided liquidity provision experiment has proven to be a unique and valuable proposition for the Bancor protocol. Yet the addition of this primitive, coupled with Impermanent loss insurance has caused limitations, decreasing Bancor's ability to accept single-sided liquidity, and inhibiting growth of TVL.

To solve this, we propose a number of solutions below along with the timelines needed to implement them.

## Overview

Bancor v2.1 introduced Single-Sided Liquidity Pools (SSLP), where Liquidity Providers (LPs) can provide liquidity to a pool with by staking 1 type of token in a pool instead of multiple as was the case earlier. 

This is done by the LP either staking an ERC20 token into the SSLP and getting the pool token in return or staking $BNT into the SSLP and consquently getting $v$BNT. 

If a LP stakes an ERC20 token in 1 side of the pool, Bancor co-invests by minting & staking $BNT, equivalent in value to the amount of the ERC20 Token, into the other side of the pool.

These single-side pools, further receive Impermanent Loss (IL) protection if they are voted to be whitelisted by holders of $BNT.

## Motivation

But even with these major improvements, each single-sided pool has a limit on the amount of $BNT that can be provided by the Bancor protocol (“co-investment limit”). When this limit is reached, $BNT must be provided by users in order for the pool to expand, or DAO/governance can vote to increase the limit.
s
Also this leads to a scenario where some pools may have high IL & low trading fees, others may have low IL and high trading fees.

Plexus now aims to compliment this process, by allowing LPs from other Automated Market Makers (AMMs) i.e. uniswap to port their LP tokens from these AMMs to Bancor via Plexus through the following solutions.

### Proposed Solutions 

#### LP swaps

Currently Bancor has some of the most competitive yield opportunities for AMMs on the market. 

This can be scaled if LPs of other AMMs are able to frictionlessly port their liquidity to Bancor pools. For this to occur, we have created a LP Migrator, which will be able to port liquidity to Bancor, from Uniswap, Sushiswap, and Balancer. 

We will create a plugin so users don't have to leave the Bancor App to Swap Liquidity. 

Our solution will work as follows

1. We query the single sided pool to see the space available for $BNT LPs i.e.

```
  IBancorLiquidityProtection bancorLiquidityProtection = IBancorLiquidityProtection(bancorLiquidityProtectionAddress);
  address poolAnchor = IBancorV2Converter(converterAddress).anchor();
  uint256 spaceAvailable = bancorLiquidityProtection.baseTokenAvailableSpace(poolAnchor);
  
```
2. If there is space available, we prompt user to stake the respective ERC20 token i.e. $LINK into the SSLP and if they agree, we do the following,
    - User's liquidity is withdrawn from original LP pool i.e. uniswap
    - User's liquidity is converted to ETH 
    - User's ETH is converted to the ERC20 Token i.e. $LINK
    - The ERC20 Token is then deposited and staked into the SSLP in Bancor for the user
    - The pool token minted i.e $LINKBNT is then sent to the users wallet.
    - The plugin will also show them their IL protection so far after the first 30days

3. If there is no space available, we prompt user to stake $BNT into the pool and if they agree, we do the following,
    - User's liquidity is withdrawn from original LP pool 
    - User's liquidity is converted to ETH 
    - User's ETH is converted to $BNT
    - $BNT is then deposited and staked into the SSLP in Bancor 
    - The $vBNT minted is then sent to the users wallet.

**Time Estimate** 2 weeks.
**Status** Partially Done.

#### Incentivize $BNT staking 

Users will incentivized to do Liquidity Mining (LM) through Plexus in Bancor, whereby users will be shown how to earn $BNT staking rewards by porting liquidity from other AMMs, while earning extra Yield with the Plexus Token (PLX) rewards.

Users will also be shown the $BNT liquidity mining rewards that Bancor governance has approved for the various pools and how they compare to the rewards offered by other AMMs for staking $BNT.

Plexus will also show users their decreasing cost for subsequent stakes, since the cost of the pool rebalance will be subsidized by a pool fee, which will save users more money, while increasing their earning potential.

**Time Estimate** 3 weeks.
**Status** Not Done.

#### Repurpose IL insurance solution 

Impermanent loss insurance is a very attractive primitive, and unique value-add for Bancor LP’s. 

We plan to repurpose this on Plexus by: 

1. Showing stakers their IL coverage as compared to staking on other AMMs

2. Allow $BNT holders to provide IL insurance for whitelisted pools. If this can be adopted, a pool can be created that solely provides IL insurance for users, and in return, the stakers earn LM rewards, and a portion of the sponsored pool’s fees.

**Time Estimate** 3 weeks.
**Status** Not Done.

#### Staking $vBNT

We will also make a designated yield farm in Plexus that maximizes users $BNT staking by re-staking their $vBNT and automatically harvesting the rewards, similar to CRV yield farming with Yearn

**Time Estimate** 4 weeks.
**Status** Not Done.

#### Leveraged staking $BNT 

$BNT stakers receive $vBNT in return for staking. Since $vBNT can be staked in a pool paired with $BNT, it has value. Users will be able to exchange their $vBNT value for $BNT and essentially leverage their staked $BNT positions.

Plexus will automate this process and UX to allow user to compound their staked $BNT with 1 click

Plexus will show the increased compounded APY, based on the users initial $BNT principle i.e. if a user deposits 100 $BNT and the current yield is 100% APY and they leverage 1.5x we will show the APY as 150% (since they will be earning 15 $BNT but only staked 10 $BNT originally).

**Time Estimate** 4 weeks.
**Status** Not Done.


## Reference Implementation

For LP Swaps, a [contract](https://github.com/plexus-money/contracts/blob/master/contracts/LP2LP.sol) `LP2LP.sol` has already been developed and deployed implementing the swap functionality.

## References

1. https://docs.bancor.network/
2. https://blog.bancor.network/bancor-v2-1-staking-for-defi-dummies-f104a6a8281e

## Copyright/license

This document is licensed under the Apache License, Version 2.0 -- see [LICENSE](https://www.apache.org/licenses/LICENSE-2.0)



