require("dotenv").config();

const config = require('../config.json');
const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');
const addr = config.addresses;

describe('Re-deploying the plexus ecosystem for Pickle test', () => {

  // Global test vars
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;
  let netinfo;
  let network = 'unknown';
  let wethAddress;
  let pickleTokenAddress;

  const tier2ContractName = "PICKLE";
  let erc20;
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

    netinfo = await ethers.provider.getNetwork();
    network = netinfo.chainId === 1 ? "mainnet" :
    netinfo.chainId === 42 ? "kovan" :
    netinfo.chainId === 56 ? "binance" :
    netinfo.chainId === 137 ? "matic" : 'mainnet';
    pickleTokenAddress = addr.tokens.PICKLE[network];
    wethAddress = addr.tokens.WETH[network];
    erc20 = new ethers.Contract(pickleTokenAddress, abi, provider);
    // Use contract as user/addr1
     coreAsSigner1 = core.connect(addr1);
  });

  describe('Plexus Pickle Token Transactions', () => {

    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('Plexus test user wallet balance is greater than 3 ETH', async () => {
      const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
      log('User ETH balance is ', ethbalance);
      expect(ethbalance).to.be.gt(3);
    });

    it('tier2Pickle contract should have the correct Token and Token Staking Addresses', async () => {
        const { status } = await (await tier1Staking.addOrEditTier2ChildsChildStakingContract(tier2Pickle.address, tier2ContractName, process.env.PICKLE_STAKING_MAINNET_ADDRESS, process.env.PICKLE_TOKEN_MAINNET_ADDRESS)).wait();

        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check conversion is successful
        if (status === 1) {
          expect(await tier2Pickle.stakingContractsStakingToken(tier2ContractName)).to.equal(process.env.PICKLE_TOKEN_MAINNET_ADDRESS);
          expect(await tier2Pickle.stakingContracts(tier2ContractName)).to.equal(process.env.PICKLE_STAKING_MAINNET_ADDRESS);
        }
    });

    it('Plexus test user wallet Pickle Token balance is equal to zero', async () => {
        // Check the pickle token balance in the contract account
        const userPickleTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));

        // Before conversion usser Pickle Token balance should be zero
        log("User pickle token balance BEFORE ETH conversion: ", userPickleTokenBalance);
        expect(userPickleTokenBalance).to.be.lte(0);

    });

    it('Should convert 2 ETH to Pickle Token', async () => {

       const zeroAddress = process.env.ZERO_ADDRESS;
       const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
       // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
       const amountPlaceholder = ethers.utils.parseEther(unitAmount)

       // We send 2 ETH to the wrapper for conversion
       let overrides = {
            value: ethers.utils.parseEther("2")
       };

       // Do the conversion as addr1 user
       let coreAsSigner1 = core.connect(addr1);

       // Convert the 2 ETH to Pickle Token(s)
       const deadline = Math.floor(new Date().getTime() / 1000) + 10;
       const paths = [[wethAddress, pickleTokenAddress]];
       const { status } = await (await coreAsSigner1.convert(zeroAddress, [pickleTokenAddress], paths, amountPlaceholder, userSlippageTolerance, deadline, overrides)).wait();

       // Check if the txn is successful
       expect(status).to.equal(1);

       // Check conversion is successful
       if (status === 1) {

          // Check the pickle token balance in the contract account
          const userPickleTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(addr1.address), `ether`));

          // Check if the conversion is successful and the user has some pickle tokens in their wallet
          log("User pickle token balance AFTER ETH conversion: ", userPickleTokenBalance);
          expect(userPickleTokenBalance).to.be.gt(0);

       }
       // Check that the users ETH balance has reduced regardless of the conversion status
       const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
       log('User ETH balance AFTER ETH conversion is: ', ethbalance);
       expect(ethbalance).to.be.lt(10000);

    });

    it("User should be able to deposit Pickle Tokens via the core contract", async () => {

        const pickleTokenDepositAmount = ethers.utils.parseEther(unitAmount);

        // Check the user pickle token balance in the token contract before deposit
        const initialUserPickleTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
        log("User pickle token balance, BEFORE deposit is: ", initialUserPickleTokenBalance);

        // Approve the core contract to spend the tokens
        let erc20AsSigner1 =  erc20.connect(addr1);
        const approved = await(await erc20AsSigner1.approve(core.address, pickleTokenDepositAmount)).wait();

        // Check if the approved txn is successful
        expect(approved.status).to.equal(1);

        // Check allowance
        const allowance = Number(ethers.utils.formatEther(await erc20.allowance(addr1.address, core.address)));
        log("Pickle tokens approved by user for deposit : ", allowance);

        // Then we deposit 2 Pickle Tokens into the core contract as addr1/user
        const deposit = await (await coreAsSigner1.deposit(tier2ContractName, pickleTokenAddress, pickleTokenDepositAmount)).wait();

        // Check if the deposit txn is successful
        expect(deposit.status).to.equal(1);

        // If txn is successful
        if (deposit.status) {

          // Check the user pickle token balance in the contract account after deposit
          const currUserPickleTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
          log("User pickle token balance, AFTER deposit is: ", currUserPickleTokenBalance);

          // Check that the initial user Pickle token balance is less 2 Tokens
          expect(currUserPickleTokenBalance).to.be.lt(initialUserPickleTokenBalance);

        }

    });

    it('User should be able to withdraw deposited Pickle tokens via the Core Contract', async () => {

      const pickleTokenWithdrawAmount = ethers.utils.parseEther(unitAmount);

      // Check the user's Pickle Token balance in the token contract before withdrawal
      const initialUserPickleTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
      log("User pickle token balance, BEFORE withdrawal is: ", initialUserPickleTokenBalance);

      // We withdraw 2 Pickle Tokens from the core contract as addr1/user
      const { status } = await (await coreAsSigner1.withdraw(tier2ContractName, pickleTokenAddress, pickleTokenWithdrawAmount)).wait();

      // Check if the withdraw txn is successful
      expect(status).to.equal(1);

      // Check if txn is successful
      if (status) {

        // Check the user pickle token balance in the contract account after deposit
        const currUserPickleTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));
        log("User pickle token balance, AFTER withdrawal is: ", currUserPickleTokenBalance);

        // Check that the initial user Pickle token balance is less 2 Tokens
        expect(currUserPickleTokenBalance).to.be.gte(initialUserPickleTokenBalance);

      }

    });

  });

});