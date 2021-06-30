const config = require('../config.json');
const addresses = require('../addresses.json');
const hre = require("hardhat");

async function main() {
	const netinfo = await ethers.provider.getNetwork();
	var network = netinfo.name;
	if (network === "unknown")
		network = "mainnet";

	// Verify Wrapper and Wrapper Proxy
	const wrapper = addresses.WrapAndUnWrap
	verifyContract(wrapper, network)
	const wrapperProxy = addresses.WrapAndUnWrapProxy
	verifyContract(wrapperProxy, network)
	const wrapperSushi = addresses.WrapAndUnWrapSushi
	verifyContract(wrapperSushi, network)
	const wrapperSushiProxy = addresses.WrapAndUnWrapSushiProxy
	verifyContract(wrapperSushiProxy, network)
	const tokenRewards = addresses.TokenRewards
	verifyContract(tokenRewards, network)
	const tokenRewardsProxy = addresses.TokenRewardsProxy
	verifyContract(tokenRewardsProxy, network)
	const plexusOracle = addresses.PlexusOracle
	verifyContract(plexusOracle, network)
	const plexusOracleProxy = addresses.PlexusOracleProxy
	verifyContract(plexusOracleProxy, network)
	const tier1Staking = addresses.Tier1FarmController
	verifyContract(tier1Staking, network)
	const tier1StakingProxy = addresses.Tier1FarmControllerProxy
	verifyContract(tier1StakingProxy, network)
	const core = addresses.Core
	verifyContract(core, network)
	const coreProxy = addresses.CoreProxy
	verifyContract(coreProxy, network)
	const tier2Farm = addresses.Tier2FarmController
	verifyContract(tier2Farm, network)
	const tier2FarmProxy = addresses.Tier2FarmControllerProxy
	verifyContract(tier2FarmProxy, network)
	const tier2Aave = addresses.Tier2AaveFarmController
	verifyContract(tier2Aave, network)
	const tier2AaveProxy = addresses.Tier2AaveFarmControllerProxy
	verifyContract(tier2AaveProxy, network)
	const tier2Pickle = addresses.Tier2PickleFarmController
	verifyContract(tier2Pickle, network)
	const tier2PickleProxy = addresses.Tier2PickleFarmControllerProxy
	verifyContract(tier2PickleProxy, network)
	const lP2LP = addresses.LP2LP
	verifyContract(lP2LP, network)
	const lP2LPProxy = addresses.LP2LPProxy
	verifyContract(lP2LPProxy, network)
	const tier2Aggregator = addresses.Tier2AggregatorFarmController
	verifyContract(tier2Aggregator, network)
	const tier2AggregatorProxy = addresses.Tier2AggregatorFarmControllerProxy
	verifyContract(tier2AggregatorProxy, network)

	console.log("============================================================");
}

function verifyContract(contractInfo, network) {
	if (contractInfo) {
		const contract = contractInfo[network]
		if (contract) {
			if (contract && contract.address.length > 0) {
				hre.run("verify:verify", {
					address: contract.address,
					constructorArguments: contract.args || [],
				});
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
