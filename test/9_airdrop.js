require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');

const delay = ms => new Promise(res => setTimeout(res, ms));

describe('Re-deploying the plexus contracts for Airdrop test', () => {
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, airdrop, owner, addr1, addrs;
  let erc20;

  const interval = process.env.BLOCK_MINING_INTERVAL;

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
    airdrop = deployedContracts.airdrop;
    owner = deployedContracts.owner;
    addr1 = deployedContracts.addr1;
    addrs = deployedContracts.addrs;

    erc20 = new ethers.Contract(plexusCoin.address, abi, provider);
  });

  describe('Test Plexus Airdrop', () => {

    // Airdrop contract has 100000 PLX coins
    it('Should have 100000 coins', async () => {
      const plxBalance = Number(ethers.utils.formatEther(await plexusCoin.balanceOf(airdrop.address)));
      log('Airdrop PLX balance is ', plxBalance);
      expect(plxBalance).to.be.equal(100000);
    });


    // Test Claim with Option #1
    it('User should be able to claim the airdrop with option 1', async () => {
      log('Before claiming, the PLX balance of address 1 is ',
        Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address))));

      // Add a new address for airdrop (total 3 addresses)
      const { status } = await (await airdrop.addAirdropAddress(addrs[1].address)).wait();

      // Check if the txn is successful
      expect(status).to.equal(1);

      const amount = Number(ethers.utils.formatEther(await airdrop.amounts(addrs[1].address)));

      // Check if the amount of new address is 4000
      expect(amount).to.be.equal(4000);

      // Claim the airdrop with addr1
      const airdropped = await (await airdrop.connect(addr1).claimAirdropWithOption1()).wait();

      // Check if the txn is successful
      expect(airdropped.status).to.equal(1);

      const upfrontAmount = Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address)));

      log('After claming with option 1, the PLX balance of address 1 is', upfrontAmount);

      expect(upfrontAmount).to.be.equal(1600);
    });


    // Test Twice Claim with Option #1
    it('User should not be able to claim the airdrop more than once', async () => {
      log('Before the second claiming, the PLX balance of address 1 is ',
        Number(ethers.utils.formatEther(await erc20.balanceOf(addr1.address))));

      await expect(airdrop.connect(addr1).claimAirdropWithOption1()).to.be.revertedWith("You already got the airdrop");
    });


    // Test Claim with Option #2
    it('User should be able to claim the airdrop with option 2', async () => {
      log('Before claiming, the PLX balance of address 1 is ',
        Number(ethers.utils.formatEther(await erc20.balanceOf(addrs[0].address))));

      const { status } = await (await airdrop.setAmount(addrs[0].address, ethers.utils.parseEther("3000"))).wait();

      // Check if the txn is successful
      expect(status).to.equal(1);

      await (await airdrop.addAirdropAddress(addrs[1].address)).wait();

      // Claim the airdrop with addrs[0]
      const airdropped = await (await airdrop.connect(addrs[0]).claimAirdropWithOption2()).wait();

      // Check if the txn is successful
      expect(airdropped.status).to.equal(1);

      const upfrontAmount = Number(ethers.utils.formatEther(await erc20.balanceOf(addrs[0].address)));

      log('After first claming with option 2, the PLX balance of address 2 is', upfrontAmount);

      expect(upfrontAmount).to.be.equal(900);
    });

    it('User should be able to get other 10% using the second claim after 50 blocks', async () => {
      // Get the current balance of address 2
      const prevAmount = Number(ethers.utils.formatEther(await erc20.balanceOf(addrs[0].address)));

      log('Before the second claiming, the PLX balance of address 1 is', prevAmount);

      // Try to claim again and check if it is reverted
      await expect(airdrop.connect(addrs[0]).claimAirdropWithOption2()).to.be.revertedWith("You need to wait more time.");

      // Wait until 60 blocks are mined
      // await delay(interval * 60);
      for (let i = 0; i < 50; i ++) {
        await ethers.provider.send("evm_mine");
      }

      // Try to claim again
      let claimed = await (await airdrop.connect(addrs[0]).claimAirdropWithOption2()).wait();

      // Check if the txn is successful
      expect(claimed.status).to.equal(1);

      // Get the balance of address 2 after claim
      const amount1 = Number(ethers.utils.formatEther(await erc20.balanceOf(addrs[0].address)));

      log('After the second claiming, the PLX balance of address 1 is ', amount1);

      expect(amount1).to.equal(1200);

      // Wait until 250 blocks are mined
      // await delay(interval * 250);
      for (let i = 0; i < 250; i ++) {
        await ethers.provider.send("evm_mine");
      }

      // Try to claim again
      claimed = await (await airdrop.connect(addrs[0]).claimAirdropWithOption2()).wait();

      // Check if the txn is successful
      expect(claimed.status).to.equal(1);

      // Get the balance of address 2 after claim
      const amount2 = Number(ethers.utils.formatEther(await erc20.balanceOf(addrs[0].address)));

      log('After the third claiming, the PLX balance of address 1 is ', amount2);

      expect(amount2).to.equal(2700);

      for (let i = 0; i < 100; i ++) {
        await ethers.provider.send("evm_mine");
      }

      // Try to claim again
      claimed = await (await airdrop.connect(addrs[0]).claimAirdropWithOption2()).wait();

      // Check if the txn is successful
      expect(claimed.status).to.equal(1);

      // Get the balance of address 2 after claim
      const amount3 = Number(ethers.utils.formatEther(await erc20.balanceOf(addrs[0].address)));

      log('After the fourth claiming, the PLX balance of address 1 is ', amount3);

      expect(amount3).to.equal(3000);
    });

  });

});