require("dotenv").config();
const config = require('../config.json');
const { getTokenPricesFromCoingecko } = require('./api')

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
        .deploy(addr.tokens.WETH[network], 
          addr.swaps.uniswapRouter[network], 
          addr.swaps.sushiswapRouter[network], 
          addr.swaps.uniswapFactory[network],  
          addr.swaps.sushiswapFactory[network]))
        .deployed();
    let wrapperSushi = await (await WrapperSushi
        .deploy(addr.tokens.WETH[network], 
          addr.swaps.uniswapRouter[network], 
          addr.swaps.sushiswapRouter[network], 
          addr.swaps.uniswapFactory[network],  
          addr.swaps.sushiswapFactory[network]))
        .deployed();

    return { deployedContracts: { wrapper, wrapperSushi, owner, addr1, addrs } };

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

const getAmountOutMin = async(paths, amount, userSlippageTolerance, contract, decimals) => {
 
  const assetAmounts = await contract.getAmountsOut(paths, amount);
  const outputTokenIndex = assetAmounts.length - 1;
  const assetAmount = numberFromWei(assetAmounts[outputTokenIndex].toString(), decimals);
  const amountOut = (assetAmount * (100 - userSlippageTolerance) / 100).toFixed(3);
  const amountOutMin = numberToWei(amountOut.toString(), decimals);

  return amountOutMin;
}

const getUnwrapAmounts = async(lpTokenBalanceInUSD, token1, token2) => {

  // first we get the token price from coingecko via their api
  const tokens = token1.symbol + ',' + token2.symbol;
  const tokenPrices = await getTokenPricesFromCoingecko(tokens);
  const unwrapAmountUSD = lpTokenBalanceInUSD / 2;
  const amount1 = (unwrapAmountUSD / tokenPrices[token1.symbol].usd).toFixed(6);
  const amount2 = (unwrapAmountUSD / tokenPrices[token2.symbol].usd).toFixed(6);

  return { amount1, amount2 };
}

const getUnwrapMinAmounts = (amount1, amount2, decimals1, decimals2) => {
  // we set a default 15% minimum amount that can be returned for both pool tokens
  const a1 = (amount1 * (100 - 15) / 100).toFixed(4);
  const a2 = (amount2 * (100 - 15) / 100).toFixed(4);

  const amount1Min = numberToWei(a1, decimals1);
  const amount2Min = numberToWei(a2, decimals2);

  return { amount1Min, amount2Min};

}

module.exports = {log, deployWrappersOnly, getAmountOutMin, getUnwrapAmounts, numberToWei, numberFromWei, getUnwrapMinAmounts  }
