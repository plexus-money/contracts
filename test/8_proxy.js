require("dotenv").config();
const hre = require("hardhat");
const { expect } = require('chai');
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');

const updateContract = async(contractFactory, deployedProxyAddr, factoryName) => {
  const deployedProxy = await ethers.getContractAt("OwnableProxy", deployedProxyAddr);
  let deployedContract = await (await contractFactory.deploy()).deployed();
  await deployedProxy.upgradeTo(deployedContract.address);
  await deployedContract.setProxy(deployedProxy.address);
}

const updateContracts = async(wrapperProxyAddr, wrapperSushiProxyAddr, tokenRewardsProxyAddr, plexusOracleProxyAddr, tier1StakingProxyAddr, coreProxyAddr, tier2FarmProxyAddr, tier2AaveProxyAddr, tier2PickleProxyAddr) => {
  // then deploy the contracts and wait for them to be mined
  const Wrapper = await ethers.getContractFactory('WrapAndUnWrap');
  const WrapperSushi = await ethers.getContractFactory('WrapAndUnWrapSushi');
  const TokenRewards = await ethers.getContractFactory('TokenRewards');
  const PlexusOracle = await ethers.getContractFactory('PlexusOracle');
  const Tier1Staking = await ethers.getContractFactory('Tier1FarmController');
  const Core = await ethers.getContractFactory('Core');
  const Tier2Farm = await ethers.getContractFactory('Tier2FarmController');
  const Tier2Aave = await ethers.getContractFactory('Tier2AaveFarmController');
  const Tier2Pickle = await ethers.getContractFactory('Tier2PickleFarmController');

  await updateContract(Wrapper, wrapperProxyAddr, 'WrapAndUnWrap');
  await updateContract(WrapperSushi, wrapperSushiProxyAddr, 'WrapAndUnWrapSushi');
  await updateContract(TokenRewards, tokenRewardsProxyAddr, 'TokenRewards');
  await updateContract(PlexusOracle, plexusOracleProxyAddr, 'PlexusOracle');
  await updateContract(Tier1Staking, tier1StakingProxyAddr, 'Tier1FarmController');
  await updateContract(Core, coreProxyAddr, 'Core');
  await updateContract(Tier2Farm, tier2FarmProxyAddr, 'Tier2FarmController');
  await updateContract(Tier2Aave, tier2AaveProxyAddr, 'Tier2AaveFarmController');
  await updateContract(Tier2Pickle, tier2PickleProxyAddr, 'Tier2PickleFarmController');
};

describe('Re-deploying the plexus ecosystem for Proxy test', () => {
  // Global test vars
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle;

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
  });

  describe('Test proxy pattern', () => {
    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('Previous variables should be saved after deployed again', async () => {
      // check previous address before re-deploy.
      const prevTokenRewardsOracleAddr = await tokenRewards.oracleAddress();
      const prevStakingTokenAddr = await tokenRewards.stakingTokensAddress();
      const prevRewardAddr = await plexusOracle.rewardAddress();
      const prevCoreAddr = await plexusOracle.coreAddress();
      const prevTier1Addr = await plexusOracle.tier1Address();
      const prevOracleAddr = await core.oracleAddress();
      const prevStakingAddr = await core.stakingAddress();
      const prevConverterAddr = await core.converterAddress();
      const prevStakingOracleAddr = await tier1Staking.oracleAddress();

      // check previous target.
      const prevWrapperTarget = await wrapper.target();
      const prevWrapperSushiTarget = await wrapperSushi.target();
      const prevTokenRewardsTarget = await tokenRewards.target();
      const prevPlexusOracleTarget = await plexusOracle.target();
      const prevTier1StakingTarget = await tier1Staking.target();
      const prevCoreTarget = await core.target();
      const prevTier2FarmTarget = await tier2Farm.target();
      const prevTier2AaveTarget = await tier2Aave.target();
      const prevTier2PickleTarget = await tier2Pickle.target();

      // Re-deploy
      await updateContracts(wrapper.address, wrapperSushi.address, tokenRewards.address, plexusOracle.address, tier1Staking.address, core.address, tier2Farm.address, tier2Aave.address, tier2Pickle.address);

      // Targets should be different
      expect(await wrapper.target()).to.not.equal(prevWrapperTarget);
      expect(await wrapperSushi.target()).to.not.equal(prevWrapperSushiTarget);
      expect(await tokenRewards.target()).to.not.equal(prevTokenRewardsTarget);
      expect(await plexusOracle.target()).to.not.equal(prevPlexusOracleTarget);
      expect(await tier1Staking.target()).to.not.equal(prevTier1StakingTarget);
      expect(await core.target()).to.not.equal(prevCoreTarget);
      expect(await tier2Farm.target()).to.not.equal(prevTier2FarmTarget);
      expect(await tier2Aave.target()).to.not.equal(prevTier2AaveTarget);
      expect(await tier2Pickle.target()).to.not.equal(prevTier2PickleTarget);

      // Variables should be same although updated contract
      expect(await tokenRewards.oracleAddress()).to.equal(prevTokenRewardsOracleAddr);
      expect(await tokenRewards.stakingTokensAddress()).to.equal(prevStakingTokenAddr);
      expect(await plexusOracle.rewardAddress()).to.equal(prevRewardAddr);
      expect(await plexusOracle.coreAddress()).to.equal(prevCoreAddr);
      expect(await plexusOracle.tier1Address()).to.equal(prevTier1Addr);
      expect(await core.oracleAddress()).to.equal(prevOracleAddr);
      expect(await core.stakingAddress()).to.equal(prevStakingAddr);
      expect(await core.converterAddress()).to.equal(prevConverterAddr);
      expect(await tier1Staking.oracleAddress()).to.equal(prevStakingOracleAddr);
    });
  });

});