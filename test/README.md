# Plexus Smart Contracts Tests

The tests for the plexus contracts are implemented using [Hardhat via a mainnet fork](https://hardhat.org/guides/mainnet-forking.html).

## Configuration

Before you run the tests, you need to configure the project correctly by doing the following,

1. Create a new [Alchemy Account](https://alchemyapi.io) if you don't have one already.
2. Rename the `.env_sample` file to `.env` and set the `RPC_NODE_URL` variable to the mainnet url in your alchemy account above.
- The reason we're using alchemy is because it supports archive nodes, which is the recommended mode for [mainnet forking](https://hardhat.org/guides/mainnet-forking.html#mainnet-forking) for hardhat.
- But if you have the url of another node that is in archive mode, you can also use it instead of the alchemy one.
3. You can also optionally replace the mainnet token addresses for the ERC20 tokens we're testing against, if they have changed from the ones now set in the `.env` file.

## Run The Tests

To run the tests, make sure you install the latest version of [node.js](https://nodejs.org/en/) and [yarn](https://yarnpkg.com/getting-started/install)

Then install the required node dependencies via the command `yarn install` in the root diirectory. 

Finally run the tests as follows:

1. To run all tests, run the command `yarn test`
2. To run a specific test, run a test command specifying the path to the test file i.e. `yarn test test/1_deployment.js`
3. You can also check the current test coverage via the command `yarn coverage`
4. Finally, you can also check for code linting via the command `yarn lint`

If you want to TURN OFF console logging in the tests, set the `CONSOLE_LOG` variable in the `.env` file to `false` and vice-versa to `true` if you want to TURN ON console logging.

### Test Setup

The plexus contracts should be deployed in the following order,

1. `wrapper.sol`
2. `tokenrewards.sol` 
3. `oracle.sol` 
4. `tier1Staking.sol` 
5. `core.sol` 
6. Finally after all the above contracts have been deployed, you can deploy the specific farming `tier2....` contractss i.e. `tier2Aave.sol`, `tier2Farm.sol` e.t.c
    - For example the `tier2Farm.sol` contract could be deployed, so that users can send tokens to the contract for Harvest.Finance farming e.t.c

### Transactions

After deploying the contracts, run these transactions to setup the plexus ecosystem

1. Call the function `updateOracleAddress` in `tokenrewards.sol` and with the address of the `oracle.sol` contract.
2. Call the function `updateRewardAddress` in `oracle.sol` and with the address of the `tokenrewards.sol` contract.
3. Call the function `updateCoreAddress` in `oracle.sol` and with the address of the `core.sol` contract.
4. Call the function `setOracleAddress` in `core.sol` and then set it to the address of the `oracle.sol` contract.
5. Call the function `setStakingAddress` in `core.sol` and then set it to the address of the `tier1Staking.sol` contract.
6. Call the function `setConverterAddress` in `core.sol` and then set it to the address of the `wrapper.sol` contract.
7. Call the function `updateOracleAddress` in `tier1Staking.sol` and then set it to the address of the `oracle.sol` contract.
8. Call the function `addOrEditTier2ChildStakingContract` in `tier1Staking.sol` and then set it to the address of the `tier2Farm.sol` contract.
9. Call the function `addOrEditTier2ChildStakingContract` in `tier1Staking.sol` and then set it to the address of the `tier2Aave.sol` contract.
10. Call the function `addOrEditTier2ChildStakingContract` in `tier1Staking.sol` and then set it to the address of the `tier2Pickle.sol` contract.
11. Call the function `changeOwner` in all of the `tier2...` contracts and then set it to the address of the `core.sol` contract.
