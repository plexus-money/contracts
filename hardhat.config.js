/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require("dotenv").config();
 require('@nomiclabs/hardhat-waffle');
 require('@nomiclabs/hardhat-solhint');
 require('solidity-coverage');
 require("@nomiclabs/hardhat-etherscan");
 require('@eth-optimism/hardhat-ovm');
 
 module.exports = {
   defaultNetwork: "optimism",
   solidity: {
     version: "0.7.6",
     settings: {
       optimizer: {
         enabled: true,
         runs: 200
       }
     }
   },
   
   ovm: {
    solcVersion: '0.7.6' // Your version goes here.
  },  
   networks: {
     hardhat: {
       gas: "auto",
       gasPrice: "auto",
       gasMultiplier: 20,
       blockGasLimit: 90000000000000,
       forking: {
         url: process.env.RPC_NODE_URL,
         blockNumber: 12829900,
       }
     },

    optimism: {
      url: process.env.L2_NODE_URL,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 15000000,
      ovm: true
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

   etherscan: {
     apiKey: process.env.ETHERSCAN_API_KEY
   },

   mocha: {
     timeout: 2000000
   }
 };
