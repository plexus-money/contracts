const addresses = require('../addresses.json');
const hre = require("hardhat");

async function main() {
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
		await verifyContract(wrapper, network);
		const wrapperProxy = addresses.WrapAndUnWrapProxy
		await verifyContract(wrapperProxy, network);
		const wrapperSushi = addresses.WrapAndUnWrapSushi
		await verifyContract(wrapperSushi, network);
		const wrapperSushiProxy = addresses.WrapAndUnWrapSushiProxy
		await verifyContract(wrapperSushiProxy, network);


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
