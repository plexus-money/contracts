require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');

describe('Re-deploying the plexus contracts for Wrapper test', () => {
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;

  const farmTokenAddress = process.env.FARM_TOKEN_MAINNET_ADDRESS;
  const daiTokenAddress = process.env.DAI_TOKEN_MAINNET_ADDRESS;
  const pickleTokenAddress = process.env.PICKLE_TOKEN_MAINNET_ADDRESS;

  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await setupContracts();
    wrapper = deployedContracts.wrapper;
    wrapperSushi = deployedContracts.wrapperSushi;
    tokenRewards = deployedContracts.tokenRewards;
    plexusOracle = deployedContracts.plexusOracle;
    tier1Staking = deployedContracts.tier1Staking;
    core = deployedContracts.core;
    tier2Farm = deployedContracts.tier2Farm;
    tier2Aave = deployedContracts.tier2Aave;
    tier2Pickle = deployedContracts.tier2Pickle;
    plexusCoin = deployedContracts.plexusCoin;
    owner = deployedContracts.owner;
    addr1 = deployedContracts.addr1;
  });

  describe('Test Plexus Uniswap wrapper', () => {
      
    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('User wallet balance is greater than 3 ETH', async () => {
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance is ', ethbalance);
        expect(ethbalance).to.be.gt(3);
    });


     // Conversions From ETH
     it('Should convert 2 ETH to Farm token from harvest.finance via Uniswap', async () => {

        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(farmTokenAddress, abi, provider);
  
        // Please note, the number of farm tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
     
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
          value: ethers.utils.parseEther("2")
        };
  
        // Convert the 2 ETH to Farm Token(s)
        const { status } = await (await wrapper.wrap(zeroAddress, [farmTokenAddress], amountPlaceholder, userSlippageTolerance, overrides)).wait();
  
        // Check if the txn is successful
        expect(status).to.equal(1);
  
        // Check conversion is successful
        if (status === 1) {
  
           // Check the farm token balance in the contract account
           const userFarmTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(owner.address), `ether`));
       
           // Check if the conversion is successful and the user has some farm tokens their wallet
           log("User farm token balance AFTER ETH conversion: ", userFarmTokenBalance);
           expect(userFarmTokenBalance).to.be.gt(0);
  
        }
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethbalance);
        expect(ethbalance).to.be.lt(10000);
  
      });
  
      it('Should convert 2 ETH to DAI Token(s) from MakerDao via Uniswap', async () => {
  
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(daiTokenAddress, abi, provider);
  
        // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
     
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
  
        // Convert the 2 ETH to Dai Token(s)
        const { status } = await (await wrapper.wrap(zeroAddress, [daiTokenAddress], amountPlaceholder, userSlippageTolerance, overrides)).wait();
  
        // Check if the txn is successful
        expect(status).to.equal(1);
  
        // Check conversion is successful
        if (status === 1) {
  
           // Check the dai token balance in the contract account
           const userDaiTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(owner.address), `ether`));
  
           // Check if the conversion is successful and the user has some dai tokens in their wallet
           log("User DAI Token balance AFTER ETH conversion: ", userDaiTokenBalance);
           expect(userDaiTokenBalance).to.be.gt(0);
  
        }
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethbalance);
        expect(ethbalance).to.be.lt(10000);
  
      });
  
      it('Should convert 2 ETH to Pickle Token(s) via Uniswap', async () => {
  
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(pickleTokenAddress, abi, provider);
  
        // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
     
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
  
        // Convert the 2 ETH to Pickle Token(s)
        const { status } = await (await wrapper.wrap(zeroAddress, [pickleTokenAddress], amountPlaceholder, userSlippageTolerance, overrides)).wait();
  
        // Check if the txn is successful
        expect(status).to.equal(1);
  
        // Check conversion is successful
        if (status === 1) {
  
           // Check the pickle token balance in the contract account
           const userPickleTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(owner.address), `ether`));
       
           // Check if the conversion is successful and the user has some pickle tokens in their wallet
           log("User pickle token balance AFTER ETH conversion: ", userPickleTokenBalance);
           expect(userPickleTokenBalance).to.be.gt(0);
  
        }
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethbalance);
        expect(ethbalance).to.be.lt(10000);
  
      });

   
  });

});