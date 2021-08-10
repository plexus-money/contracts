/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require('dotenv').config();
 require('@nomiclabs/hardhat-waffle');
 require('@nomiclabs/hardhat-solhint');
 require('solidity-coverage');
 require("@nomiclabs/hardhat-etherscan");

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

     mainnet: {
      accounts: [`0x${process.env.MAINNET_PRIVATE_KEY}`],
       url: process.env.RPC_NODE_URL,
       chainId: 1,
       timeout: 2000000
     },

     kovan: {
      accounts: [`0x${process.env.KOVAN_PRIVATE_KEY}`],
       url: process.env.RPC_NODE_URL_KOVAN,
       chainId: 42,
       timeout: 2000000
     },

     binance: {
      accounts: [`0x${process.env.BINANCE_PRIVATE_KEY}`],
       url: "https://bsc-dataseed.binance.org/",
       chainId: 56,
       timeout: 20000000
     },

     matic: {
      accounts: [`0x${process.env.MATIC_PRIVATE_KEY}`],
       url: "https://rpc-mainnet.maticvigil.com/",
       chainId: 137,
       timeout: 20000000
     },
   },

   etherscan: {
     apiKey: process.env.ETHERSCAN_API_KEY
   },

   mocha: {
     timeout: 2000000
   }
 };
