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
    const WrapperUniV3 = await ethers.getContractFactory('WrapAndUnWrapUniV3');

    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    let wrapper = await (await Wrapper
        .deploy(addr.tokens.WETH[network], addr.swaps.uniswapRouter[network], addr.swaps.uniswapFactory[network]))
        .deployed();
    let wrapperSushi = await (await WrapperSushi
        .deploy(addr.tokens.WETH[network], addr.swaps.sushiswapRouter[network], addr.swaps.sushiswapFactory[network]))
        .deployed();
    let wrapperUniV3 = await (await WrapperUniV3
        .deploy(addr.tokens.WETH[network], addr.swaps.uniswapRouterV3[network], addr.swaps.uniswapFactoryV3[network], addr.swaps.positionManager[network], addr.swaps.quoter[network]))
        .deployed();
        console.log(wrapperUniV3.address);
        
    await (await wrapper.setWrapperSushiAddress(wrapperSushi.address)).wait();
    await (await wrapperSushi.setWrapperUniAddress(wrapper.address)).wait();

    return { deployedContracts: { wrapper, wrapperSushi, wrapperUniV3, owner, addr1, addrs } };

}

const getAmountOutMin = async(paths, amount, userSlippageTolerance, contract, decimals) => {
  const assetAmounts = await contract.getAmountsOut(paths, amount);
  const outputTokenIndex = assetAmounts.length - 1;
  const assetAmount = numberFromWei(assetAmounts[outputTokenIndex].toString(), decimals);
  const getAmountOut = assetAmount * (100 - userSlippageTolerance) / 100;
  const getAmountOutMin = numberToWei(getAmountOut.toString(), decimals);

  return getAmountOutMin;
}

const numberToWei = (number, decimals) => {
  let numberToWei = undefined;
  switch (decimals) {
    case 18:
      numberToWei = ethers.utils.parseUnits(number, `ether`);
      break;
    case 15:
      numberToWei = ethers.utils.parseUnits(number, `finney`);
      break;
    case 12:
      numberToWei = ethers.utils.parseUnits(number, `szabo`);
      break;
    case 9:
      numberToWei = ethers.utils.parseUnits(number, `gwei`);
      break;
    case 6:
      numberToWei = ethers.utils.parseUnits(number, `mwei`);
      break;
    case 3:
      numberToWei = ethers.utils.parseUnits(number, `kwei`);
      break;
    default:
      numberToWei = ethers.utils.parseUnits(number, `wei`);
      break;
  }

  return numberToWei;
}

const numberFromWei = (number, decimals) => {
  let numberFromWei = undefined;

  switch (decimals) {
    case 18:
      numberFromWei = ethers.utils.formatUnits(number, `ether`);
      break;
    case 15:
      numberFromWei = ethers.utils.formatUnits(number, `finney`);
      break;
    case 12:
      numberFromWei = ethers.utils.formatUnits(number, `szabo`);
      break;
    case 9:
      numberFromWei = ethers.utils.formatUnits(number, `gwei`);
      break;
    case 6:
      numberFromWei = ethers.utils.formatUnits(number, `mwei`);
      break;
    case 3:
      numberFromWei = ethers.utils.formatUnits(number, `kwei`);
      break;
    default:
      numberFromWei = ethers.utils.formatUnits(number, `wei`);
      break;
  }

  return numberFromWei;
}

module.exports = {log, deployWrappersOnly, getAmountOutMin }
