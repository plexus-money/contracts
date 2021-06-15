require("dotenv").config();
const hre = require("hardhat");

const setupContracts = async() => {
    // get the contract factories
    const Wrapper = await ethers.getContractFactory('WrapAndUnWrap');
    const WrapperSushi = await ethers.getContractFactory('WrapAndUnWrapSushi');
    const TokenRewards = await ethers.getContractFactory('TokenRewards');
    const PlexusOracle = await ethers.getContractFactory('PlexusOracle');
    const Tier1Staking = await ethers.getContractFactory('Tier1FarmController');
    const Core = await ethers.getContractFactory('Core');
    const OwnableProxy = await ethers.getContractFactory('OwnableProxy');
    const Tier2Farm = await ethers.getContractFactory('Tier2FarmController');
    const Tier2Aave = await ethers.getContractFactory('Tier2AaveFarmController');
    const Tier2Pickle = await ethers.getContractFactory('Tier2PickleFarmController');

    // plexus reward token
    const PlexusCoin = await ethers.getContractFactory('PlexusTestCoin');
    
    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    // then deploy the contracts and wait for them to be mined
    const wrapperValues = await deployWithProxy(Wrapper, OwnableProxy, 'WrapAndUnWrap');
    const wrapper = wrapperValues[0]
    const wrapperProxy = wrapperValues[1]
    const wrapperSushiValues = await deployWithProxy(WrapperSushi, OwnableProxy, 'WrapAndUnWrapSushi');
    const wrapperSushi = wrapperSushiValues[0]
    const wrapperSushiProxy = wrapperSushiValues[1]
    const tokenRewardsValues = await deployWithProxy(TokenRewards, OwnableProxy, 'TokenRewards');
    const tokenRewards = tokenRewardsValues[0]
    const tokenRewardsProxy = tokenRewardsValues[1]
    const plexusOracleValues = await deployWithProxy(PlexusOracle, OwnableProxy, 'PlexusOracle');
    const plexusOracle = plexusOracleValues[0]
    const plexusOracleProxy = plexusOracleValues[1]
    const tier1StakingValues = await deployWithProxy(Tier1Staking, OwnableProxy, 'Tier1FarmController');
    const tier1Staking = tier1StakingValues[0]
    const tier1StakingProxy = tier1StakingValues[1]
    const coreValues = await deployWithProxy(Core, OwnableProxy, 'Core');
    const core = coreValues[0]
    const coreProxy = coreValues[1]
    const tier2FarmValues = await deployWithProxy(Tier2Farm, OwnableProxy, 'Tier2FarmController');
    const tier2Farm = tier2FarmValues[0]
    const tier2FarmProxy = tier2FarmValues[1]
    const tier2AaveValues = await deployWithProxy(Tier2Aave, OwnableProxy, 'Tier2AaveFarmController');
    const tier2Aave = tier2AaveValues[0]
    const tier2AaveProxy = tier2AaveValues[1]
    const tier2PickleValues = await deployWithProxy(Tier2Pickle, OwnableProxy, 'Tier2PickleFarmController');
    const tier2Pickle = tier2PickleValues[0]
    const tier2PickleProxy = tier2PickleValues[1]

    // plexus reward token
    const plexusCoin = await (await PlexusCoin.deploy()).deployed();

    // then setup the contracts
    await tokenRewards.updateOracleAddress(plexusOracle.address);
    await tokenRewards.updateStakingTokenAddress(plexusCoin.address);
   
    await plexusOracle.updateRewardAddress(tokenRewards.address);
    await plexusOracle.updateCoreAddress(core.address);
    await plexusOracle.updateTier1Address(tier1Staking.address);

    await core.setOracleAddress(plexusOracle.address);
    await core.setStakingAddress(tier1Staking.address);
    await core.setConverterAddress(wrapper.address);
    await tier1Staking.updateOracleAddress(plexusOracle.address);

    // setup tier 1 staking
    await tier1Staking.addOrEditTier2ChildStakingContract("FARM", tier2Farm.address);
    await tier1Staking.addOrEditTier2ChildStakingContract("DAI", tier2Aave.address);
    await tier1Staking.addOrEditTier2ChildStakingContract("PICKLE", tier2Pickle.address);

    // setup ownership of tier2 contracts ownership
    await tier2Farm.changeOwner(tier1Staking.address);
    await tier2Aave.changeOwner(tier1Staking.address);
    await tier2Pickle.changeOwner(tier1Staking.address);

    // let core1 = await (await Core.deploy()).deployed();
    // await coreProxy.upgradeTo(core1.address);
    // await core1.setProxy(coreProxy.address);
    // core1 = await ethers.getContractAt('Core', coreProxy.address);
    // console.log('#####', await  core.oracleAddress())
    // console.log('#####1', await  core1.oracleAddress())

    console.log('wrapper', wrapper.address)
    console.log('wrapperProxy', wrapperProxy.address)
    console.log('wrapperSushi', wrapperSushi.address)
    console.log('wrapperSushiProxy', wrapperSushiProxy.address)
    console.log('tokenRewards', tokenRewards.address)
    console.log('tokenRewardsProxy', tokenRewardsProxy.address)
    console.log('plexusOracle', plexusOracle.address)
    console.log('plexusOracleProxy', plexusOracleProxy.address)
    console.log('tier1Staking', tier1Staking.address)
    console.log('tier1StakingProxy', tier1StakingProxy.address)
    console.log('core', core.address)
    console.log('coreProxy', coreProxy.address)
    console.log('tier2Farm', tier2Farm.address)
    console.log('tier2FarmProxy', tier2FarmProxy.address)
    console.log('tier2Aave', tier2Aave.address)
    console.log('tier2AaveProxy', tier2AaveProxy.address)
    console.log('tier2Pickle', tier2Pickle.address)
    console.log('tier2PickleProxy', tier2PickleProxy.address)
    console.log('owner', owner.address)

    return [wrapper,
        wrapperProxy,
        wrapperSushi,
        wrapperSushiProxy,
        tokenRewards,
        tokenRewardsProxy,
        plexusOracle,
        plexusOracleProxy,
        tier1Staking,
        tier1StakingProxy,
        core,
        coreProxy,
        tier2Farm,
        tier2FarmProxy,
        tier2Aave,
        tier2AaveProxy,
        tier2Pickle,
        tier2PickleProxy,
        plexusCoin,
        owner,
        addr1];
};

const log = (message, params) =>{
    if(process.env.CONSOLE_LOG === 'true') {
       console.log(message, params);
    }
}

const deployWithProxy = async(contractFactory, proxyFactory, factoryName) => {
    let deployedContract = await (await contractFactory.deploy()).deployed();
    const deployedProxy = await (await proxyFactory.deploy(deployedContract.address)).deployed();
    await deployedContract.setProxy(deployedProxy.address);
    deployedContract = await ethers.getContractAt(factoryName, deployedProxy.address);
    await deployedContract.initialize();
    return [deployedContract, deployedProxy]
}

// const deployWithProxyTest = async(contractFactory, deployedProxy, factoryName, owner) => {
//     let deployedContract = await (await contractFactory.deploy()).deployed();
//     await deployedProxy.upgradeTo(deployedContract.address);
//     await deployedContract.setProxy(deployedProxy.address);
//     deployedContract = await ethers.getContractAt(factoryName, deployedProxy.address);
//     return deployedContract
// }
//
// const setupContractsForProxyTest = async({ wrapperProxy, wrapperSushiProxy, tokenRewardsProxy, plexusOracleProxy, tier1StakingProxy, coreProxy, tier2FarmProxy, tier2AaveProxy, tier2PickleProxy }) => {
//     // get the contract factories
//     const Wrapper = await ethers.getContractFactory('WrapAndUnWrap');
//     const WrapperSushi = await ethers.getContractFactory('WrapAndUnWrapSushi');
//     const TokenRewards = await ethers.getContractFactory('TokenRewards');
//     const PlexusOracle = await ethers.getContractFactory('PlexusOracle');
//     const Tier1Staking = await ethers.getContractFactory('Tier1FarmController');
//     const Core = await ethers.getContractFactory('Core');
//     const Tier2Farm = await ethers.getContractFactory('Tier2FarmController');
//     const Tier2Aave = await ethers.getContractFactory('Tier2AaveFarmController');
//     const Tier2Pickle = await ethers.getContractFactory('Tier2PickleFarmController');
//
//     // then deploy the contracts and wait for them to be mined
//     const wrapper1 = await deployWithProxyTest(Wrapper, wrapperProxy, 'WrapAndUnWrap');
//     const wrapperSushi1 = await deployWithProxyTest(WrapperSushi, wrapperSushiProxy, 'WrapAndUnWrapSushi');
//     const tokenRewards1 = await deployWithProxyTest(TokenRewards, tokenRewardsProxy, 'TokenRewards');
//     const plexusOracle1 = await deployWithProxyTest(PlexusOracle, plexusOracleProxy, 'PlexusOracle');
//     const tier1Staking1 = await deployWithProxyTest(Tier1Staking, tier1StakingProxy, 'Tier1FarmController');
//     const core1 = await deployWithProxyTest(Core, coreProxy, 'Core');
//     const tier2Farm1 = await deployWithProxyTest(Tier2Farm, tier2FarmProxy, 'Tier2FarmController');
//     const tier2Aave1 = await deployWithProxyTest(Tier2Aave, tier2AaveProxy, 'Tier2AaveFarmController');
//     const tier2Pickle1 = await deployWithProxyTest(Tier2Pickle, tier2PickleProxy, 'Tier2PickleFarmController');
//
//     return [wrapper1, wrapperSushi1, tokenRewards1, plexusOracle1, tier1Staking1, core1, tier2Farm1, tier2Aave1, tier2Pickle1];
// };

const mineBlocks = async (numOfBlocks) => {
    while (numOfBlocks > 0) {
        numOfBlocks--;
        await hre.network.provider.request({
          method: "evm_mine",
          params: [],
        });
    }
}

module.exports = { setupContracts, log, mineBlocks }
