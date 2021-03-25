require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');

describe('Re-deploying the plexus ecosystem for Farm test', () => {

  // Global test vars
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;

  const tier2ContractName = "FARM";
  const farmTokenAddress = process.env.FARM_TOKEN_MAINNET_ADDRESS;
  const erc20 = new ethers.Contract(farmTokenAddress, abi, provider);
  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {

    [ wrapper, 
      wrapperSushi, 
      tokenRewards, 
      plexusOracle, 
      tier1Staking, 
      core, 
      tier2Farm, 
      tier2Aave, 
      tier2Pickle, 
      plexusCoin, 
      owner, 
      addr1 ] = await setupContracts();

    // Use contract as user/addr1
    coreAsSigner1 = core.connect(addr1);
  });

  describe('Plexus Farm Token Transactions', () => {

    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('User wallet balance is greater than 3 ETH', async () => {
        const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
        log('User ETH balance is ', ethbalance);
        expect(ethbalance).to.be.gt(3);
    });


    it('tier2Farm contract should have the correct Token and Token Staking Addresses', async () => {

        const { status } = await (await tier1Staking.addOrEditTier2ChildsChildStakingContract(tier2Farm.address, tier2ContractName, process.env.FARM_STAKING_MAINNET_ADDRESS, process.env.FARM_TOKEN_MAINNET_ADDRESS)).wait();

        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check conversion is successful
        if (status === 1) {

          expect(await tier2Farm.stakingContractsStakingToken(tier2ContractName)).to.equal(process.env.FARM_TOKEN_MAINNET_ADDRESS);
          expect(await tier2Farm.stakingContracts(tier2ContractName)).to.equal(process.env.FARM_STAKING_MAINNET_ADDRESS);
        }
    });

    it('Plexus test user wallet Farm Token balance is equal to zero', async () => {
        // Check the farm token balance in the contract account
        const userFarmTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
    
        // Before conversion usser Farm Token balance should be zero
        log("User farm token balance BEFORE ETH conversion: ", userFarmTokenBalance);
        expect(userFarmTokenBalance).to.be.lte(0);

    });

    it('Should convert 2 ETH to Farm token from harvest.finance', async () => {

       const zeroAddress = process.env.ZERO_ADDRESS;

       // Please note, the number of farm tokens we want to get doesn't matter, so the unit amount is just a placeholder
       const amountPlaceholder = ethers.utils.parseEther(unitAmount)
    
       // We send 2 ETH to the wrapper for conversion
       let overrides = {
            value: ethers.utils.parseEther("2")
       };

       // Do the conversion as addr1 user
       let coreAsSigner1 = core.connect(addr1);

       // Convert the 2 ETH to Farm Token(s)
       const { status } = await (await coreAsSigner1.convert(zeroAddress, [farmTokenAddress], amountPlaceholder, overrides)).wait();

       // Check if the txn is successful
       expect(status).to.equal(1);

       // Check conversion is successful
       if (status === 1) {

          // Check the farm token balance in the contract account
          const userFarmTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(addr1.address), `ether`));
      
          // Check if the conversion is successful and the user has some farm tokens in their wallet
          log("User farm token balance AFTER ETH conversion: ", userFarmTokenBalance);
          expect(userFarmTokenBalance).to.be.gt(0);

       }
       // Check that the users ETH balance has reduced regardless of the conversion status
       const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
       log('User ETH balance AFTER ETH conversion is: ', ethbalance);
       expect(ethbalance).to.be.lt(10000);
 
    });

    it("User should be able to deposit Farm Tokens via the core contract", async () => {
    
        const farmTokenDepositAmount = ethers.utils.parseEther(unitAmount);

        // Check the user farm token balance in the token contract before deposit
        const initialUserFarmTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
        log("User farm token balance, BEFORE deposit is: ", initialUserFarmTokenBalance);
        
        // Approve the core contract to spend the tokens
        let erc20AsSigner1 =  erc20.connect(addr1);
        const approved = await(await erc20AsSigner1.approve(core.address, farmTokenDepositAmount)).wait();

        // Check if the approved txn is successful
        expect(approved.status).to.equal(1);

        // Check allowance
        const allowance = Number(ethers.utils.formatEther(await erc20.allowance(addr1.address, core.address)));
        log("Farm tokens approved by user for deposit : ", allowance);

        // Then we deposit 2 Farm Tokens into the core contract as addr1/user
        const deposit = await (await coreAsSigner1.deposit(tier2ContractName, farmTokenAddress, farmTokenDepositAmount)).wait();

        // Check if the deposit txn is successful
        expect(deposit.status).to.equal(1);

        // If txn is successful
        if (deposit.status) {

          // Check the user farm token balance in the contract account after deposit
          const currUserFarmTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
          log("User farm token balance, AFTER deposit is: ", currUserFarmTokenBalance);
          
          // Check that the initial user Farm token balance is less 2 Tokens
          expect(currUserFarmTokenBalance).to.be.lt(initialUserFarmTokenBalance);

        }

    });

    it('User should be able to withdraw deposited Farm tokens via the Core Contract', async () => {
    
      const farmTokenWithdrawAmount = ethers.utils.parseEther(unitAmount);

      // Check the user's Farm Token balance in the token contract before withdrawal
      const initialUserFarmTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
      log("User farm token balance, BEFORE withdrawal is: ", initialUserFarmTokenBalance);

      // We withdraw 2 Farm Tokens from the core contract as addr1/user
      const { status } = await (await coreAsSigner1.withdraw(tier2ContractName, farmTokenAddress, farmTokenWithdrawAmount)).wait();

      // Check if the withdraw txn is successful
      expect(status).to.equal(1);

      // Check if txn is successful
      if (status) {

        // Check the user farm token balance in the contract account after deposit
        const currUserFarmTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
        log("User farm token balance, AFTER withdrawal is: ", currUserFarmTokenBalance);
         
        // Check that the initial user Farm token balance is less 2 Tokens
        expect(currUserFarmTokenBalance).to.be.gte(initialUserFarmTokenBalance);

      }
    
    });
  
  });

});