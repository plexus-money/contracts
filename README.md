## Plexus Smart Contracts

### Yield Farming Aggregator and Plexus Rewards Ecosystem

## Overview

The smart contracts included in the `/contracts` directory are solidity-based contracts which make up the Plexus Ecosystem v.0.1. These contracts all center around the `core.sol` contract. The primary user benefit of these contracts is to:

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

4. No tests. This will change in the future; however, given our 4-week solidity development timeline, the Truffle mainnet fork + Remix was leveraged to test core functionality. The plan is to write automated tests in the `tests` directory post-internal and external audits and once the initial contracts have been tied-in and work properly with the 70% completed front-end (as of the time of this writing)


## Individual Contract Overview (Ordered in a way to help best understand arhitecture)

1. Core.sol
This contract is the main point of contact will all areas of functionality. It was designed to be the contract of interface with the front-end for depositing, withdrawing, getting user balance info, and converting ETH or other ERC-20 tokens into stakable tokens or LP on various platforms.

The hope of this contract is for it to be the one contract that never changes in address, at least until version 1 or 2, as it is highly upgradable. However, many of the contracts that creates instances of (oracle, and  wrapper) can be leveraged independently to save funds on gas. The main things you really want to do with this contract is deposit, see your balance and withdraw, and all of these functions are actually carried out using the below contract instances, separately deployed. Upon deployment there is an owner (msg.sender) and this can be changed at any time. The owner has the benefit of moving any accidentally sent ETH or ERC-20 tokens. This contract however does not store any of the staked funds. Those are all controlled by Tier2 contracts (referenced later).

2. tier1Staking.sol
The tier1Staking contract is the router between the modular tier2 contracts. Each "child" tier2 contract is tied to a a specific farm (Harvest, Pickle, etc). The tier2Staking contract has an admin and an owner. The admin should be set to the core contract address, as only that contract can call the deposit and withdraw functions (onlyAdmin modifier on those functions stipulate this). This is for security purposes to prevent all kinds of mayhem if users could interact directly. `onBehalfOf` variable is commonly used and is the msg.sender of the Core.sol contract, passed to the tier1Staking. There are reenetrancy guards on all deposit and withdraw function to prevent reentrancy attacks and other kinds of economic attacks powered by flashloans.
The tier1Staking contract does not hold any funds, it just routes them. This contract can have the rewards contract set manually by the owner or the owner can specify an oracle for it to retrieve its information from that source.


3. oracle.sol
This contract is responsible for obtaining data from the tier1 and tier2 staking contracts and relaying them to the Core.sol contract, which relays balance and rewards information to the user.

4. tokenrewards.sol
This contract is responsible for calculating and distributing rewards to users based on their staking period. It is called by the tier1Staking contract when a deposit is made and a users staked balance is recorded then. Also upon withdrawal, this contract is updated to reflect that and disburse rewards.

5. wrapper.sol
This contract is pretty robust but fairly simple in use. It can convert a token into another token when there is only one element in the `address[] memory destinationTokens` array parameter of the `wrap` function, or if there are two elements, it converts the `sourceToken` into the `destinationTokens` evenly and then provides them as liquidity in the Uniswap AMM receiving LP tokens in return and remiting those tokens back to the user.

6. tier2[...].sol Files
These contracts generally do not store user funds, but act as the owner of tokens when they are sent to a third-party farm. When a user requests to withdraw their tokens, all the tokens are withdrawn from a given farm, and the users' proportion is calculated and sent, and the remainder of the funds are re-staked. The platform is designed this way for simplicity, but also becuase some farms such as Harvest.Finance do not have paramters to unstake a small amount of tokens, but only allows the unstaking of all. To keep thing constant and allow these to be easily replicated across any yield farming platform with only the requirement of a few parameter and interface changes, this design choice was made. If there are any big vulnerabilities, these are the contracts to really look out for for possible economic attacks.


## Have questions or recommendations?

Please leave an issue with any questions or suggestions.

Thank you
