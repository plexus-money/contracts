const config = require('../config.json');
const fs = require('fs');
let root = {};

const deployWrappersOnly = async() => {

    const addr = config.addresses;
    const netinfo = await ethers.provider.getNetwork();

	const network = netinfo.chainId === 1 ? "mainnet" :
			  netinfo.chainId === 42 ? "kovan" :
			  netinfo.chainId === 56 ? "binance" :
			  netinfo.chainId === 137 ? "matic" : 'mainnet';


    // get the contract factories
    const Wrapper = await ethers.getContractFactory('WrapAndUnWrap');
    const WrapperSushi = await ethers.getContractFactory('WrapAndUnWrapSushi');
	const WrapperUniV3 = await ethers.getContractFactory('WrapAndUnWrapUniV3');

    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    let wrapper = await (await Wrapper
        .deploy(addr.tokens.WETH[network], addr.swaps.uniswapRouter[network], addr.swaps.uniswapFactory[network]))
        .deployed();

	await writeAddress('WrapAndUnWrap', wrapper.address, network,
		[addr.tokens.WETH[network], addr.swaps.uniswapRouter[network], addr.swaps.uniswapFactory[network]]);

	let wrapperUniV3 = await (await WrapperUniV3
		.deploy(addr.tokens.WETH[network], addr.swaps.uniswapRouterV3[network], addr.swaps.uniswapFactoryV3[network], addr.swaps.positionManager[network], addr.swaps.quoter[network]))
		.deployed();

	await writeAddress('WrapperUniV3', wrapperUniV3.address, network,
		[addr.tokens.WETH[network], addr.swaps.uniswapRouterV3[network], addr.swaps.uniswapFactoryV3[network], addr.swaps.positionManager[network], addr.swaps.quoter[network]]);

    let wrapperSushi = await (await WrapperSushi
        .deploy(addr.tokens.WETH[network], addr.swaps.sushiswapRouter[network], addr.swaps.sushiswapFactory[network]))
        .deployed();

	await writeAddress('WrapAndUnWrapSushi', wrapperSushi.address, network,
		[addr.tokens.WETH[network], addr.swaps.sushiswapRouter[network], addr.swaps.sushiswapFactory[network]]);

    await (await wrapper.setWrapperSushiAddress(wrapperSushi.address)).wait();
    await (await wrapperSushi.setWrapperUniAddress(wrapper.address)).wait();

}

const writeAddress = async (factoryName, address, network, args) => {
	root[factoryName] = {}
	root[factoryName][network] = {
		address,
		args
	}

	const json = JSON.stringify(root);
	fs.writeFileSync('addresses.json', json);
}

deployWrappersOnly()
	.then(() => process.exit(0))
	.catch(error => {
			console.error(error);
			process.exit(1);
	});
