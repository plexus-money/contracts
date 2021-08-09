const addresses = require('../addresses.json');
const hre = require("hardhat");

async function main() {
	const netinfo = await ethers.provider.getNetwork();
	let network = netinfo.name;
	if (network === "unknown")
		network = "mainnet";

	// Verify Wrapper and Wrapper Proxy
	const wrapper = addresses.WrapAndUnWrap
	await verifyContract(wrapper, network);
	const wrapperProxy = addresses.WrapAndUnWrapProxy
	await verifyContract(wrapperProxy, network);
	const wrapperSushi = addresses.WrapAndUnWrapSushi
	await verifyContract(wrapperSushi, network);
	const wrapperSushiProxy = addresses.WrapAndUnWrapSushiProxy
	await verifyContract(wrapperSushiProxy, network);

	console.log("============================================================");
}

async function verifyContract(contractInfo, network) {
	if (contractInfo) {
		const contract = contractInfo[network]
		if (contract) {
			if (contract && contract.address.length > 0) {
				console.log('contractAddress', contract.address)
				console.log('contractArgs', contract.args)
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
