const config = require('../config.json');
const fs = require('fs');
let root = {};
let network = 'unknown';

async function main() {
	const addr = config.addresses;

	const netinfo = await ethers.provider.getNetwork();
	console.log('netinfo', netinfo.name);
	network = netinfo.chainId === 1 ? "mainnet" :
			  netinfo.chainId === 42 ? "kovan" :
			  netinfo.chainId === 56 ? "binance" :
			  netinfo.chainId === 137 ? "matic" : 'mainnet';

	const chainId = netinfo.chainId;
	console.log("============================================================");
	console.log("");
	console.log("Deployment Started ...");
	console.log("Deploying on " + network + " (chainId: " + chainId + ") ...");
	console.log("");

	console.log("Getting contract factories ...");
	// get the contract factories
	const OwnableProxy = await ethers.getContractFactory('OwnableProxy');
	const Wrapper = await ethers.getContractFactory('WrapAndUnWrap');
	const WrapperSushi = await ethers.getContractFactory('WrapAndUnWrapSushi');
	

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
			addr.swaps.uniswapRouter[network],
			addr.swaps.uniswapFactory[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		const wrapperSushi = await deployWithProxy(
			WrapperSushi,
			OwnableProxy,
			'WrapAndUnWrapSushi',
			addr.tokens.WETH[network],
			addr.swaps.sushiswapRouter[network],
			addr.swaps.sushiswapFactory[network]
		);
		console.log("WrapperSushi is deployed at: ", wrapperSushi.address);
		
	} else if (network === 'binance') {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.pancakeswapRouter[network],
			addr.swaps.pancakeswapFactory[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

	
	} else if (network === 'matic') {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.quickswapRouter[network],
			addr.swaps.quickswapFactory[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		
	} else {
		const wrapper = await deployWithProxy(
			Wrapper,
			OwnableProxy,
			'WrapAndUnWrap',
			addr.tokens.WETH[network],
			addr.swaps.uniswapRouter[network],
			addr.swaps.uniswapFactory[network]
		);
		console.log("Wrapper is deployed at: ", wrapper.address);

		const wrapperSushi = await deployWithProxy(
			WrapperSushi,
			OwnableProxy,
			'WrapAndUnWrapSushi',
			addr.tokens.WETH[network],
			addr.swaps.sushiswapRouter[network],
			addr.swaps.sushiswapFactory[network]
		);
		console.log("WrapperSushi is deployed at: ", wrapperSushi.address);

	}

	console.log("");
	console.log("Successfully Deployed Wrapper(s)!");
	console.log("============================================================");
}

const deployWithProxy = async(contractFactory, proxyFactory, factoryName, ...params) => {
	let deployedContract = await (await contractFactory.deploy()).deployed();
	console.log('factoryName', factoryName)
	const logicContractAddr = deployedContract.address;
	console.log('address', logicContractAddr);
	await writeAddress(factoryName, deployedContract.address, [])
	const deployedProxy = await (await proxyFactory.deploy(deployedContract.address)).deployed();
	await deployedContract.setProxy(deployedProxy.address);
	deployedContract = await ethers.getContractAt(factoryName, deployedProxy.address);
	await deployedContract.initialize(...params);
	await writeAddress(factoryName + 'Proxy', deployedProxy.address, [logicContractAddr])

	return deployedContract;
}

const writeAddress = async (factoryName, address, args) => {
	root[factoryName] = {}
	root[factoryName][network] = {
		address,
		args
	}

	const json = JSON.stringify(root);
	fs.writeFileSync('addresses.json', json);
}

main()
	.then(() => process.exit(0))
	.catch(error => {
			console.error(error);
			process.exit(1);
	});
