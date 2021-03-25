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
    const Tier2Farm = await ethers.getContractFactory('Tier2FarmController');
    const Tier2Aave = await ethers.getContractFactory('Tier2AaveFarmController');
    const Tier2Pickle = await ethers.getContractFactory('Tier2PickleFarmController');

    // plexus reward token
    const PlexusCoin = await ethers.getContractFactory('PlexusTestCoin');
    
    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    // then deploy the contracts and wait for them to be mined
    const wrapper = await (await Wrapper.deploy()).deployed();
    const wrapperSushi = await (await WrapperSushi.deploy()).deployed();
    const tokenRewards = await (await TokenRewards.deploy()).deployed();
    const plexusOracle = await (await PlexusOracle.deploy()).deployed();
    const tier1Staking = await (await  Tier1Staking.deploy()).deployed();
    const core = await (await Core.deploy()).deployed();
    const tier2Farm = await (await Tier2Farm.deploy()).deployed();
    const tier2Aave = await (await Tier2Aave.deploy()).deployed();
    const tier2Pickle = await (await Tier2Pickle.deploy()).deployed();
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

    return [wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1];
};

const log = (message, params) => {
    if(process.env.CONSOLE_LOG === 'true') {
       console.log(message, params);
    }
}

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
