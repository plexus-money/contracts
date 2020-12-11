## Plexus Smart Contracts

### Yield Farming Aggregator and Plexus Rewards Ecosystem

## Overview

The smart contracts included the `/contracts` directory are solidity-based contracts which make up the Plexus Ecosystem v.0.1. These contracts all center around the `core.sol` contract. The primary user benefit of these contracts is to:

- Deposit ERC-20 tokens into the Plexus ecosystem, either to collect interest from Aave or to be sent to a Yield Farm. Aave is pretty low risk, which staking FARM tokens on the Harvest.Finance platform is a bit riskier.

- Earn Plex ERC-20 Token Rewards from leveraging the Plexus ecosystem to deposit/stake (The token is to be created later and will be generated using Aragon as it will also serve as a governance token. However, the token itself is outside the scope. A Placeholder token can be used for examples). One could simply just stake directly on Harvest.Finance or Pickle; however, then the user would not earn PLEX as well.

- Generate commissions for the Plexus core team and wider community in exchange for the Plexus rewards when a user withdraws tokensInRewardsReserve

- Withdraw ERC-20 tokens that have been deposited into the Plexus ecosystem, generating both Plex rewards and 3rd party staking Rewards

- Convert popular ERC-20 tokens or ETH into Uniswap LP tokens to be used for staking on the Plexus platform (as an ease-of-use mechanism to onboard a wider audience might not understand how to generate LP tokens. Previously, before these contracts (specifically the wrapper.sol contract)) a user had to perform over 6 transactions between ETH and obtaining and LP token. Also, this is currently the only platform which allows users to convert LP tokens to any other ERC-20 token (DAI, WETH, USDC) with a single transaction, instead of the 3+ transactions that is usually required.

- View the Average APY of various third-party tokens and farms. For now, these need to be manually entered by an owner as each third-party platform demonstrates this data on their dashboards but that data is not easily obtainable directly from their smart contracts as usually there is an undefined future emmissions drop that happens daily and also depends on the number of stakers, time periods, etc.

- Retrieve user staking balances within the Plexus Ecosystem


## Important Design Decision Notes

1. Each contract in the contract folder contains all interfaces and libraries on a single file. This design decision was made for 2 reasons: 1) Etherscan sometimes has issues with various compiler versions verifying the contract code when the files are split up. Etherscan, when there is an issue, can be pretty slow to fix these issues, and to prevent this complexity, single file formats were chosen. Additionally, even when importing files, the Ethereum chain sees the code the same as having all of the content on a single file (libs, interfaces, etc), therefore for transparency for audits all of this is included. Further, when importing interfaces there are often many functions or events from another contract that will not be used in the deployed contract, so it's more expensive generally to import the same libraries for all files. While this design decision is not as popular, the utility of it, also for security purposes (something being hidden in all the imports that is a vulnerability), outweighs the pretty style of the typical import syntax.


2. Delegate calls were not used. Instead instances of third-part contracts are used to make the platform more modular and containerized.

3. Most contracts within the ecosystem (wrapper.sol, tier1Staking.sol, rewards.sol) are built to work as stand-alone products. This makes testing easier and also means these features can be easily ported into other projects related to Plexus in the future very easily.
