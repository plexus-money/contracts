require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');

describe('Re-deploying the plexus ecosystem for Aave (DAI) test', () => {

  // Global test vars
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;

  const tier2ContractName = "DAI";
  const daiTokenAddress = process.env.DAI_TOKEN_MAINNET_ADDRESS;
  const erc20 = new ethers.Contract(daiTokenAddress, abi, provider);
  const unitAmount = "200";

  // Deploy and setup the contracts
  before(async () => {

    [wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1 ] = await setupContracts();

    // Use contract as user/addr1
    coreAsSigner1 = core.connect(addr1);
  });

  describe('Plexus Aave (DAI) Token Transactions', () => {

    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('Plexus test user wallet balance is greater than 3 ETH', async () => {
      const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
      log('User ETH balance is ', ethbalance);
      expect(ethbalance).to.be.gt(3);
    });


    it('tier2Aave (DAI) contract should have the correct Token and Token Staking Addresses', async () => {

        const { status } = await (await tier2Aave.addOrEditStakingContract(tier2ContractName, process.env.AAVE_STAKING_MAINNET_ADDRESS, process.env.DAI_TOKEN_MAINNET_ADDRESS)).wait();
       
        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check conversion is successful
        if (status === 1) {
          expect(await tier2Aave.stakingContractsStakingToken(tier2ContractName)).to.equal(ethers.utils.getAddress(process.env.DAI_TOKEN_MAINNET_ADDRESS));
          expect(await tier2Aave.stakingContracts(tier2ContractName)).to.equal(ethers.utils.getAddress(process.env.AAVE_STAKING_MAINNET_ADDRESS));
        }
    });

    it('Should check that the user wallet DAI Token balance is equal to zero', async () => {
        // Check the dai token balance in the contract account
        const userDaiTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
    
        // Before conversion usser Dai Token balance should be zero
        log("User DAI Token balance BEFORE ETH conversion: ", userDaiTokenBalance);
        expect(userDaiTokenBalance).to.be.lte(0);

    });

    it('Should convert 2 ETH to DAI Token from MakerDao', async () => {

       const zeroAddress = process.env.ZERO_ADDRESS;

       // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
       const amountPlaceholder = ethers.utils.parseEther(unitAmount)
    
       // We send 2 ETH to the wrapper for conversion
       let overrides = {
            value: ethers.utils.parseEther("2")
       };

       // Do the conversion as addr1 user
       let coreAsSigner1 = core.connect(addr1);

       // Convert the 2 ETH to Dai Token(s)
       const { status } = await (await coreAsSigner1.convert(zeroAddress, [daiTokenAddress], amountPlaceholder, overrides)).wait();

       // Check if the txn is successful
       expect(status).to.equal(1);

       // Check conversion is successful
       if (status === 1) {

          // Check the dai token balance in the contract account
          const userDaiTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(addr1.address), `ether`));

          // Check if the conversion is successful and the user has some dai tokens in their wallet
          log("User DAI Token balance AFTER ETH conversion: ", userDaiTokenBalance);
          expect(userDaiTokenBalance).to.be.gt(0);

       }
       // Check that the users ETH balance has reduced regardless of the conversion status
       const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
       log('User ETH balance AFTER ETH conversion is: ', ethbalance);
       expect(ethbalance).to.be.lt(10000);
 
    });

    it("User should be able to deposit DAI Tokens via the core contract", async () => {
    
        const daiTokenDepositAmount = ethers.utils.parseEther(unitAmount);

        // Check the user dai token balance in the token contract before deposit
        const initialUserDaiTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
        log("User DAI Token balance, BEFORE deposit is: ", initialUserDaiTokenBalance);
        
        // Approve the core contract to spend the tokens
        let erc20AsSigner1 =  erc20.connect(addr1);
        const approved = await(await erc20AsSigner1.approve(core.address, daiTokenDepositAmount)).wait();

        // Check if the approved txn is successful
        expect(approved.status).to.equal(1);

        // Check allowance
        const allowance = Number(ethers.utils.formatEther(await erc20.allowance(addr1.address, core.address)));
        log("DAI Tokens approved by user for deposit : ", allowance);

        // Then we deposit 2 Dai Tokens into the core contract as addr1/user
        const deposit = await (await coreAsSigner1.deposit(tier2ContractName, daiTokenAddress, daiTokenDepositAmount)).wait();

        // Check if the deposit txn is successful
        expect(deposit.status).to.equal(1);

        // If txn is successful
        if (deposit.status) {
          // Check the user dai token balance in their account after deposit
          const currUserDaiTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
          log("User DAI token balance, AFTER deposit is: ", currUserDaiTokenBalance);
          
          // Check that the initial user Dai token balance is less 2 Tokens
          expect(currUserDaiTokenBalance).to.be.lt(initialUserDaiTokenBalance);

        }

    });

    it('User should be able to withdraw deposited DAI tokens via the Core Contract', async () => {
    
        const daiTokenWithdrawAmount = ethers.utils.parseEther(unitAmount);
  
        // Check the user's Dai Token balance in the token contract before withdrawal
        const initialUserDaiTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
        log("User DAI Token balance, BEFORE withdrawal is: ", initialUserDaiTokenBalance);
  
        // We withdraw 2 Dai Tokens from the core contract as addr1/user
        const { status } = await (await coreAsSigner1.withdraw(tier2ContractName, daiTokenAddress, daiTokenWithdrawAmount)).wait();
  
        // Check if the withdraw txn is successful
        expect(status).to.equal(1);
  
        // Check if txn is successful
        if (status) {
  
          // Check the user dai token balance in the contract account after deposit
          const currUserDaiTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
          log("User DAI Token balance, AFTER withdrawal is: ", currUserDaiTokenBalance);
           
          // Check that the initial user Dai token balance is less 2 Tokens
          expect(currUserDaiTokenBalance).to.be.gte(initialUserDaiTokenBalance);
  
        }
      
      });
  
  });

});