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
    },

    // mainnet: {
    //   gas: "auto",
    //   gasPrice: "auto",
    //   gasMultiplier: 20,
    //   blockGasLimit: 90000000000000,
    //   accounts: {
    //     mnemonic: process.env.MNEMONIC
    //   },
    //   url: process.env.RPC_NODE_URL,
    //   chainId: 1
    // },

    kovan: {
      gas: "auto",
      gasPrice: "auto",
      gasMultiplier: 20,
      blockGasLimit: 90000000000000,
      accounts: {
        mnemonic: process.env.MNEMONIC
      },
      url: process.env.RPC_NODE_URL_KOVAN,
      chainId: 42
    },

    matic: {
      url: "https://rpc-mainnet.maticvigil.com",
      mnemonic: process.env.MNEMONIC
    },

    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      mnemonic: process.env.MNEMONIC
    }
  },

  mocha: {
    timeout: 2000000
  }
};
