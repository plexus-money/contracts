require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const config = require('../config.json');
const abi = require('human-standard-token-abi');
const { setupContracts, log, getMaxTick, getMinTick } = require('./helper');
const { FeeAmount, TICK_SPACINGS } = require('./constants');
const abiPositionManager = require('../artifacts/contracts/interfaces/uniswap/v3/INonfungiblePositionManager.sol/INonfungiblePositionManager.json').abi;

describe('Re-deploying the plexus contracts for Wrapper test', () => {
  let wrapper, wrapperV3, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;

  const farmTokenAddress = process.env.FARM_TOKEN_MAINNET_ADDRESS;
  const daiTokenAddress = process.env.DAI_TOKEN_MAINNET_ADDRESS;
  const pickleTokenAddress = process.env.PICKLE_TOKEN_MAINNET_ADDRESS;

  const unitAmount = "2";

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await setupContracts();
    wrapper = deployedContracts.wrapper;
    wrapperV3 = deployedContracts.wrapperV3;
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
  });

  describe('Test Plexus Uniswap wrapper', () => {

    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('User wallet balance is greater than 3 ETH', async () => {
        const ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        log('User ETH balance is ', ethbalance);
        expect(ethbalance).to.be.gt(3);
    });

     // Conversions From ETH
     it('Should convert 2 ETH to Farm token from harvest.finance via Uniswap', async () => {
     
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(farmTokenAddress, abi, provider);
     
        // Please note, the number of farm tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
     
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
          value: ethers.utils.parseEther("2")
        };
     
        // Convert the 2 ETH to Farm Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const { status } = await (await wrapper.wrap(zeroAddress, [farmTokenAddress], amountPlaceholder, userSlippageTolerance, deadline, overrides)).wait();
  
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

      it('Should convert 2 ETH to Farm token from harvest.finance via UniswapV3', async () => {

          const zeroAddress = process.env.ZERO_ADDRESS;
          const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
          const erc20 = new ethers.Contract(farmTokenAddress, abi, provider);

          // Please note, the number of farm tokens we want to get doesn't matter, so the unit amount is just a placeholder
          const amountPlaceholder = ethers.utils.parseEther(unitAmount)

          // We send 2 ETH to the wrapper for conversion
          let overrides = {
              value: ethers.utils.parseEther("2")
          };

          // Convert the 2 ETH to Farm Token(s)
          const deadline = Math.floor(new Date().getTime() / 1000) + 10;
          const { status } = await (await wrapperV3.wrapV3(zeroAddress, [farmTokenAddress], amountPlaceholder, userSlippageTolerance, 0, 0, 0, deadline, overrides)).wait();

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

      it('Should convert 2 ETH to DAI Token(s) from MakerDao via Uniswap', async () => {
      
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(daiTokenAddress, abi, provider);
      
        // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
      
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
      
        // Convert the 2 ETH to Dai Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const { status } = await (await wrapper.wrap(zeroAddress, [daiTokenAddress], amountPlaceholder, userSlippageTolerance, deadline, overrides)).wait();
      
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

      it('Should convert 2 ETH to DAI Token(s) from MakerDao via UniswapV3', async () => {
      
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(daiTokenAddress, abi, provider);
      
        // Please note, the number of dai tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
      
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
      
        // Convert the 2 ETH to Dai Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const { status } = await (await wrapperV3.wrapV3(zeroAddress, [daiTokenAddress], amountPlaceholder, userSlippageTolerance, 0, 0, 0, deadline, overrides)).wait();
      
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

      it('Should convert 2 ETH to Pickle Token(s) via Uniswap', async () => {
      
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(pickleTokenAddress, abi, provider);
      
        // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
      
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
      
        // Convert the 2 ETH to Pickle Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const { status } = await (await wrapper.wrap(zeroAddress, [pickleTokenAddress], amountPlaceholder, userSlippageTolerance, deadline, overrides)).wait();
  
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
  
      it('Should revert via Uniswap after the deadline has passed', async () => {
  
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
  
        // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
     
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
        
        // Check if the txn reverts after it has passed
        await expect(wrapper.wrap(zeroAddress, [pickleTokenAddress], amountPlaceholder, userSlippageTolerance, 10, overrides)).to.be.revertedWith("revert UniswapV2Router: EXPIRED");
      });

      it('Should convert 2 ETH to Pickle Token(s) via UniswapV3', async () => {
      
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
        const erc20 = new ethers.Contract(pickleTokenAddress, abi, provider);
      
        // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
      
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
      
        // Convert the 2 ETH to Pickle Token(s)
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const { status } = await (await wrapperV3.wrapV3(zeroAddress, [pickleTokenAddress], amountPlaceholder, userSlippageTolerance, 0, 0, 0, deadline, overrides)).wait();
      
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

      it('Should create pool(DAI:PICKLE) with 2 ETH via UniswapV3', async () => {
      
        const zeroAddress = process.env.ZERO_ADDRESS;
        const userSlippageTolerance = process.env.SLIPPAGE_TOLERANCE;
      
        // Please note, the number of pickle tokens we want to get doesn't matter, so the unit amount is just a placeholder
        const amountPlaceholder = ethers.utils.parseEther(unitAmount)
      
        // We send 2 ETH to the wrapper for conversion
        let overrides = {
             value: ethers.utils.parseEther("2")
        };
      
        const tickUpper = getMaxTick(TICK_SPACINGS.MEDIUM);
        const tickLower = getMinTick(TICK_SPACINGS.MEDIUM);
        const fee = FeeAmount.MEDIUM;
        let ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
        console.log("-----Begin wrapv3 test-----");
        log("User ETH balance BEFORE add liquidity: ", ethbalance);
        const deadline = Math.floor(new Date().getTime() / 1000) + 10;
        const tx = await (await wrapperV3.wrapV3(zeroAddress, 
          [daiTokenAddress, pickleTokenAddress], 
          amountPlaceholder, 
          userSlippageTolerance, 
          tickLower, 
          tickUpper, 
          fee, 
          deadline, 
          overrides
          )).wait();
        
        expect(tx.status).to.equal(1);
        if (tx.status === 1) {
          ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
          log("User ETH balance AFTER add liquidity: ", ethbalance);

          let erc20 = new ethers.Contract(daiTokenAddress, abi, provider);
          const daiTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(owner.address)));
          erc20 = new ethers.Contract(pickleTokenAddress, abi, provider);
          const pickleTokenBalance = Number(ethers.utils.formatEther(await erc20.balanceOf(owner.address)));
          const event = tx.events.find((item)=>{
            return item.event === "WrapV3";
          })
          const lpTokenId = event.args.tokenId;
          const liquidity = event.args.liquidity;
          log("User dai token balance, AFTER added liquidity: ", daiTokenBalance);
          log("User pickle token balance, AFTER added liquidity: ", pickleTokenBalance);
          log("LP TokenID: ", lpTokenId.toString());
          log("Liquidity: ", liquidity.toString());
          const netinfo = await ethers.provider.getNetwork();
          var network = netinfo.name;
          if (network === "unknown")
            network = "mainnet";
          const addr = config.addresses;
          const positionManagerContractAddr = addr.swaps.uniswapNonfungiblePositionManager[network];
          let erc721 = new ethers.Contract(positionManagerContractAddr, abiPositionManager, provider);
          const address = await erc721.ownerOf(lpTokenId);
          expect(address).to.equal(owner.address);
          console.log("-----End wrapv3 test-----");

          console.log("-----Begin unwrapv3 test-----");
          erc721 = await erc721.connect(owner);
          await erc721.approve(wrapperV3.address, lpTokenId);
          const deadline = Math.floor(new Date().getTime() / 1000) + 10;
          await (await wrapperV3.unwrapV3(lpTokenId, zeroAddress, zeroAddress, liquidity, userSlippageTolerance, deadline)).wait();
          ethbalance = Number(ethers.utils.formatEther(await owner.getBalance()));
          log("User ETH balance AFTER removed liquidity: ", ethbalance);
        }
      });
  });
});