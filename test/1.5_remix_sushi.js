require("dotenv").config();

const config = require('../config.json');
const { expect } = require('chai');
const { waffle } = require("hardhat");
const { BigNumber } = require("ethers");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { deployWrappersOnly, log, getAmountOutMin, getUnwrapAmounts, 
  getUnwrapMinAmounts, numberToWei, numberFromWei } 
= require('./helper');
const { getLPTokenDetails } = require('./subgraphs');
const addr = config.addresses;
const DEX = "Sushi";

describe('Deploying the plexus contracts for WrapperSushi SAME-DEX remix test', () => {
  let wrapperSushi, owner;
  let netinfo;
  let network = 'unknown';
  let tokenPairAddress = '';
  let daiTokenAddress;
  let cvxCrvTokenAddress;
  let crvTokenAddress;
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
    wethAddress = addr.tokens.WETH[network];

    cvxCrvTokenAddress = "0x62b9c7356a2dc64a1969e19c23e4f579f9810aa7";
    crvTokenAddress = "0xd533a949740bb3306d119cc777fa900ba034cd52";
  });

  describe('Testing Sushi remixing liquidity', () => {

    it('Should convert 2 ETH to DAI Token(s) from MakerDao via Sushi', async () => {

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
        const path1 = [wethAddress, daiTokenAddress];
        const amountOutMin = await getAmountOutMin(path1, amountPlaceholder, userSlippageTolerance, wrapperSushi, 18);
        const { status } = await (await wrapperSushi.wrap({sourceToken: zeroAddress, destinationTokens: [daiTokenAddress], path1, path2: [], amount: amountPlaceholder, userSlippageToleranceAmounts: [amountOutMin], deadline}, overrides)).wait();

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

    it('Should add liquidity to the (USDC-ETH) sushi pool from DAI in Sushi', async () => {
         // we get the slippage tolerance from the config
         const userSlippageTolerance = config.userSlippageTolerance;

         // initialize the DAI contract
         let daiToken = new ethers.Contract(daiTokenAddress, abi, provider);
       
         // check the users initial DAI balance
         const initDaiBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));
         log('init DAI balance is: ', initDaiBalance);

         // Then we get the DAI balance for the user
         const initDaiBalanceInWei = await daiToken.balanceOf(owner.address);
         log('Init Dai Balance in WEI is : ', initDaiBalanceInWei.toString());
  
         // for this conversion we use the approve function to make sure the contract is approved to do the wrap
         daiToken = await daiToken.connect(owner);
         await daiToken.approve(wrapperSushi.address, initDaiBalanceInWei);

         // Convert the 1000 DAI to ETH-USDC, create pool with token pair(ETH-USDC)
         const deadline =  Date.now() + 1000 * 60 * 10; //10 minutes
         log('WETH Token Address', wethAddress);
         log('USDC Token Address', usdcTokenAddress);

         // The wrap conversion paths
         const path1 = [daiTokenAddress, wethAddress];
         const path2 = [daiTokenAddress, wethAddress, usdcTokenAddress];

         // The slippage tolerance amounts
         const amountOutMin1 = await getAmountOutMin(path1, BigNumber.from(initDaiBalanceInWei).div(2), userSlippageTolerance, wrapperSushi, 18);
         const amountOutMin2 = await getAmountOutMin(path2, BigNumber.from(initDaiBalanceInWei).div(2), userSlippageTolerance, wrapperSushi, 6);

         // Then we do the actual wrap
         const { status, events } = await (await wrapperSushi
          .wrap({sourceToken: daiTokenAddress, destinationTokens: [wethAddress, usdcTokenAddress], 
              path1, path2, amount: initDaiBalanceInWei, userSlippageToleranceAmounts: [amountOutMin1, amountOutMin2], deadline}))
          .wait();
        
         // Check if the txn is successful
         expect(status).to.equal(1);

         // Check conversion is successful
         if (status === 1) {

           // check if the wrap event has been returned
           const event = events.find((item)=>{
               return item.event === "WrapSushi";
           })

           // we get the LP token address
           tokenPairAddress = event.args.lpTokenPairAddress;
           log("(USDC-ETH) LP Token/Pair Address: ", tokenPairAddress);

           // init the LP Token contract
           const lpToken = new ethers.Contract(tokenPairAddress, abi, provider);

           // Then get the balance
           const lpTokenBalance = Number(ethers.utils.formatUnits(await lpToken.balanceOf(owner.address), `ether`));
           log("(USDC-ETH) LP Token balance: ", lpTokenBalance);
           expect(lpTokenBalance).to.be.gt(0);

           // Check that the users DAI balance has reduced if the conversion is successful
           const daiBalance = Number(ethers.utils.formatEther(await daiToken.balanceOf(owner.address)), `ether`);
           log('User DAI balance AFTER create pool is: ', daiBalance);
           expect(daiBalance).to.be.lt(initDaiBalance);
         }

    });

    it('Should do a SAME-DEX remix from the (ETH-USDC) LP Token to the (CRV-CVXCRV) LP Token in Sushi', async () => {
        let lpToken = new ethers.Contract(tokenPairAddress, abi, provider);
        lpToken = await lpToken.connect(owner);
        const lpTokenBalanceinWei = await lpToken.balanceOf(owner.address);
        await lpToken.approve(wrapperSushi.address, lpTokenBalanceinWei);

          // Check that the users initial LP Token balance is greater than zero
        const initialLpToken = new ethers.Contract(tokenPairAddress, abi, provider);
        let initialLpTokenBalance = Number(ethers.utils.formatUnits(await initialLpToken.balanceOf(owner.address), `ether`));
        log("Initial LP Token balance for (ETH-USDC) LP Token is greater than zero: ", initialLpTokenBalance);
        expect(initialLpTokenBalance).to.be.gte(0);


        // first of all we get the LP token price details using the address of a known whale
        const lpTokenDetails = await getLPTokenDetails(DEX, 0.5);
        const lpTokenBalance = Number(ethers.utils.formatUnits(await lpToken.balanceOf(owner.address), `ether`));
        const lpTokenBalanceInUSD = lpTokenBalance * lpTokenDetails.lpTokenPrice;

        log("ETH-USDC LP TOKEN Balance in USD is : ", lpTokenBalanceInUSD);

        // The token ordering MATTERS alot otherwise you'll get alot of funny errors, 
        // when unwrapping because the token ordering is off

        // we get the token prices based on their coingecko id's and their order in the pool
        const token0 = { symbol : 'usd-coin'};
        const token1 = { symbol : 'ethereum'};

        const unwrapAmounts  = await getUnwrapAmounts(lpTokenBalanceInUSD, token0, token1);

        log("Unwrap amounts: ", unwrapAmounts);
        
        // The cross dex remix wrap conversion paths
        const wrapPath1 = [usdcTokenAddress, wethAddress, cvxCrvTokenAddress];
        const wrapPath2 = [wethAddress, crvTokenAddress];

        // The estimated amounts we expect to get from the unwrap
        const { amount1, amount2 } = unwrapAmounts;

        // the minimum amounts we expect from the remove liquidity operation of (USDC-ETH) pool or the txn reverts
        const { amount1Min, amount2Min } = getUnwrapMinAmounts(amount1, amount2, 6, 18);
        const deadline =  Date.now() + 1000 * 60 * 10; //10 minutes
   
        // The wrap slippage tolerance amounts for the constituent tokens in the LP Token
        const slippageAmount1 = numberToWei("0", 18);
        const slippageAmount2 = numberToWei("0", 18);

        // the cvxCRV & CRV token addresses respectively
        const destinationTokens = [cvxCrvTokenAddress, crvTokenAddress];

        // Then we do the actual cross-dex remix from the (ETH-USDC) LP Token in Uni V2 to the (CVXCRV-CRV) LP Token in Sushi
        const { status, events } = await (await wrapperSushi
            .remix({lpTokenPairAddress: tokenPairAddress, destinationTokens, wrapPath1, wrapPath2, 
                  amount: lpTokenBalanceinWei, remixWrapSlippageToleranceAmounts: [slippageAmount1, slippageAmount2],
                  minUnwrapAmounts: [amount1Min, amount2Min], deadline, crossDexRemix: false }))
            .wait();

        // Check if the txn is successful
        expect(status).to.equal(1);

        // Check if remix is successful
        if (status === 1) {

          // check if the wrap event has been returned
          const event = events.find((item)=> {
              return item.event === "LpTokenRemixWrap";
          });
          const newLpTokenAddress = event.args.lpTokenPairAddress;
          const remixedLpTokenAmount = event.args.amount;

          log("New LP TOKEN address is: ", newLpTokenAddress);
          log("Remixed amount in wei is: ", remixedLpTokenAmount.toString());
          log("(CVXCRV-CRV) LP Token Balance is: ",  Number(numberFromWei(remixedLpTokenAmount, 18)));

          // Check that the user has the (CVXCRV-CRV) LP Token and the balance is greater than zero
          expect(tokenPairAddress).is.not.equal(newLpTokenAddress);
          expect(Number(numberFromWei(remixedLpTokenAmount, 18))).to.be.gt( 0);
         
        }
          
    });
   
  });

});