## Plexus Smart Contracts

### Yield Farming Aggregator and Plexus Rewards Ecosystem

## Overview

The smart contracts included the `/contracts` directory are solidity-based contracts which make up the Plexus Ecosystem v.0.1. These contracts all center around the `core.sol` contract. The primary user benefit of these contracts is to:

- Deposit ERC-20 tokens into the Plexus ecosystem, either to collect interest from Aave or to be sent to a Yield Farm. Aave is pretty low risk, which staking FARM tokens on the Harvest.Finance platform is a bit riskier.

- Earn Plex ERC-20 Token Rewards from leveraging the Plexus ecosystem to deposit/stake (The token is to be created later and will be generated using Aragon as it will also serve as a governance token. However, the token itself is outside the scope. A Placeholder token can be used for examples). One could simply just stake directly on Harvest.Finance or Pickle; however, then the user would not earn PLEX as well.

- Generate commissions for the Plexus core team and wider community in exchange for the Plexus rewards when a user withdraws tokensInRewardsReserve

- Withdraw ERC-20 tokens that have been deposited into the Plexus ecosystem, generating both Plex rewards and 3rd party staking Rewards

- Convert popular ERC-20 tokens or ETH into Uniswap LP tokens to be used for staking on the Plexus platform (as an ease-of-use mechansism to onboard a wider audience might nto understand how to generate LP tokens. Previosuly, before these contracts (specifically the wrapper.sol contract)) a user had to perform over 6 transactions between ETH and obtaining and LP token. Also, this is currently the only platform which allows users to convert LP tokens to any other ERC-20 token (DAI, WETH, USDC) with a single transaction, instead of the 3+ transactions that is usually required.

- View the Average APY of various tokens and farm. For now, these need to be manually intered by an owner as each third-party platform demonstrates this data on their dashboards but that data is not easily obtainable directly from their smart contracts as usually there is an undefined future emmissions drop that happens daily and alos depends on the number of stakers, time periods, etc.

- Retrieve user staking balances within the Plexus Ecosystem
