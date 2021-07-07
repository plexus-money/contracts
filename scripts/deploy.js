const config = require('../config.json');
const fs = require('fs');
let root = {};
let network = 'mainnet';

async function main() {
	const addr = config.addresses;

	const netinfo = await ethers.provider.getNetwork();
	network = netinfo.chainId === 1 ? "mainnet" :
			  netinfo.chainId === 42 ? "kovan" :
			  netinfo.chainId === 56 ? "binance" :
			  netinfo.chainId === 137 ? "matic" :
			  "mainnet";

	const chainId = netinfo.chainId;
	console.log("============================================================");
	console.log("");
	console.log("Deployment Started ...");
	console.log("Deploying on " + network + " (chainId: " + chainId + ") ...");
	console.log("");

	console.log("Getting contract factories ...");
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

	const ownerAddress = await owner.getAddress();
	console.log("");
	console.log("Deploying from account: " + ownerAddress);
	console.log("");

	// then deploy the contracts and wait for them to be mined
	if (network === 'mainnet') {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.uniswap[network],
			addr.swaps.uniswapFactory[network],
			addr.tokens.DAI[network],
			addr.tokens.USDT[network],
			addr.tokens.USDC[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		const wrapperSushi = await deployWithProxy(
			WrapperSushi,
			OwnableProxy,
			'WrapAndUnWrapSushi',
			addr.tokens.WETH[network],
			addr.swaps.sushiswap[network],
			addr.swaps.uniswapFactory[network],
			addr.tokens.DAI[network],
			addr.tokens.USDT[network],
			addr.tokens.USDC[network]
		);
		console.log("WrapperSushi is deployed at: ", wrapperSushi.address);

		const tokenRewards = await deployWithProxy(
			TokenRewards,
			OwnableProxy,
			'TokenRewards'
		);
		console.log("TokenRewards is deployed at: ", tokenRewards.address);

		const plexusOracle = await deployWithProxy(
			PlexusOracle,
			OwnableProxy,
			'PlexusOracle',
			addr.swaps.uniswap[network],
			addr.tokens.USDC[network]
		);
		console.log("PlexusOracle is deployed at: ", plexusOracle.address);

		const tier2Farm = await deployWithProxy(
			Tier2Farm,
			OwnableProxy,
			'Tier2FarmController',
			addr.AutoStake[network],
			addr.tokens.FARM[network]
		);
		console.log("Tier2Farm is deployed at: ", tier2Farm.address);

		const tier1Staking = await deployWithProxy(
			Tier1Staking,
			OwnableProxy,
			'Tier1FarmController',
			tier2Farm.address,
			plexusOracle.address
		);
		console.log("Tier1Staking is deployed at: ", tier1Staking.address);

		const core = await deployWithProxy(
			Core,
			OwnableProxy,
			'Core',
			addr.tokens.WETH[network],
			wrapper.address
		);
		console.log("Core is deployed at: ", core.address);

		const tier2Aave = await deployWithProxy(
			Tier2Aave,
			OwnableProxy,
			'Tier2AaveFarmController',
			addr.AaveLendingPoolV2[network],
			addr.tokens.DAI[network],
			addr.tokens.aDAI[network]
		);
		console.log("Tier2Aave is deployed at: ", tier2Aave.address);

		const tier2Pickle = await deployWithProxy(
			Tier2Pickle,
			OwnableProxy,
			'Tier2PickleFarmController',
			addr.StakingRewards[network],
			addr.tokens.PICKLE[network]
		);
		console.log("Tier2Pickle is deployed at: ", tier2Pickle.address);

		const lp2lp = await deployWithProxy(
			LP2LP,
			OwnableProxy,
			'LP2LP',
			addr.tokens.vBNT[network]
		);
		console.log("LP2LP is deployed at: ", lp2lp.address);

		const tier2Aggregator = await deployWithProxy(
			Tier2Aggregator,
			OwnableProxy,
			'Tier2AggregatorFarmController',
			addr.tokens.pUNI_V2[network],
			addr.tokens.UNI_V2[network]
		);
		console.log("Tier2Aggregator is deployed at: ", tier2Aggregator.address);

		const plexusCoin = await (await PlexusCoin.deploy()).deployed();
		console.log("PlexusCoin is deployed at: ", plexusCoin.address);

		// airdrop
		const airdrop = await deployWithProxy(
			Airdrop,
			OwnableProxy,
			'Airdrop',
			plexusCoin.address,
			[addr1.address, addrs[0].address]
		);
		console.log("Airdrop is deployed at: ", airdrop.address);

		console.log("");
		// then setup the contracts
		console.log("Setting up contracts... ");
		await tokenRewards.updateOracleAddress(plexusOracle.address);
		await tokenRewards.updateStakingTokenAddress(plexusCoin.address);

		await plexusOracle.updateRewardAddress(tokenRewards.address);
		await plexusOracle.updateCoreAddress(core.address);
		await plexusOracle.updateTier1Address(tier1Staking.address);

		await core.setOracleAddress(plexusOracle.address);
		await core.setStakingAddress(tier1Staking.address);
		await core.setConverterAddress(wrapper.address);

		await tier1Staking.updateOracleAddress(plexusOracle.address);

		console.log("");
		// setup tier 1 staking
		console.log("Setting up Tier1Staking... ");
		await tier1Staking.addOrEditTier2ChildStakingContract("FARM", tier2Farm.address);
		await tier1Staking.addOrEditTier2ChildStakingContract("DAI", tier2Aave.address);
		await tier1Staking.addOrEditTier2ChildStakingContract("PICKLE", tier2Pickle.address);

		console.log("");
		// setup ownership of tier2 contracts ownership
		console.log("Setting up ownerships of Tier2 contracts... ");
		await tier2Farm.changeOwner(tier1Staking.address);
		await tier2Aave.changeOwner(tier1Staking.address);
		await tier2Pickle.changeOwner(tier1Staking.address);
	} else if (network === 'binance') {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.pancakeswap[network],
			addr.swaps.pancakeswapFactory[network],
			addr.tokens.DAI[network],
			addr.tokens.USDT[network],
			addr.tokens.USDC[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		const tokenRewards = await deployWithProxy(
			TokenRewards,
			OwnableProxy,
			'TokenRewards'
		);
		console.log("TokenRewards is deployed at: ", tokenRewards.address);

		const plexusOracle = await deployWithProxy(
			PlexusOracle,
			OwnableProxy,
			'PlexusOracle',
			addr.swaps.pancakeswap[network],
			addr.tokens.USDC[network]
		);
		console.log("PlexusOracle is deployed at: ", plexusOracle.address);

		const core = await deployWithProxy(
			Core,
			OwnableProxy,
			'Core',
			addr.tokens.WETH[network],
			wrapper.address
		);
		console.log("Core is deployed at: ", core.address);

		const plexusCoin = await (await PlexusCoin.deploy()).deployed();
		console.log("PlexusCoin is deployed at: ", plexusCoin.address);

		// airdrop
		const airdrop = await deployWithProxy(
			Airdrop,
			OwnableProxy,
			'Airdrop',
			plexusCoin.address,
			[addr1.address, addrs[0].address]
		);
		console.log("Airdrop is deployed at: ", airdrop.address);

		console.log("");
		// then setup the contracts
		console.log("Setting up contracts... ");
		await tokenRewards.updateOracleAddress(plexusOracle.address);
		await tokenRewards.updateStakingTokenAddress(plexusCoin.address);

		await plexusOracle.updateRewardAddress(tokenRewards.address);
		await plexusOracle.updateCoreAddress(core.address);
		await plexusOracle.updateTier1Address(tier1Staking.address);

		await core.setOracleAddress(plexusOracle.address);
		await core.setConverterAddress(wrapper.address);
	} else if (network === 'matic') {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.quickswap[network],
			addr.swaps.quickswapFactory[network],
			addr.tokens.DAI[network],
			addr.tokens.USDT[network],
			addr.tokens.USDC[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		const tokenRewards = await deployWithProxy(
			TokenRewards,
			OwnableProxy,
			'TokenRewards'
		);
		console.log("TokenRewards is deployed at: ", tokenRewards.address);

		const plexusOracle = await deployWithProxy(
			PlexusOracle,
			OwnableProxy,
			'PlexusOracle',
			addr.swaps.quickswap[network],
			addr.tokens.USDC[network]
		);
		console.log("PlexusOracle is deployed at: ", plexusOracle.address);

		const core = await deployWithProxy(
			Core,
			OwnableProxy,
			'Core',
			addr.tokens.WETH[network],
			wrapper.address
		);
		console.log("Core is deployed at: ", core.address);

		const plexusCoin = await (await PlexusCoin.deploy()).deployed();
		console.log("PlexusCoin is deployed at: ", plexusCoin.address);

		// airdrop
		const airdrop = await deployWithProxy(
			Airdrop,
			OwnableProxy,
			'Airdrop',
			plexusCoin.address,
			[addr1.address, addrs[0].address]
		);
		console.log("Airdrop is deployed at: ", airdrop.address);

		console.log("");
		// then setup the contracts
		console.log("Setting up contracts... ");
		await tokenRewards.updateOracleAddress(plexusOracle.address);
		await tokenRewards.updateStakingTokenAddress(plexusCoin.address);

		await plexusOracle.updateRewardAddress(tokenRewards.address);
		await plexusOracle.updateCoreAddress(core.address);
		await plexusOracle.updateTier1Address(tier1Staking.address);

		await core.setOracleAddress(plexusOracle.address);
		await core.setConverterAddress(wrapper.address);
	} else {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.uniswap[network],
			addr.swaps.uniswapFactory[network],
			addr.tokens.DAI[network],
			addr.tokens.USDT[network],
			addr.tokens.USDC[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		const wrapperSushi = await deployWithProxy(
			WrapperSushi,
			OwnableProxy,
			'WrapAndUnWrapSushi',
			addr.tokens.WETH[network],
			addr.swaps.sushiswap[network],
			addr.swaps.uniswapFactory[network],
			addr.tokens.DAI[network],
			addr.tokens.USDT[network],
			addr.tokens.USDC[network]
		);
		console.log("WrapperSushi is deployed at: ", wrapperSushi.address);

		const tokenRewards = await deployWithProxy(
			TokenRewards,
			OwnableProxy,
			'TokenRewards'
		);
		console.log("TokenRewards is deployed at: ", tokenRewards.address);

		const plexusOracle = await deployWithProxy(
			PlexusOracle,
			OwnableProxy,
			'PlexusOracle',
			addr.swaps.uniswap[network],
			addr.tokens.USDC[network]
		);
		console.log("PlexusOracle is deployed at: ", plexusOracle.address);

		const tier2Farm = await deployWithProxy(
			Tier2Farm,
			OwnableProxy,
			'Tier2FarmController',
			addr.AutoStake[network],
			addr.tokens.FARM[network]
		);
		console.log("Tier2Farm is deployed at: ", tier2Farm.address);

		const tier1Staking = await deployWithProxy(
			Tier1Staking,
			OwnableProxy,
			'Tier1FarmController',
			tier2Farm.address,
			plexusOracle.address
		);
		console.log("Tier1Staking is deployed at: ", tier1Staking.address);

		const core = await deployWithProxy(
			Core,
			OwnableProxy,
			'Core',
			addr.tokens.WETH[network],
			wrapper.address
		);
		console.log("Core is deployed at: ", core.address);

		const tier2Aave = await deployWithProxy(
			Tier2Aave,
			OwnableProxy,
			'Tier2AaveFarmController',
			addr.AaveLendingPoolV2[network],
			addr.tokens.DAI[network],
			addr.tokens.aDAI[network]
		);
		console.log("Tier2Aave is deployed at: ", tier2Aave.address);

		const tier2Pickle = await deployWithProxy(
			Tier2Pickle,
			OwnableProxy,
			'Tier2PickleFarmController',
			addr.StakingRewards[network],
			addr.tokens.PICKLE[network]
		);
		console.log("Tier2Pickle is deployed at: ", tier2Pickle.address);

		const lp2lp = await deployWithProxy(
			LP2LP,
			OwnableProxy,
			'LP2LP',
			addr.tokens.vBNT[network]
		);
		console.log("LP2LP is deployed at: ", lp2lp.address);

		const tier2Aggregator = await deployWithProxy(
			Tier2Aggregator,
			OwnableProxy,
			'Tier2AggregatorFarmController',
			addr.tokens.pUNI_V2[network],
			addr.tokens.UNI_V2[network]
		);
		console.log("Tier2Aggregator is deployed at: ", tier2Aggregator.address);

		const plexusCoin = await (await PlexusCoin.deploy()).deployed();
		console.log("PlexusCoin is deployed at: ", plexusCoin.address);

		// airdrop
		const airdrop = await deployWithProxy(
			Airdrop,
			OwnableProxy,
			'Airdrop',
			plexusCoin.address,
			[addr1.address, addrs[0].address]
		);
		console.log("Airdrop is deployed at: ", airdrop.address);

		console.log("");
		// then setup the contracts
		console.log("Setting up contracts... ");
		await tokenRewards.updateOracleAddress(plexusOracle.address);
		await tokenRewards.updateStakingTokenAddress(plexusCoin.address);

		await plexusOracle.updateRewardAddress(tokenRewards.address);
		await plexusOracle.updateCoreAddress(core.address);
		await plexusOracle.updateTier1Address(tier1Staking.address);

		await core.setOracleAddress(plexusOracle.address);
		await core.setStakingAddress(tier1Staking.address);
		await core.setConverterAddress(wrapper.address);

		await tier1Staking.updateOracleAddress(plexusOracle.address);

		console.log("");
		// setup tier 1 staking
		console.log("Setting up Tier1Staking... ");
		await tier1Staking.addOrEditTier2ChildStakingContract("FARM", tier2Farm.address);
		await tier1Staking.addOrEditTier2ChildStakingContract("DAI", tier2Aave.address);
		await tier1Staking.addOrEditTier2ChildStakingContract("PICKLE", tier2Pickle.address);

		console.log("");
		// setup ownership of tier2 contracts ownership
		console.log("Setting up ownerships of Tier2 contracts... ");
		await tier2Farm.changeOwner(tier1Staking.address);
		await tier2Aave.changeOwner(tier1Staking.address);
		await tier2Pickle.changeOwner(tier1Staking.address);
	}

	console.log("Write addresses")
	const json = JSON.stringify(root);

	fs.writeFileSync('addresses.json', json);

	console.log("");
	console.log("Successfully Deployed!");
	console.log("============================================================");
}

const deployWithProxy = async(contractFactory, proxyFactory, factoryName, ...params) => {
	let deployedContract = await (await contractFactory.deploy()).deployed();
	await writeAddress(factoryName, deployedContract.address, [])
	const deployedProxy = await (await proxyFactory.deploy(deployedContract.address)).deployed();
	await deployedContract.setProxy(deployedProxy.address);
    deployedContract = await ethers.getContractAt(factoryName, deployedProxy.address);
    await deployedContract.initialize(...params);
	await writeAddress(factoryName + 'Proxy', deployedProxy.address, [])

    return deployedContract;
}

const writeAddress = async (factoryName, address, args) => {
	root[factoryName] = {}
	root[factoryName][network] = {
		address,
		args
	}
}

main()
	.then(() => process.exit(0))
	.catch(error => {
			console.error(error);
			process.exit(1);
	});
