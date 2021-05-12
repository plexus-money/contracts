/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-solhint');
require('solidity-coverage');

module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 20,
      blockGasLimit: 90000000000000,
      forking: {
        url: process.env.RPC_NODE_URL,
        blockNumber: 11997864,
      }
    }
  },
  mocha: {
    timeout: 2000000
  }
};
