const { expect } = require('chai');
const { setupContracts, log } = require('./helper');

describe('Deploying the plexus contracts', () => {
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, airdrop, owner, addr1;

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
  });

  describe('Test plexus contract deployment', () => {

    it('Should set the deployed contracts to the correct owner', async function () {
      expect(await wrapper.owner()).to.equal(owner.address);
      expect(await wrapperSushi.owner()).to.equal(owner.address);
      expect(await tokenRewards.owner()).to.equal(owner.address);
      expect(await plexusOracle.owner()).to.equal(owner.address);
      expect(await tier1Staking.owner()).to.equal(owner.address);
      expect(await core.owner()).to.equal(owner.address);
      expect(await plexusCoin.owner()).to.equal(owner.address);
      expect(await airdrop.owner()).to.equal(owner.address);
    });

    it('Should set the tier1Staking contract as the owner of the deployed tier2 contracts', async function () {
      expect(await tier2Farm.owner()).to.equal(tier1Staking.address);
      expect(await tier2Aave.owner()).to.equal(tier1Staking.address);
      expect(await tier2Pickle.owner()).to.equal(tier1Staking.address);
    });

    it('Should setup the contracts addresses correctly after deployment', async function () {
      expect(await tokenRewards.oracleAddress()).to.equal(plexusOracle.address);
      expect(await plexusOracle.rewardAddress()).to.equal(tokenRewards.address);
      expect(await plexusOracle.coreAddress()).to.equal(core.address);
      expect(await plexusOracle.tier1Address()).to.equal(tier1Staking.address);

      expect(await core.oracleAddress()).to.equal(plexusOracle.address);
      expect(await core.converterAddress()).to.equal(wrapper.address);
      expect(await core.stakingAddress()).to.equal(tier1Staking.address);

      expect(await tier1Staking.oracleAddress()).to.equal(plexusOracle.address);
      expect(await tier1Staking.tier2StakingContracts("FARM")).to.equal(tier2Farm.address);
    });

    // we need to make sure user wallet has atleast 100 ETH to make sure subsequent tests don't fail during conversion
    it('Plexus test user wallet balance is greater than 100 ETH', async () => {
      const ethbalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
      log('Starting ETH balance is ', ethbalance);
      expect(ethbalance).to.be.gte(100);
    });
  });

});
