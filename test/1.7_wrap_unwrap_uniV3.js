require("dotenv").config();

const config = require('../config.json');
const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { deployWrappersOnly, log } = require('./helper');
const { toUtf8Bytes } = require("ethers/lib/utils");
const addr = config.addresses;

describe('Deploying the plexus contracts for WrapperUni adding liquidity test', () => {
  let wrapper, owner;
  let netinfo;
  let network = 'unknown';
  let tokenPairAddress = '';
  let daiTokenAddress;
  let sushiTokenAddress;
  let compoundTokenAddress;
  let wethAddress;
  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await deployWrappersOnly();
    wrapper = deployedContracts.wrapperUniV3;
    owner = deployedContracts.owner;
    addr1 = deployedContracts.addr1;
    netinfo = await ethers.provider.getNetwork();
    network = netinfo.chainId === 1 ? "mainnet" :
    netinfo.chainId === 42 ? "kovan" :
    netinfo.chainId === 56 ? "binance" :
    netinfo.chainId === 137 ? "matic" : 'mainnet';
    daiTokenAddress = addr.tokens.DAI[network];
    usdtTokenAddress = addr.tokens.USDT[network];
    usdcTokenAddress = addr.tokens.USDC[network];
    farmTokenAddress = addr.tokens.FARM[network];
    pickleTokenAddress = addr.tokens.PICKLE[network];
    sushiTokenAddress = addr.tokens.SUSHI[network];
    compoundTokenAddress = addr.tokens.COMP[network];
    wethAddress = addr.tokens.WETH[network];
  });

  describe('Test Uni V2 liquidity pool', () => {

      it('Should convert 2 ETH to DAI Token(s) from MakerDao via Uniswap', async () => {

          const zeroAddress = process.env.ZERO_ADDRESS;
          const userSlippageTolerance = config.userSlippageTolerance;
          const daiToken = new ethers.Contract(usdtTokenAddress, abi, provider);

    //       // calculate incentiveId
    const types = ['address', 'uint24', 'address']
    const values = [
        wethAddress,
        3000,
        usdtTokenAddress]
    const encodedKey = ethers.utils.defaultAbiCoder.encode(types, values)
    const incentiveId = ethers.utils.keccak256(encodedKey)

          // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
          const amountPlaceholder = ethers.utils.parseEther(unitAmount)

          // We send 2 ETH to the wrapper for conversion
          let overrides = {
              value: ethers.utils.parseEther("2")
          };

          // Convert the 2 ETH to Dai Token(s)
          const deadline = Math.floor(new Date().getTime() / 1000) + 1000;
          const paths = [wethAddress, usdtTokenAddress];
          const path1= "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000bb8dac17f958d2ee523a2206206994597c13d831ec7"
          
          const path = [incentiveId,incentiveId];
          let wrapParams = {
            sourceToken: zeroAddress,
            destinationTokens: paths,
            paths: path,
            amount: amountPlaceholder,
            minAmounts: [0,0],
            poolFee: 3000,
            tickLower: -87420,
            tickUpper: 73560,
            userSlippageTolerance: userSlippageTolerance,
            deadline: deadline,
          };
          const { status } = await (await wrapper.connect(addr1).wrap(wrapParams,overrides)).wait();
          expect(status).to.equal(1);

          // Check conversion is successful
          if (status === 1) {

              // Check the dai token balance in the contract account
              const daiTokenBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));

              // Check if the conversion is successful and the user has some dai tokens in their wallet
              log("User DAI Token balance AFTER ETH conversion: ", daiTokenBalance);
              expect(daiTokenBalance).to.be.gt(0);

          }
          // Check that the users ETH balance has reduced regardless of the conversion status
          const ethBalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
          log('User ETH balance AFTER ETH conversion is: ', ethBalance);
          expect(ethBalance).to.be.lt(10000);

      });

  });

});