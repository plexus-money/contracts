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
