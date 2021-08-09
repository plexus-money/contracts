require("dotenv").config();
const hre = require("hardhat");
const config = require('../config.json');

const setupContracts = async() => {

    const addr = config.addresses;

	const netinfo = await ethers.provider.getNetwork();
	var network = netinfo.name;
	if (network === "unknown")
		network = "mainnet";

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
    const LP2LP = await ethers.getContractFactory('LP2LP');
	const Tier2Aggregator = await ethers.getContractFactory('Tier2AggregatorFarmController');
    const Airdrop = await ethers.getContractFactory('Airdrop');

    // plexus reward token
    const PlexusCoin = await ethers.getContractFactory('PlexusTestCoin');

    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    // then deploy the contracts and wait for them to be mined
    const wrapper = await deployWithProxy(
        Wrapper,
        OwnableProxy,
        'WrapAndUnWrap',
		addr.tokens.WETH[network],
		addr.swaps.uniswapRouter[network],
		addr.swaps.uniswapFactory[network]
    );

    const wrapperSushi = await deployWithProxy(
        WrapperSushi,
        OwnableProxy,
        'WrapAndUnWrapSushi',
		addr.tokens.WETH[network],
		addr.swaps.sushiswapRouter[network],
		addr.swaps.sushiswapFactory[network]
    );

    const tokenRewards = await deployWithProxy(
        TokenRewards,
        OwnableProxy,
        'TokenRewards'
    );

    const plexusOracle = await deployWithProxy(
        PlexusOracle,
        OwnableProxy,
        'PlexusOracle',
		addr.swaps.uniswapRouter[network],
		addr.tokens.USDC[network]
    );

    const tier2Farm = await deployWithProxy(
        Tier2Farm,
        OwnableProxy,
        'Tier2FarmController',
		addr.AutoStake[network],
		addr.tokens.FARM[network]
    );

    const tier1Staking = await deployWithProxy(
        Tier1Staking,
        OwnableProxy,
        'Tier1FarmController',
		tier2Farm.address,
		plexusOracle.address
    );

    const core = await deployWithProxy(
        Core,
        OwnableProxy,
        'Core',
		addr.tokens.WETH[network],
		wrapper.address
    );

    const tier2Aave = await deployWithProxy(
        Tier2Aave,
        OwnableProxy,
        'Tier2AaveFarmController',
		addr.AaveLendingPoolV2[network],
		addr.tokens.DAI[network],
		addr.tokens.aDAI[network]
    );

    const tier2Pickle = await deployWithProxy(
        Tier2Pickle,
        OwnableProxy,
        'Tier2PickleFarmController',
		addr.StakingRewards[network],
		addr.tokens.PICKLE[network]
    );

    const lp2lp = await deployWithProxy(
        LP2LP,
        OwnableProxy,
        'LP2LP',
		addr.tokens.vBNT[network]
    );

    const tier2Aggregator = await deployWithProxy(
        Tier2Aggregator,
        OwnableProxy,
        'Tier2AggregatorFarmController',
		addr.tokens.pUNI_V2[network],
		addr.tokens.UNI_V2[network]
    );

    // plexus reward token
    const plexusCoin = await (await PlexusCoin.deploy()).deployed();

    // airdrop
    const airdrop = await deployWithProxy(
        Airdrop,
        OwnableProxy,
        'Airdrop',
		plexusCoin.address,
		[addr1.address, addrs[0].address]
    );

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

    return { deployedContracts: { wrapper,
        wrapperSushi,
        tokenRewards,
        plexusOracle,
        tier1Staking,
        core,
        tier2Farm,
        tier2Aave,
        tier2Pickle,
        lp2lp,
        tier2Aggregator,
        plexusCoin,
        airdrop,
        owner,
        addr1,
        addrs } };
};

const log = (message, params) =>{
    if(process.env.CONSOLE_LOG === 'true') {
       console.log(message, params);
    }
}

const deployWithProxy = async(contractFactory, proxyFactory, factoryName, ...params) => {
    let deployedContract = await (await contractFactory.deploy()).deployed();
    const deployedProxy = await (await proxyFactory.deploy(deployedContract.address)).deployed();
    await deployedContract.setProxy(deployedProxy.address);
    deployedContract = await ethers.getContractAt(factoryName, deployedProxy.address);
    await deployedContract.initialize(...params);
    return deployedContract;
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
