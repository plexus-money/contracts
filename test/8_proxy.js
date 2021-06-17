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

  it('Comparing the status of updated contracts to previous status', async () => {
    // check owner
    const prevWrapperProxyOwner = await wrapper.owner();
    const prevWrapperContract = await ethers.getContractAt("WrapAndUnWrap", await wrapper.target());
    const prevWrapperContractOwner = await prevWrapperContract.owner();
    const prevWrapperSushiProxyOwner = await wrapperSushi.owner();
    const prevWrapperSushiContract = await ethers.getContractAt("WrapAndUnWrapSushi", await wrapperSushi.target());
    const prevWrapperSushiContractOwner = await prevWrapperSushiContract.owner();
    const prevTokenRewardsProxyOwner = await tokenRewards.owner();
    const prevTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());
    const prevTokenRewardsContractOwner = await prevTokenRewardsContract.owner();
    const prevPlexusOracleProxyOwner = await plexusOracle.owner();
    const prevPlexusOracleContract = await ethers.getContractAt("PlexusOracle", await plexusOracle.target());
    const prevPlexusOracleContractOwner = await prevPlexusOracleContract.owner();
    const prevTier1StakingProxyOwner = await tier1Staking.owner();
    const prevTier1StakingContract = await ethers.getContractAt("Tier1FarmController", await tier1Staking.target());
    const prevTier1StakingContractOwner = await prevTier1StakingContract.owner();
    const prevCoreProxyOwner = await core.owner();
    const prevCoreContract = await ethers.getContractAt("Core", await core.target());
    const prevCoreContractOwner = await prevCoreContract.owner();
    const prevTier2FarmProxyOwner = await tier2Farm.owner();
    const prevTier2FarmContract = await ethers.getContractAt("Tier2FarmController", await tier2Farm.target());
    const prevTier2FarmContractOwner = await prevTier2FarmContract.owner();
    const prevTier2AaveProxyOwner = await tier2Aave.owner();
    const prevTier2AaveContract = await ethers.getContractAt("Tier2AaveFarmController", await tier2Aave.target());
    const prevTier2AaveContractOwner = await prevTier2AaveContract.owner();
    const prevTier2PickleProxyOwner = await tier2Pickle.owner();
    const prevTier2PickleContract = await ethers.getContractAt("Tier2PickleFarmController", await tier2Pickle.target());
    const prevTier2PickleContractOwner = await prevTier2PickleContract.owner();

    describe('', () => {
      it('The Owner of proxy should be equal to the one of his logic contract', () => {
        expect(prevWrapperProxyOwner).to.equal(prevWrapperContractOwner);
        expect(prevWrapperSushiProxyOwner).to.equal(prevWrapperSushiContractOwner);
        expect(prevTokenRewardsProxyOwner).to.equal(prevTokenRewardsContractOwner);
        expect(prevPlexusOracleProxyOwner).to.equal(prevPlexusOracleContractOwner);
        expect(prevTier1StakingProxyOwner).to.equal(prevTier1StakingContractOwner);
        expect(prevCoreProxyOwner).to.equal(prevCoreContractOwner);
      });
    });

    describe('', () => {
      it('For tier2Farm, tier2Aave, and tier2Pickle, The Owner of proxy should be not equal to the one of his logic contract because owner address has been updated after setup.', () => {
        expect(prevTier2FarmProxyOwner).to.not.equal(prevTier2FarmContractOwner);
        expect(prevTier2AaveProxyOwner).to.not.equal(prevTier2AaveContractOwner);
        expect(prevTier2PickleProxyOwner).to.not.equal(prevTier2PickleContractOwner);
      });
    })

    // Get previous state variables from contracts.
    const prevTokenRewardsOracleAddr = await tokenRewards.oracleAddress();
    const prevStakingTokenAddr = await tokenRewards.stakingTokensAddress();
    const tokenAddress = '0x0000000000000000000000000000000000000000'
    await tokenRewards.addTokenToWhitelist(tokenAddress);
    await tokenRewards.updateLPStakingTokenAddress(tokenAddress);
    const prevStakingTokenWhitelistValue = await tokenRewards.getTokenWhiteListValue(tokenAddress);
    const prevStakingLPTokensAddr = await tokenRewards.stakingLPTokensAddress();
    const prevRewardAddr = await plexusOracle.rewardAddress();
    const prevCoreAddr = await plexusOracle.coreAddress();
    const prevTier1Addr = await plexusOracle.tier1Address();
    const prevOracleAddr = await core.oracleAddress();
    const prevStakingAddr = await core.stakingAddress();
    const prevConverterAddr = await core.converterAddress();
    const prevStakingOracleAddr = await tier1Staking.oracleAddress();

    // Get addresses of original logic contracts.
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

    describe('', () => {
      it('The Owner of proxy should remains after updated logic contracts', async () => {
        expect(await wrapper.owner()).to.equal(prevWrapperProxyOwner);
        expect(await wrapperSushi.owner()).to.equal(prevWrapperSushiProxyOwner);
        expect(await tokenRewards.owner()).to.equal(prevTokenRewardsProxyOwner);
        expect(await plexusOracle.owner()).to.equal(prevPlexusOracleProxyOwner);
        expect(await tier1Staking.owner()).to.equal(prevTier1StakingProxyOwner);
        expect(await core.owner()).to.equal(prevCoreProxyOwner);
        expect(await tier2Farm.owner()).to.equal(prevTier2FarmProxyOwner);
        expect(await tier2Aave.owner()).to.equal(prevTier2AaveProxyOwner);
        expect(await tier2Pickle.owner()).to.equal(prevTier2PickleProxyOwner);
      })
    })

    //Get address of updated logic contracts.
    const newWrapperContract = await ethers.getContractAt("WrapAndUnWrap", await wrapper.target());
    const newWrapperSushiContract = await ethers.getContractAt("WrapAndUnWrapSushi", await wrapperSushi.target());
    const newTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());
    const newPlexusOracleContract = await ethers.getContractAt("PlexusOracle", await plexusOracle.target());
    const newTier1StakingContract = await ethers.getContractAt("Tier1FarmController", await tier1Staking.target());
    const newCoreContract = await ethers.getContractAt("Core", await core.target());
    const newTier2FarmContract = await ethers.getContractAt("Tier2FarmController", await tier2Farm.target());
    const newTier2AaveContract = await ethers.getContractAt("Tier2AaveFarmController", await tier2Aave.target());
    const newTier2PickleContract = await ethers.getContractAt("Tier2PickleFarmController", await tier2Pickle.target());

    describe('', () => {
      it('The Owner of proxy should be equal to the one of updated logic contracts', async () => {
        expect(prevWrapperContractOwner).to.equal(await newWrapperContract.owner());
        expect(prevWrapperSushiProxyOwner).to.equal(await newWrapperSushiContract.owner());
        expect(prevTokenRewardsProxyOwner).to.equal(await newTokenRewardsContract.owner());
        expect(prevPlexusOracleProxyOwner).to.equal(await newPlexusOracleContract.owner());
        expect(prevTier1StakingProxyOwner).to.equal(await newTier1StakingContract.owner());
        expect(prevCoreProxyOwner).to.equal(await newCoreContract.owner());
      });
    });

    describe('', () => {
      it('For tier2Farm, tier2Aave, and tier2Pickle, The Owner of proxy should be not equal to the one of his updated logic contract', async () => {
        expect(prevTier2FarmProxyOwner).to.not.equal(await newTier2FarmContract.owner());
        expect(prevTier2AaveProxyOwner).to.not.equal(await newTier2AaveContract.owner());
        expect(prevTier2PickleProxyOwner).to.not.equal(await newTier2PickleContract.owner());
      });
    })

    describe('', () => {
      it('Logic contracts from proxies should be different from original logic contracts after reset target of proxies', async () => {
        expect(await wrapper.target()).to.not.equal(prevWrapperTarget);
        expect(await wrapperSushi.target()).to.not.equal(prevWrapperSushiTarget);
        expect(await tokenRewards.target()).to.not.equal(prevTokenRewardsTarget);
        expect(await plexusOracle.target()).to.not.equal(prevPlexusOracleTarget);
        expect(await tier1Staking.target()).to.not.equal(prevTier1StakingTarget);
        expect(await core.target()).to.not.equal(prevCoreTarget);
        expect(await tier2Farm.target()).to.not.equal(prevTier2FarmTarget);
        expect(await tier2Aave.target()).to.not.equal(prevTier2AaveTarget);
        expect(await tier2Pickle.target()).to.not.equal(prevTier2PickleTarget);
      });
    });

    describe('', () => {
      it('Global state variables of original contracts should be preserved in new contracts after redeploy', async () => {
        expect(await tokenRewards.oracleAddress()).to.equal(prevTokenRewardsOracleAddr);
        expect(await tokenRewards.stakingTokensAddress()).to.equal(prevStakingTokenAddr);
        expect(await tokenRewards.stakingLPTokensAddress()).to.equal(prevStakingLPTokensAddr);
        expect(await tokenRewards.getTokenWhiteListValue(tokenAddress)).to.equal(prevStakingTokenWhitelistValue);
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
});