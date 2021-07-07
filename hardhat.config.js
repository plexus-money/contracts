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
 
     mainnet: {
       accounts: {
         mnemonic: process.env.MNEMONIC
       },
       url: process.env.RPC_NODE_URL,
       chainId: 1,
       timeout: 2000000
     },
     
     kovan: {
       accounts: {
         mnemonic: process.env.MNEMONIC
       },
       url: process.env.RPC_NODE_URL_KOVAN,
       chainId: 42,
       timeout: 2000000
     },
     
     binance: {
       accounts: {
         mnemonic: process.env.MNEMONIC
       },
       url: "https://bsc-dataseed.binance.org/",
       chainId: 56,
       timeout: 20000000
     },
     
     matic: {
       accounts: {
         mnemonic: process.env.MNEMONIC
       },
       url: "https://rpc-mainnet.maticvigil.com/",
       chainId: 137,
       timeout: 20000000
     },
 
   },
 
   mocha: {
     timeout: 2000000
   }
 };
 