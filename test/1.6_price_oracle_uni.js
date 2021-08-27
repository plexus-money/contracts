require("dotenv").config();

const config = require('../config.json');
const { log } = require('./helper');
const addr = config.addresses;
const { UniswapPriceOracle } = require('../scripts/uniswapPriceOracle');

describe('Re-deploying the plexus contracts for PriceOracleUni test', () => {
  let usdtTokenAddress;
  let daiTokenAddress;
  let wethTokenAddress;
  let uniswapFactoryAddress;
  let network;

  // Deploy and setup the contracts
  before(async () => {
    let netinfo = await ethers.provider.getNetwork();
    network = netinfo.chainId === 1 ? "mainnet" :
    netinfo.chainId === 42 ? "kovan" :
    netinfo.chainId === 56 ? "binance" :
    netinfo.chainId === 137 ? "matic" : 'mainnet';
    wethTokenAddress = addr.tokens.WETH[network];
    usdtTokenAddress = addr.tokens.USDT[network];
    daiTokenAddress = addr.tokens.DAI[network];
    uniswapFactoryAddress = addr.swaps.uniswapFactory[network];
  });

  describe('Test Price from Oracle uniswap ', () => {

    it('Get token price with WETH/USDT', async () => {
      const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_NODE_URL)
      const blockNumber = BigInt(await provider.getBlockNumber()-1);
      const uniFactory = await ethers.getContractAt("IUniswapFactory", uniswapFactoryAddress);
      const pairAddress = await uniFactory.getPair(usdtTokenAddress, wethTokenAddress);
      const uniswapPriceOracle = new UniswapPriceOracle(provider);
      let price = await uniswapPriceOracle.getTokenPrice(BigInt(pairAddress), BigInt(usdtTokenAddress), blockNumber);
      const wethDecimals = 18;
      const denominationDecimals = 6;
      const decimals = (wethDecimals - denominationDecimals);
      price = (Number(price) / 2**112) * 10**decimals;
      log('price', price);
    })
  });

});