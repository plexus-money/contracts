require("dotenv").config();

const config = require('../config.json');
const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { deployWrappersOnly, log } = require('./helper');
const addr = config.addresses;

describe('Re-deploying the plexus contracts for WrapperSushi remix test', () => {
  let wrapperSushi, owner, addr1;
  let netinfo;
  let network = 'unknown';
  let tokenPairAddress = '';
  let daiTokenAddress;
  let sushiTokenAddress;
  let compoundTokenAddress;
  let wethAddress;
  let usdcTokenAddress;

  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await deployWrappersOnly();
    wrapperSushi = deployedContracts.wrapperSushi;
    owner = deployedContracts.owner;
    addr1 = deployedContracts.addr1;

    netinfo = await ethers.provider.getNetwork();
    network = netinfo.chainId === 1 ? "mainnet" :
    netinfo.chainId === 42 ? "kovan" :
    netinfo.chainId === 56 ? "binance" :
    netinfo.chainId === 137 ? "matic" : 'mainnet';
    daiTokenAddress = addr.tokens.DAI[network];
    usdcTokenAddress = addr.tokens.USDC[network];
    sushiTokenAddress = addr.tokens.SUSHI[network];
    compoundTokenAddress = addr.tokens.COMP[network];
    wethAddress = addr.tokens.WETH[network];
  });

  describe('Testing Sushi remixing liquidity', () => {

      it('Should convert 2 ETH to DAI Token(s) from MakerDao via SushiSwap', async () => {

          const zeroAddress = process.env.ZERO_ADDRESS;
          const userSlippageTolerance = config.userSlippageTolerance;
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
          const userSlippageTolerance = config.userSlippageTolerance;
          let daiToken = new ethers.Contract(daiTokenAddress, abi, provider);

          const initDaiBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));
          log('init DAI balance is: ', initDaiBalance);
          // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
          const amountPlaceholder = await daiToken.balanceOf(owner.address);
          daiToken = await daiToken.connect(owner);
          await daiToken.approve(wrapperSushi.address, amountPlaceholder);
          // Convert the 1000 DAI to SUSHI and COMPOUND, create pool with token pair(SUSHI-COMPOUND)
          const deadline = Math.floor(new Date().getTime() / 1000) + 10;
          log('Sushi Token Address', sushiTokenAddress);
          log('Compound Token Address', compoundTokenAddress);
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

       it('Should remix the (SUSHI-COMPOUND) LP Token to the (ETH-USDC) LP Token in SUSHI', async () => {
            const userSlippageTolerance = config.userSlippageTolerance;
            let lpToken = new ethers.Contract(tokenPairAddress, abi, provider);
            lpToken = await lpToken.connect(owner);
            const amountPlaceholder = await lpToken.balanceOf(owner.address);
            await lpToken.approve(wrapperSushi.address, amountPlaceholder);

            // Check that the users initial LP Token balance is greater than zero
            const initialLpToken = new ethers.Contract(tokenPairAddress, abi, provider);
            let initialLpTokenBalance = Number(ethers.utils.formatUnits(await initialLpToken.balanceOf(owner.address), `ether`));
            log("Initial LP Token balance for (SUSHI-COMPOUND) is greater than zero: ", initialLpTokenBalance);
            expect(initialLpTokenBalance).to.be.gte(0);

            // Remix the (SUSHI-COMPOUND) LP Token to (ETH-USDC) in Sushi
            const deadline = Math.floor(new Date().getTime() / 1000) + 10;
            const unwrapPath1 = [sushiTokenAddress, wethAddress, daiTokenAddress]
            const unwrapPath2 = [compoundTokenAddress, wethAddress, daiTokenAddress];

            // for sushi because the DAI-USDC pair has low liquidity, we have to go through WETH for the second path
            const wrapPath1 = [daiTokenAddress, wethAddress];
            const wrapPath2 = [daiTokenAddress, wethAddress, usdcTokenAddress];
            const outputToken = daiTokenAddress;
            const destinationTokens = [wethAddress, usdcTokenAddress];
            const crossDex = false;
            const { status, events } = await (await wrapperSushi
                .remix({lpTokenPairAddress: tokenPairAddress, unwrapOutputToken: outputToken, destinationTokens, unwrapPath1, unwrapPath2, wrapPath1, wrapPath2, amount: amountPlaceholder, userSlippageTolerance, deadline, crossDexRemix: crossDex}))
                .wait();

            // Check if the txn is successful
            expect(status).to.equal(1);

            // Check conversion is successful
            if (status === 1) {
                const event = events.find((item)=>{
                    return item.event === "RemixWrap";
                })
                const remixedTokenPairAddress = event.args.lpTokenPairAddress;
                log("Remixed LP Token pair address for (ETH-USDC): ", remixedTokenPairAddress);

                const lpToken = new ethers.Contract(remixedTokenPairAddress, abi, provider);
                const lpTokenBalance = Number(ethers.utils.formatUnits(await lpToken.balanceOf(owner.address), `ether`));
                log("Remixed LP Token balance for (ETH-USDC): ", lpTokenBalance);
                expect(lpTokenBalance).to.be.gt(0);

                // Check that the users initial LP Token balance is zero
                initialLpTokenBalance = Number(ethers.utils.formatUnits(await initialLpToken.balanceOf(owner.address), `ether`));
                log("Final LP Token balance for (SUSHI-COMPOUND) should be zero after remix: ", initialLpTokenBalance);
                expect(initialLpTokenBalance).to.be.lte(0);
            }

        });
  });

});