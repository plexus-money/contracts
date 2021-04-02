---
title: Plexus - Optimism Integration
author: terminator0x 
created: 2021-04-02
---

## Summary

This spec is a detailed write-up of how to get Plexus eco-system contracts working with the Optimistic Ethereum (OE) is a Layer 2 scaling solution.

## Overview

Optimistic Ethereum (OE) is a Layer 2 scaling protocol for Ethereum applications. I.e., it makes transactions (txns) cheap. It's main goal is to decrease the latency, cost and congestion, currently being experienced in the Ethereum Mainnet Layer 1 (L1) because of the high volume of transactions coming from DeFi projects.

It is also the protocol that Uniswap Version 3 (UNI V3) will launch in. And so for this reason we need to make sure the Plexus contracts are able to run well in OE.

## How it works

Optimistic Ethereum (OE) enables fast transaction processing and low gas fees, by executing mainnet transactions in a modified Ethereum Virtual Machine (EVM) called the Optimism Virtual Machine (OVM).

These transactions once executed by the OVM are now send back to the Ethereum Mainnet Layer 1 (L1), where the respective nodes conduct **fraud detection** to make sure the transaction results from the OVM are correct and would have been the same if they were executed in L1. If the txn results are correct, then the L1 nodes can now add them to a block and wait for the block to be mined on network consensus.

The beauty and genius of this 2-tiered system, is that the ethereum mainnet is now able to offload most of it's txn processing to OE and only focus on consensus & achieving block finalit. This in turn saves time, decreases latency and congestion in L1 thereby leading to higher throughputs in the Ethereum Mainnet.

## Fraud Detection

Since OE executes contracts in a different environment from the Ethereum Mainnet, there is a need for the Ethereum Mainnet (L1) to verify that the results returned from OVM txn processing are correct and not fradulent.

This is simply done by having an OE mainnet contract that re-runs the same txn for which a result has been returned, but in sandbox mode. If the mainnet result is the same as the OE result, then the txn is of course verified as correct and if not, it is dropped and not added to the fcurrent block.


# Plexus Integration

Since Plexus already works as intended in the Ethereum Mainnet, then there is literally nothing that needs to be changed for it to work with OE. All we need to do is simplyy deploy the contracts as they are to both the Ethereum mainnet and OE, and we should be good to go.

However it's also highly recommended we first test this by doing the following using **hardhat**,

## Step 1: Compiling the contracts

### Compiling an Ethereum contract

Just like with any other project, we'll first need to compile the Plexus Solidity code into EVM bytecode, but running the following command.

```sh
npx hardhat compile
```

We should now see a new folder, `artifacts`, which has some JSON files in it.
If you can see this folder you're ready to move onto the next section!

### Compiling an Optimistic Ethereum contract

Compiling the Plexus contracts for Optimistic Ethereum is pretty easy!
First we'll need to install the `@eth-optimism/plugins` package:

```sh
yarn add --dev @eth-optimism/plugins
```

Next we just need to add this line to `hardhat.config.js`:

```js
// hardhat.config.js

require('@eth-optimism/plugins/hardhat/compiler')
```

And we're ready to compile!
All we now have to do is add `TARGET=ovm` to the beginning of your command:

```sh
TARGET=ovm npx hardhat compile
```

We can then verify that everything went well by looking for the `artifacts-ovm` and `cache-ovm` directories.

Here, `artifacts-ovm` signifies that the contracts contained in this directory have been compiled for the OVM, the **O**ptimistic **V**irtual **M**achine, as opposed to the Ethereum Virtual Machine.
Now let's move on to testing!

## Step 2: Testing the contracts

### Testing on Ethereum

Since we already have tests written for Plexus using hardhat, we'll simply run the command below to test

```sh
yarn test
```

If everything is going as planned, a bunch of green checkmarks will show at the end of the test cycle.

### Testing on Optimistic Ethereum 

First we'll need to get a local version of an Optimistic Ethereum node running...

---

Fortunately, OE have a [repository](https://github.com/ethereum-optimism/optimism-integration) that makes it easy to spin up a local Optimistic Ethereum node!

Since we're going to be using Docker, we need to make sure that Docker is installed prior to moving on to the next step(s) (info on how to do that [here](https://docs.docker.com/engine/install/)).

Now we just need to install our Optimistic Ethereum node by running:

```sh
git clone git@github.com:ethereum-optimism/optimism-integration.git --recurse-submodules
cd optimism-integration
./pull.sh
```

`./pull.sh` will pull the latest version of all of our docker images and make sure everything else is up to date.

Then we'll run the  `./up.sh` command to spin up our node:

```sh
./up.sh
```

Give `./up.sh` a little bit to fully start up (could be up to ~30 seconds).

We'll need to keep this terminal running for the rest of this test cycle since it's our Optimistic Ethereum node.

So now we can open up a second terminal so that we can run more commands while the other terminal is still running.

We now have our very own locally deployed instance of Optimistic Ethereum! 🙌

---

With our local instance of Optimistic Ethereum up and running, we can now tesst the contracts as follows!

We'll first have to add `optimism` to your list of networks within `hardhat.config.ts`:

```js
// hardhat.config.js

module.exports = {
  networks: {
    hardhat: {
      accounts: {
        ......
      }
    },
    // Add this network to our config!
    optimism: {
      url: 'http://127.0.0.1:8545',
      accounts: {
        mnemonic: 'test test test test test test test test test test test junk'
      }
    }
  },
  ...
}
```

After this, we run the command below

```sh
TARGET=ovm npx hardhat --network optimism test
```

Again we're using the `TARGET=ovm` flag to let hardhat know that we want to use the Optimistic Ethereum solidity compiler.

We also use the `--network optimism` option so that transactions are sent to our L2 node (instead of hardhat's local L1 node).

Once we run this command, we should see another set of passing tests which means we're ready to deploy the Plexus Contracts to Optimistic Ethereum.

It really is that easy.

## Step 3: Deploying the contracts

### Deploying on Ethereum Mainnet

Going through this routine one more time.

Now we're going to deploy an Ethereum contract using hardhat.

So we'll need to run:

```sh
npx hardhat deploy
```

This should do a deployment against a local (in-memory) Ethereum node.

### Deploying an Optimistic Ethereum contract

Next we'll do the same thing on Optimistic Ethereum, using the command.

```sh
TARGET=ovm npx hardhat --network optimism deploy
```

And once again we're adding `TARGET=ovm` and using the `--network optimism` option.

After a few seconds the Plexus contracts should be deployed to our local Optimistic Ethereum node and that's pretty much it!

Plexus will now be working with Optimistic Ethereum as required.


## Reference Implementation

Synthetix have been working on [fully integrating their platform with OE](https://blog.synthetix.io/why-optimism/). 

## References

1. https://community.optimism.io/docs/
2. https://optimism.io/demos

## Copyright/license

This document is licensed under the Apache License, Version 2.0 -- see [LICENSE](https://www.apache.org/licenses/LICENSE-2.0)