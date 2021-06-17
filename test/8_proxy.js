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
    let prevWrapperProxyOwner;
    let prevWrapperContract;
    let prevWrapperContractOwner;
    let prevWrapperSushiProxyOwner;
    let prevWrapperSushiContract;
    let prevWrapperSushiContractOwner;
    let prevTokenRewardsProxyOwner;
    let prevTokenRewardsContract;
    let prevTokenRewardsContractOwner;
    let prevPlexusOracleProxyOwner;
    let prevPlexusOracleContract;
    let prevPlexusOracleContractOwner;
    let prevTier1StakingProxyOwner;
    let prevTier1StakingContract;
    let prevTier1StakingContractOwner;
    let prevCoreProxyOwner;
    let prevCoreContract;
    let prevCoreContractOwner;
    let prevTier2FarmProxyOwner;
    let prevTier2FarmContract;
    let prevTier2FarmContractOwner;
    let prevTier2AaveProxyOwner;
    let prevTier2AaveContract;
    let prevTier2AaveContractOwner;
    let prevTier2PickleProxyOwner;
    let prevTier2PickleContract;
    let prevTier2PickleContractOwner;
    let prevTokenRewardsOracleAddr;
    let prevStakingTokenAddr;
    let tokenAddress;
    let prevStakingTokenWhitelistValue
    let prevStakingLPTokensAddr
    let prevRewardAddr
    let prevCoreAddr
    let prevTier1Addr
    let prevOracleAddr
    let prevStakingAddr
    let prevConverterAddr
    let prevStakingOracleAddr
    let prevWrapperTarget
    let prevWrapperSushiTarget
    let prevTokenRewardsTarget
    let prevPlexusOracleTarget
    let prevTier1StakingTarget
    let prevCoreTarget
    let prevTier2FarmTarget
    let prevTier2AaveTarget
    let prevTier2PickleTarget
    let newWrapperContract;
    let newWrapperSushiContract;
    let newTokenRewardsContract;
    let newPlexusOracleContract;
    let newTier1StakingContract;
    let newCoreContract;
    let newTier2FarmContract;
    let newTier2AaveContract;
    let newTier2PickleContract;

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
  
    before(async () => {
        // Get owner
        prevWrapperProxyOwner = await wrapper.owner();
        prevWrapperContract = await ethers.getContractAt("WrapAndUnWrap", await wrapper.target());
        prevWrapperContractOwner = await prevWrapperContract.owner();
        prevWrapperSushiProxyOwner = await wrapperSushi.owner();
        prevWrapperSushiContract = await ethers.getContractAt("WrapAndUnWrapSushi", await wrapperSushi.target());
        prevWrapperSushiContractOwner = await prevWrapperSushiContract.owner();
        prevTokenRewardsProxyOwner = await tokenRewards.owner();
        prevTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());
        prevTokenRewardsContractOwner = await prevTokenRewardsContract.owner();
        prevPlexusOracleProxyOwner = await plexusOracle.owner();
        prevPlexusOracleContract = await ethers.getContractAt("PlexusOracle", await plexusOracle.target());
        prevPlexusOracleContractOwner = await prevPlexusOracleContract.owner();
        prevTier1StakingProxyOwner = await tier1Staking.owner();
        prevTier1StakingContract = await ethers.getContractAt("Tier1FarmController", await tier1Staking.target());
        prevTier1StakingContractOwner = await prevTier1StakingContract.owner();
        prevCoreProxyOwner = await core.owner();
        prevCoreContract = await ethers.getContractAt("Core", await core.target());
        prevCoreContractOwner = await prevCoreContract.owner();
        prevTier2FarmProxyOwner = await tier2Farm.owner();
        prevTier2FarmContract = await ethers.getContractAt("Tier2FarmController", await tier2Farm.target());
        prevTier2FarmContractOwner = await prevTier2FarmContract.owner();
        prevTier2AaveProxyOwner = await tier2Aave.owner();
        prevTier2AaveContract = await ethers.getContractAt("Tier2AaveFarmController", await tier2Aave.target());
        prevTier2AaveContractOwner = await prevTier2AaveContract.owner();
        prevTier2PickleProxyOwner = await tier2Pickle.owner();
        prevTier2PickleContract = await ethers.getContractAt("Tier2PickleFarmController", await tier2Pickle.target());
        prevTier2PickleContractOwner = await prevTier2PickleContract.owner();

        // Get previous state variables from contracts.
        prevTokenRewardsOracleAddr = await tokenRewards.oracleAddress();
        prevStakingTokenAddr = await tokenRewards.stakingTokensAddress();
        tokenAddress = '0x0000000000000000000000000000000000000000'
        await tokenRewards.addTokenToWhitelist(tokenAddress);
        await tokenRewards.updateLPStakingTokenAddress(tokenAddress);
        prevStakingTokenWhitelistValue = await tokenRewards.getTokenWhiteListValue(tokenAddress);
        prevStakingLPTokensAddr = await tokenRewards.stakingLPTokensAddress();
        prevRewardAddr = await plexusOracle.rewardAddress();
        prevCoreAddr = await plexusOracle.coreAddress();
        prevTier1Addr = await plexusOracle.tier1Address();
        prevOracleAddr = await core.oracleAddress();
        prevStakingAddr = await core.stakingAddress();
        prevConverterAddr = await core.converterAddress();
        prevStakingOracleAddr = await tier1Staking.oracleAddress();

        // Get addresses of original logic contracts.
        prevWrapperTarget = await wrapper.target();
        prevWrapperSushiTarget = await wrapperSushi.target();
        prevTokenRewardsTarget = await tokenRewards.target();
        prevPlexusOracleTarget = await plexusOracle.target();
        prevTier1StakingTarget = await tier1Staking.target();
        prevCoreTarget = await core.target();
        prevTier2FarmTarget = await tier2Farm.target();
        prevTier2AaveTarget = await tier2Aave.target();
        prevTier2PickleTarget = await tier2Pickle.target();

        // Re-deploy
        await updateContracts(wrapper.address, wrapperSushi.address, tokenRewards.address, plexusOracle.address, tier1Staking.address, core.address, tier2Farm.address, tier2Aave.address, tier2Pickle.address);

        newWrapperContract = await ethers.getContractAt("WrapAndUnWrap", await wrapper.target());
        newWrapperSushiContract = await ethers.getContractAt("WrapAndUnWrapSushi", await wrapperSushi.target());
        newTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());
        newPlexusOracleContract = await ethers.getContractAt("PlexusOracle", await plexusOracle.target());
        newTier1StakingContract = await ethers.getContractAt("Tier1FarmController", await tier1Staking.target());
        newCoreContract = await ethers.getContractAt("Core", await core.target());
        newTier2FarmContract = await ethers.getContractAt("Tier2FarmController", await tier2Farm.target());
        newTier2AaveContract = await ethers.getContractAt("Tier2AaveFarmController", await tier2Aave.target());
        newTier2PickleContract = await ethers.getContractAt("Tier2PickleFarmController", await tier2Pickle.target());
    });
  
    it('The Owner of proxy should be equal to the one of his logic contract', () => {
        expect(prevWrapperProxyOwner).to.equal(prevWrapperContractOwner);
        expect(prevWrapperSushiProxyOwner).to.equal(prevWrapperSushiContractOwner);
        expect(prevTokenRewardsProxyOwner).to.equal(prevTokenRewardsContractOwner);
        expect(prevPlexusOracleProxyOwner).to.equal(prevPlexusOracleContractOwner);
        expect(prevTier1StakingProxyOwner).to.equal(prevTier1StakingContractOwner);
        expect(prevCoreProxyOwner).to.equal(prevCoreContractOwner);
    });

    it('For tier2Farm, tier2Aave, and tier2Pickle, The Owner of proxy should be not equal to the one of his logic contract because owner address has been updated after setup.', () => {
        expect(prevTier2FarmProxyOwner).to.not.equal(prevTier2FarmContractOwner);
        expect(prevTier2AaveProxyOwner).to.not.equal(prevTier2AaveContractOwner);
        expect(prevTier2PickleProxyOwner).to.not.equal(prevTier2PickleContractOwner);
    });

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
    });

    it('The Owner of proxy should be equal to the one of updated logic contracts', async () => {
        expect(prevWrapperContractOwner).to.equal(await newWrapperContract.owner());
        expect(prevWrapperSushiProxyOwner).to.equal(await newWrapperSushiContract.owner());
        expect(prevTokenRewardsProxyOwner).to.equal(await newTokenRewardsContract.owner());
        expect(prevPlexusOracleProxyOwner).to.equal(await newPlexusOracleContract.owner());
        expect(prevTier1StakingProxyOwner).to.equal(await newTier1StakingContract.owner());
        expect(prevCoreProxyOwner).to.equal(await newCoreContract.owner());
    });

    it('For tier2Farm, tier2Aave, and tier2Pickle, The Owner of proxy should be not equal to the one of his updated logic contract', async () => {
        expect(prevTier2FarmProxyOwner).to.not.equal(await newTier2FarmContract.owner());
        expect(prevTier2AaveProxyOwner).to.not.equal(await newTier2AaveContract.owner());
        expect(prevTier2PickleProxyOwner).to.not.equal(await newTier2PickleContract.owner());
    });

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