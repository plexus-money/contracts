## Plexus Smart Contracts

[![Node.js CI](https://github.com/plexus-money/contracts/actions/workflows/node.js.yml/badge.svg?branch=master)](https://github.com/plexus-money/contracts/actions/workflows/node.js.yml)

### Yield Farming Aggregator and Plexus Rewards Ecosystem

## Overview

The smart contracts included in the `/contracts` directory are solidity-based contracts which make up the Plexus Ecosystem v.0.1. These contracts all center around the `core.sol` contract. The primary user benefit of these contracts is to:

- Deposit ERC-20 tokens into the Plexus ecosystem, either to collect interest from Aave or to be sent to a Yield Farm. Aave is pretty low risk, which staking FARM tokens on the Harvest.Finance platform is a bit riskier.

- Earn Plexus ERC-20 token rewards from leveraging the Plexus ecosystem to deposit/stake (The token is to be created later and will be generated using Aragon as it will also serve as a governance token. However, the token itself is outside the scope of this document. A placeholder token can be used for purposes of discussion). One could simply just stake directly on Harvest.Finance or Pickle however, then the user would not be earning PLX..

- Generate commissions for the Plexus core team and wider community in exchange for the Plexus rewards when a user withdraws tokensInRewardsReserve

- Withdraw ERC-20 tokens that have been deposited into the Plexus ecosystem, generating both PLX rewards and third party staking Rewards

- Convert popular ERC-20 tokens or ETH into LP tokens to be used for staking on the Plexus platform (as an ease-of-use mechanism to onboard a wider audience might not understand how to generate LP tokens. Without Plexus (specifically the wrapper.sol contract) a user has to perform over 6 transactions between ETH and obtaining the LP token. Also, this is currently the only platform which allows users to convert LP tokens to any other ERC-20 token (DAI, WETH, USDC) with a single transaction, instead of the 3+ transactions that are usually required.

- View the average APY of various third party tokens and farms. For now, these need to be manually entered by an owner, as each third party platform demonstrates this data on their dashboards but that data is not easily obtainable directly from their smart contracts as usually there is an undefined future emissions drop that happens daily and also depends on the number of stakers, time periods, etc.

- Retrieve user staking balances within the Plexus Ecosystem.


## Important Design Decision Notes

1. Each of the 9 main contracts in the contract folder contains all of its needed interfaces and libraries in single-file format. This design decision was made for two reasons: 1) Etherscan sometimes has issues, with various compiler versions, verifying the contract code when the files are split up. When there is an issue, Etherscan can be pretty slow to fix them. To prevent this complexity, single file formats were chosen. Additionally, even when importing files, the Ethereum blockchain sees the code as having all of the content on a single file (libs, interfaces, etc). Therefore for transparency in the auditing process, all of this is included. 2) When importing interfaces there are often many functions or events from another contract that will not be used in the deployed contract, so it's more expensive generally to import the same libraries for all files. While this design decision is not as popular, the utility of it, also for security purposes (something being hidden in all the imports that is a vulnerability), outweighs the pretty style of the typical import syntax.


2. Delegate calls were not used. Instead instances of third-party contracts were used to allow the platform to be modular and containerized.

3. Most contracts within the ecosystem (wrapper.sol, tier1Staking.sol, rewards.sol) are built to work as stand-alone products. This makes testing easier and also means these features can be easily ported into other projects related to Plexus in the future very easily.

4. No tests. This will change in the future; however, given our 4-week solidity development timeline, the Truffle mainnet fork + Remix was leveraged to test core functionality. The plan is to write automated tests in the `tests` directory post-internal and external audits and once the initial contracts are integrated and functional 80% completed front-end (as of the time of  writing)


## Important Deployment Notes

- Core.sol needs its staking contract and oracle contract updated to the deployed contracts for it to work properly

- Oracle.sol needs to be updated with the "CORE" with the `updateDirectory` function in order for deposits and withdrawals to work.

- Example of a working deployment of Core connected to an oracle: https://etherscan.io/address/0x7a72b2c51670a3d77d4205c2db90f6ddb09e4303#code

- Get APR is a placeholder for now and the front-end will likely use an API to get third-party platform APYs and APRs as they are variable and not easily identifiable given their emission schedules, etc. for various platforms (often these platforms use their own APIs and not their smart contracts to determine this).

- Tier 2 contracts need to be added by the owner to the Tier 1 contract. It comes with FARM working out of the box, but for example Pickle's Tier 2 contract and info should be added by the owner to the Tier 1 contract. When new platforms are added they will be updated in the tier1Staking.sol contract. The oracle pulls its balances and other data from here.


## Individual Contract Overview (Ordered to help best understand architecture)

1. `Core.sol` (https://etherscan.io/address/0x7a72b2c51670a3d77d4205c2db90f6ddb09e4303#code)

This contract is the main point of contact with all areas of functionality. It was designed to be the contract of interface with the front-end for depositing, withdrawing, getting user balance info, and converting ETH or other ERC-20 tokens into stakeable tokens or LP on various platforms.

The hope of this contract is for it to be the one contract that never changes in address, at least until version 1 or 2, as it is highly upgradable. However, many of the contracts that create instances of (oracle, and wrapper) can be leveraged independently to save funds on gas. The main things you really want to do with this contract is deposit, see your balance and withdraw, and all of these functions are actually carried out separately deployed contract instances below. Upon deployment there is an owner (msg.sender) and this can be changed at any time. The owner has the benefit of moving any accidentally sent ETH or ERC-20 tokens. This contract however does not store any of the staked funds. Those are all controlled by Tier2 contracts (referenced later).

2. `tier1Staking.sol` (https://etherscan.io/address/0x97b00db19bAe93389ba652845150CAdc597C6B2F#code)

The tier1Staking contract is the router between the modular tier2 contracts. Each "child" tier2 contract is tied to a specific farm (Harvest, Pickle, etc). The tier2Staking contract has an admin and an owner. The admin should be set to the core contract address, as only that contract can call the deposit and withdraw functions (the onlyAdmin modifier on those functions stipulates this). This is for security purposes to prevent all kinds of mayhem if users could interact directly. `onBehalfOf` variable is commonly used and is the msg.sender of the Core.sol contract, passed to the tier1Staking. There are reentrancy guards on all deposit and withdraw functions to prevent reentrancy attacks and other kinds of economic attacks powered by flashloans. The tier1Staking contract does not hold any funds, it just routes them. This contract can have the rewards contract set manually by the owner or the owner can specify an oracle for it to retrieve its information from that source.


3. `oracle.sol` (https://etherscan.io/address/0xBDfF00110c97D0FE7Fefbb78CE254B12B9A7f41f#code)

This contract is responsible for obtaining data from the tier1 and tier2 staking contracts and relaying them to the Core.sol contract, which relays balance and rewards information to the user.

4. `tokenrewards.sol` (https://etherscan.io/address/0x2ae7b37ab144b5f8c803546b83e81ad297d8c2c4#code)

This contract is responsible for calculating and distributing rewards to users based on their staking period. It is called by the tier1Staking contract when a deposit is made and a users staked balance is recorded then. Also upon withdrawal, this contract is updated to reflect that and disburse rewards.

5. `wrapper.sol` (https://etherscan.io/address/0x95DE267b94130B1AA6Dd664247433212B9a27286#code)

This contract is pretty robust but fairly simple in use. It can convert a token into another token when there is only one element in the `address[] memory destinationTokens` array parameter of the `wrap` function, or if there are two elements, it converts the `sourceToken` into the `destinationTokens` evenly and then provides them as liquidity in the Uniswap AMM receiving LP tokens in return and remitting those tokens back to the user.

6. `tier2[...].sol` Files (FARM example: https://etherscan.io/address/0x618fDCFF3Cca243c12E6b508D9d8a6fF9018325c#code)

These contracts generally do not store user funds, but act as the owner of tokens when they are sent to a third party farm. When a user requests to withdraw their tokens, all the tokens are withdrawn from a given farm, and the users' proportion is calculated and sent, and the remainder of the funds are re-staked. The platform is designed this way for simplicity, also because some farms such as Harvest.Finance do not have parameters to unstake a small amount of tokens, only unstaking of all tokens. This design choice was made to keep things constant and is easily replicable across any yield farming platform with only the requirement of a few parameter and interface changes. If there are any big vulnerabilities, these are the contracts to really look out for in the event of economic attacks.



## Have questions or recommendations?

Please leave an issue with any questions or suggestions.

Thank you
