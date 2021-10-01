const config = require('../config.json');

const func = async (hre) => {
	
	const {
		deployments: { deploy },
		getNamedAccounts,
	} = hre;

    const addr = config.addresses;
    const netinfo = await ethers.provider.getNetwork();

	const network = netinfo.chainId === 1 ? "mainnet" :
			  netinfo.chainId === 42 ? "kovan" :
			  netinfo.chainId === 56 ? "binance" :
			  netinfo.chainId === 137 ? "matic" : 'mainnet';

	const chainId = netinfo.chainId;

	console.log("============================================================");
	console.log("");
	console.log("Wrapper Deployment Started ...");
	console.log("Deploying wrappers on " + network + " (chainId: " + chainId + ") ...");
	console.log("");
	console.log("============================================================");
  	const { deployer } = await getNamedAccounts();

    console.log("Deployer Address is " + deployer );

 	await deploy('WrapAndUnWrap', {
		from: deployer,
		args: [addr.tokens.WETH[network], 
			addr.swaps.uniswapRouter[network], 
			addr.swaps.sushiswapRouter[network], 
			addr.swaps.uniswapFactory[network],  
			addr.swaps.sushiswapFactory[network]],
		log: true,
	});

    await deploy('WrapAndUnWrapSushi', {
		from: deployer,
		args: [addr.tokens.WETH[network], 
			addr.swaps.uniswapRouter[network], 
			addr.swaps.sushiswapRouter[network], 
			addr.swaps.uniswapFactory[network],  
			addr.swaps.sushiswapFactory[network]],
		log: true,
	});

	console.log("Deployment DONE! ...");
	console.log("============================================================");
};

module.exports = func;
func.tags = ['Wrappers'];