require("dotenv").config();
const config = require('../config.json');

const log = (message, params) =>{
    if(process.env.CONSOLE_LOG === 'true') {
       console.log(message, params);
    }
}

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

    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    let wrapper = await (await Wrapper
        .deploy(addr.tokens.WETH[network], addr.swaps.uniswapRouter[network], addr.swaps.uniswapFactory[network]))
        .deployed();
    let wrapperSushi = await (await WrapperSushi
        .deploy(addr.tokens.WETH[network], addr.swaps.sushiswapRouter[network], addr.swaps.sushiswapFactory[network]))
        .deployed();

    await (await wrapper.setWrapperSushiAddress(wrapperSushi.address)).wait();
    await (await wrapperSushi.setWrapperUniAddress(wrapper.address)).wait();

    return { deployedContracts: { wrapper, wrapperSushi, owner, addr1, addrs } };

}

module.exports = {log, deployWrappersOnly }
