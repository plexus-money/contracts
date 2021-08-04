require("dotenv").config();

const config = require('../config.json');
const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { setupContracts, log } = require('./helper');
const addr = config.addresses;

describe('Re-deploying the plexus contracts for WrapperSushi test', () => {
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;
  let netinfo;
  let network = 'unknown';
  let tokenPairAddress = '';
  let daiTokenAddress;
  let farmTokenAddress;
  let pickleTokenAddress;
  let sushiTokenAddress;
  let compoundTokenAddress;
  let wethAddress;

  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await setupContracts();
    wrapper = deployedContracts.wrapper;
    wrapperSushi = deployedContracts.wrapperSushi;
    tokenRewards = deployedContracts.tokenRewards;
    plexusOracle = deployedContracts.plexusOracle;
    tier1Staking = deployedContracts.tier1Staking;
    core = deployedContracts.core;
    tier2Farm = deployedContracts.tier2Farm;
    tier2Aave = deployedContracts.tier2Aave;
    tier2Pickle = deployedContracts.tier2Pickle;
    plexusCoin = deployedContracts.plexusCoin;
    owner = deployedContracts.owner;
    addr1 = deployedContracts.addr1;

    netinfo = await ethers.provider.getNetwork();
    network = netinfo.chainId === 1 ? "mainnet" :
    netinfo.chainId === 42 ? "kovan" :
    netinfo.chainId === 56 ? "binance" :
    netinfo.chainId === 137 ? "matic" : 'mainnet';
    daiTokenAddress = addr.tokens.DAI[network];
    farmTokenAddress = addr.tokens.FARM[network];
    pickleTokenAddress = addr.tokens.PICKLE[network];
    sushiTokenAddress = addr.tokens.SUSHI[network];
    compoundTokenAddress = addr.tokens.COMP[network];
    wethAddress = addr.tokens.WETH[network];
  });

  describe('Test liquidity pool', () => {

      it('Should convert 2 ETH to DAI Token(s) from MakerDao via SushiSwap', async () => {

          const zeroAddress = process.env.ZERO_ADDRESS;
          const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
          const daiToken = new ethers.Contract(daiTokenAddress, abi, provider);

          // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
          const amountPlaceholder = ethers.utils.parseEther(unitAmount)

          // We send 2 ETH to the wrapperSushi for conversion
          let overrides = {
              value: ethers.utils.parseEther("2")
          };

          // Convert the 2 ETH to Dai Token(s)
          const deadline = Math.floor(new Date().getTime() / 1000) + 10;
          const paths = [[wethAddress, daiTokenAddress]];
          const { status } = await (await wrapperSushi.wrap(zeroAddress, [daiTokenAddress], paths, amountPlaceholder, userSlippageTolerance, deadline, overrides)).wait();

          // Check if the txn is successful
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
          const ethBalance = Number(ethers.utils.formatEther(await owner.getBalance()));
          log('User ETH balance AFTER ETH conversion is: ', ethBalance);
          expect(ethBalance).to.be.lt(10000);

      });

      it('Should create pool(SUSHI-COMPOUND) with DAI via UniswapV2', async () => {
          const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
          let daiToken = new ethers.Contract(daiTokenAddress, abi, provider);

          const initDaiBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));
          log('init DAI balance is: ', initDaiBalance);
          // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
          const amountPlaceholder = await daiToken.balanceOf(owner.address);
          daiToken = await daiToken.connect(owner);
          await daiToken.approve(wrapperSushi.address, amountPlaceholder);
          // Convert the 1000 DAI to SUSHI and COMPOUND, create pool with token pair(SUSHI-COMPOUND)
          const deadline = Math.floor(new Date().getTime() / 1000) + 10;
          log('sushiToken Address', sushiTokenAddress);
          log('compoundToken Address', compoundTokenAddress);
          const paths = [[daiTokenAddress, wethAddress, sushiTokenAddress], [daiTokenAddress, wethAddress, compoundTokenAddress]];
          const { status, events } = await (await wrapperSushi.wrap(daiTokenAddress, [sushiTokenAddress, compoundTokenAddress], paths, amountPlaceholder, userSlippageTolerance, deadline)).wait();
          // Check if the txn is successful
          expect(status).to.equal(1);

          // Check conversion is successful
          if (status === 1) {
              const event = events.find((item)=>{
                  return item.event === "WrapSushi";
              })
              tokenPairAddress = event.args.lpTokenPairAddress;
              log("lpToken pair address: ", tokenPairAddress);

              const lpToken = new ethers.Contract(tokenPairAddress, abi, provider);
              const lpTokenBalance = Number(ethers.utils.formatUnits(await lpToken.balanceOf(owner.address), `ether`));
              log("lpToken balance: ", lpTokenBalance);
              expect(lpTokenBalance).to.be.gt(0);

              // Check that the users DAI balance has reduced regardless of the conversion status
              const daiBalance = Number(ethers.utils.formatEther(await daiToken.balanceOf(owner.address)), `ether`);
              log('User DAI balance AFTER create pool is: ', daiBalance);
              expect(daiBalance).to.be.lt(initDaiBalance);
          }

      });

      it('Should return DAI from pool when upwrap with token pair via SushiSwap', async () => {
          const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
          let daiToken = new ethers.Contract(daiTokenAddress, abi, provider);
          let lpToken = new ethers.Contract(tokenPairAddress, abi, provider);
          lpToken = await lpToken.connect(owner);
          const amountPlaceholder = await lpToken.balanceOf(owner.address);
          await lpToken.approve(wrapperSushi.address, amountPlaceholder);

          // Convert the 1000 DAI to SUSHI and COMPOUND, create pool with token pair(SUSHI-COMPOUND)
          const deadline = Math.floor(new Date().getTime() / 1000) + 10;
          const paths = [[sushiTokenAddress, wethAddress, daiTokenAddress], [compoundTokenAddress, wethAddress, daiTokenAddress]];
          const { status, events } = await (await wrapperSushi.unwrap(tokenPairAddress, daiTokenAddress, tokenPairAddress, paths, amountPlaceholder, userSlippageTolerance, deadline)).wait();

          // Check if the txn is successful
          expect(status).to.equal(1);

          // Check conversion is successful
          if (status === 1) {
              const event = events.find((item)=>{
                  return item.event === "UnWrapSushi";
              })

              const destinationTokenBalance = Number(ethers.utils.formatUnits(event.args.amount, `ether`));
              log("Dai balance after call unwarp function: ", destinationTokenBalance);
              const daiTokenBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));
              // Check if the conversion is successful and the user has some sushi, dai tokens in their wallet
              log("User Dai Token balance AFTER DAI conversion: ", daiTokenBalance);
              expect(destinationTokenBalance).to.equal(daiTokenBalance);
          }
      });
  });

});