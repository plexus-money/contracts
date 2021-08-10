const addresses = require('../addresses.json');
const hre = require("hardhat");

async function main() {
	const netinfo = await ethers.provider.getNetwork();
	const netinfo = await ethers.provider.getNetwork();

	console.log('netinfo', netinfo.name);
	const network = netinfo.chainId === 1 ? "mainnet" :
			  netinfo.chainId === 42 ? "kovan" :
			  netinfo.chainId === 56 ? "binance" :
			  netinfo.chainId === 137 ? "matic" : 'mainnet';


	const chainId = netinfo.chainId;
	console.log("============================================================");
	console.log("");
	console.log("Verification Started ...");
	console.log("Verifying contracts on " + network + " (chainId: " + chainId + ") ...");
	console.log("");

	if (network === "mainnet" || network === "kovan") {

		// Verify Wrapper and Wrapper Proxy
		const wrapper = addresses.WrapAndUnWrap
		await verifyContract(wrapper, network)
		const wrapperProxy = addresses.WrapAndUnWrapProxy
		await verifyContract(wrapperProxy, network)
		const wrapperSushi = addresses.WrapAndUnWrapSushi
		await verifyContract(wrapperSushi, network)
		const wrapperSushiProxy = addresses.WrapAndUnWrapSushiProxy
		await verifyContract(wrapperSushiProxy, network)
		const tokenRewards = addresses.TokenRewards
		await verifyContract(tokenRewards, network)
		const tokenRewardsProxy = addresses.TokenRewardsProxy
		await verifyContract(tokenRewardsProxy, network)
		const plexusOracle = addresses.PlexusOracle
		await verifyContract(plexusOracle, network)
		const plexusOracleProxy = addresses.PlexusOracleProxy
		await verifyContract(plexusOracleProxy, network)
		const tier1Staking = addresses.Tier1FarmController
		await verifyContract(tier1Staking, network)
		const tier1StakingProxy = addresses.Tier1FarmControllerProxy
		await verifyContract(tier1StakingProxy, network)
		const core = addresses.Core
		await verifyContract(core, network)
		const coreProxy = addresses.CoreProxy
		await verifyContract(coreProxy, network)
		const tier2Farm = addresses.Tier2FarmController
		await verifyContract(tier2Farm, network)
		const tier2FarmProxy = addresses.Tier2FarmControllerProxy
		await verifyContract(tier2FarmProxy, network)
		const tier2Aave = addresses.Tier2AaveFarmController
		await verifyContract(tier2Aave, network)
		const tier2AaveProxy = addresses.Tier2AaveFarmControllerProxy
		await verifyContract(tier2AaveProxy, network)
		const tier2Pickle = addresses.Tier2PickleFarmController
		await verifyContract(tier2Pickle, network)
		const tier2PickleProxy = addresses.Tier2PickleFarmControllerProxy
		await verifyContract(tier2PickleProxy, network)
		const lP2LP = addresses.LP2LP
		await verifyContract(lP2LP, network)
		const lP2LPProxy = addresses.LP2LPProxy
		await verifyContract(lP2LPProxy, network)
		const tier2Aggregator = addresses.Tier2AggregatorFarmController
		await verifyContract(tier2Aggregator, network)
		const tier2AggregatorProxy = addresses.Tier2AggregatorFarmControllerProxy
		await verifyContract(tier2AggregatorProxy, network)
		const airdrop = addresses.Airdrop
		await verifyContract(airdrop, network)
		const airdropProxy = addresses.airdropProxy
		await verifyContract(airdropProxy, network)

	
		console.log("");
		console.log("Successfully Verified Wrapper(s)!");
		console.log("============================================================");

	} else {
		console.log("Sorry verification is not yet enabled for this network yet!");
	}
}

async function verifyContract(contractInfo, network) {
	if (contractInfo) {
		const contract = contractInfo[network]
		if (contract) {
			if (contract && contract.address.length > 0) {
				console.log('Contract Address', contract.address)
				console.log('Contract Args', contract.args)
				try {
					await hre.run("verify:verify", {
						address: contract.address,
						constructorArguments: contract.args || [],
					});
				} catch (e) {
					console.log(e)
				}
			}
		}
	}
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});
