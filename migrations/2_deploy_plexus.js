const Wrapper = artifacts.require("wrapper");
const TokenRewards = artifacts.require("tokenrewards");
const Oracle = artifacts.require("oracle");
const Tier1Staking = artifacts.require("tier1Staking");
const Core = artifacts.require("core");
const Tier2Farm = artifacts.require("tier2Farm");
const Tier2Aave= artifacts.require("tier2Aave");
const Tier2Aggregator = artifacts.require("tier2Aggregator");
const Tier2Pickle = artifacts.require("tier2Pickle");

module.exports = async (deployer) => {

    // deploy all the contracts
    const wrapper = await deployer.deploy(Wrapper, {overwrite: false});
    const tokenRewards = await deployer.deploy(TokenRewards, {overwrite: false});
    const oracle = await deployer.deploy(Oracle, {overwrite: false});
    const tier1Staking = await deployer.deploy(Tier1Staking, {overwrite: false});
    const core = await deployer.deploy(Core, {overwrite: false});
    await deployer.deploy(Tier2Farm, {overwrite: false});
    await deployer.deploy(Tier2Aave, {overwrite: false});
    await deployer.deploy(Tier2Aggregator, {overwrite: false});
    await deployer.deploy(Tier2Pickle, {overwrite: false});

    // run the setup txns
    const wrapperInstance = await wrapper.deployed();
    const tokenRewardsInstance = await tokenRewards.deployed();
    const oracleInstance = await oracle.deployed();
    const tier1StakingInstance = await tier1Staking.deployed();
    const coreInstance = await core.deployed();

    // setup the needed txns
    await tokenRewardsInstance.updateOracleAddress(oracleInstance.address);

    await oracleInstance.updateRewardAddress(tokenRewardsInstance.address);
    await oracleInstance.updateCoreAddress(coreInstance.address);

    await tier1StakingInstance.updateOracleAddress(oracleInstance.address);

    await coreInstance.setOracleAddress(oracleInstance.address);
    await coreInstance.setStakingAddress(tier1StakingInstance.address);
    await coreInstance.setConverterAddress(wrapperInstance.address);


}; 