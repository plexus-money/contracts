require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { deployWrappersOnly, log, getAmountOutMin } = require('./helper');
const config = require('../config.json');
const addr = config.addresses;

describe('Deploying the plexus contracts for WrapperSushi Token Swap test', () => {
  let wrapperSushi, owner;
  let netinfo;
  let network = 'unknown';
  let daiTokenAddress;
  let farmTokenAddress;
  let pickleTokenAddress;
  let wethAddress;
  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await deployWrappersOnly();
    wrapperSushi = deployedContracts.wrapperSushi;
    owner = deployedContracts.owner;

    netinfo = await ethers.provider.getNetwork();
    network = netinfo.chainId === 1 ? "mainnet" :
    netinfo.chainId === 42 ? "kovan" :
    netinfo.chainId === 56 ? "binance" :
    netinfo.chainId === 137 ? "matic" : 'mainnet';
    daiTokenAddress = addr.tokens.DAI[network];
    farmTokenAddress = addr.tokens.FARM[network];
    pickleTokenAddress = addr.tokens.PICKLE[network];
    wethAddress = addr.tokens.WETH[network];
  });

  describe('Test Plexus SushiSwap swapping from ETH TO ERC20 tokens', () => {

    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('User wallet balance is greater than 3 ETH', async () => {
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance is ', ethbalance);
        expect(ethbalance).to.be.gt(3);
    });


     // Conversions From ETH
     it('Should convert 2 ETH to Farm token from harvest.finance via SushiSwap', async () => {

        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = config.userSlippageTolerance;
        const erc20 = new ethers.Contract(farmTokenAddress, abi, provider);

        // Please note, the number of farm tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)

        // We send 2 ETH to the wrapper for conversion
        let overrides = {
          value: ethers.utils.parseEther("2")
        };

        // Convert the 2 ETH to Farm Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const path1 = [wethAddress, farmTokenAddress];
        const amountOutMin = await getAmountOutMin(path1, amountPlaceholder, userSlippageTolerance, wrapperSushi, 18);
        const { status } = await (await wrapperSushi.wrap({sourceToken: zeroAddress, destinationTokens: [farmTokenAddress], path1, path2: [], amount: amountPlaceholder, userSlippageToleranceAmounts: [amountOutMin], deadline}, overrides)).wait();

        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check conversion is successful
        if (status === 1) {

           // Check the farm token balance in the contract account
           const userFarmTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(owner.address), `ether`));

           // Check if the conversion is successful and the user has some farm tokens their wallet
           log("User farm token balance AFTER ETH conversion: ", userFarmTokenBalance);
           expect(userFarmTokenBalance).to.be.gt(0);

        }
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethbalance);
        expect(ethbalance).to.be.lt(10000);

      });

      it('Should convert 2 ETH to DAI Token(s) from MakerDao via SushiSwap', async () => {

        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = config.userSlippageTolerance;
        const erc20 = new ethers.Contract(daiTokenAddress, abi, provider);

        // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)

        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };

        // Convert the 2 ETH to Dai Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const path1 = [wethAddress, daiTokenAddress];
        const amountOutMin = await getAmountOutMin(path1, amountPlaceholder, userSlippageTolerance, wrapperSushi, 18);
        const { status } = await (await wrapperSushi.wrap({sourceToken: zeroAddress, destinationTokens: [daiTokenAddress], path1, path2: [], amount: amountPlaceholder, userSlippageToleranceAmounts: [amountOutMin], deadline}, overrides)).wait();

        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check conversion is successful
        if (status === 1) {

           // Check the dai token balance in the contract account
           const userDaiTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(owner.address), `ether`));

           // Check if the conversion is successful and the user has some dai tokens in their wallet
           log("User DAI Token balance AFTER ETH conversion: ", userDaiTokenBalance);
           expect(userDaiTokenBalance).to.be.gt(0);

        }
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethbalance);
        expect(ethbalance).to.be.lt(10000);

      });

      it('Should convert 2 ETH to Pickle Token(s) via SushiSwap', async () => {

        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = config.userSlippageTolerance;
        const erc20 = new ethers.Contract(pickleTokenAddress, abi, provider);

        // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)

        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };

        // Convert the 2 ETH to Pickle Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const path1 = [wethAddress, pickleTokenAddress];
        const amountOutMin = await getAmountOutMin(path1, amountPlaceholder, userSlippageTolerance, wrapperSushi, 18);
        const { status } = await (await wrapperSushi.wrap({sourceToken: zeroAddress, destinationTokens: [pickleTokenAddress], path1, path2: [], amount: amountPlaceholder, userSlippageToleranceAmounts: [amountOutMin], deadline}, overrides)).wait();

        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check conversion is successful
        if (status === 1) {

           // Check the pickle token balance in the contract account
           const userPickleTokenBalance = Number(ethers.utils.formatUnits(await erc20.balanceOf(owner.address), `ether`));

           // Check if the conversion is successful and the user has some pickle tokens in their wallet
           log("User pickle token balance AFTER ETH conversion: ", userPickleTokenBalance);
           expect(userPickleTokenBalance).to.be.gt(0);

        }
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethbalance);
        expect(ethbalance).to.be.lt(10000);

    });

    it('Should revert via Sushi after the deadline has passed', async () => {

      const zeroAddress = process.env.ZERO_ADDRESS;
      const userSlippageTolerance = config.userSlippageTolerance;

      // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
      const amountPlaceholder = ethers.utils.parseEther(unitAmount)

      // We send 2 ETH to the wrapper for conversion
      let overrides = {
          value: ethers.utils.parseEther("2")
      };

      // Check if the txn reverts after it has passed
      const path1 = [wethAddress, pickleTokenAddress];
      const amountOutMin = await getAmountOutMin(path1, amountPlaceholder, userSlippageTolerance, wrapperSushi, 18);
      await expect(wrapperSushi.wrap({sourceToken: zeroAddress, destinationTokens: [pickleTokenAddress], path1, path2: [], amount: amountPlaceholder, userSlippageToleranceAmounts: [amountOutMin], deadline: 10}, overrides))
      .to.be.revertedWith("reverted with reason string 'UniswapV2Router: EXPIRED'");
    });
  });

});