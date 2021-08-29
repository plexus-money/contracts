require("dotenv").config();

const config = require('../config.json');
const { expect } = require('chai');
const { waffle } = require("hardhat");
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { deployWrappersOnly, log } = require('./helper');
const { toUtf8Bytes } = require("ethers/lib/utils");
const addr = config.addresses;
const { Pool, nearestUsableTick, Position } = require('@uniswap/v3-sdk');
const { Token } = require('@uniswap/sdk-core');
const abi_uniswap = require('./abis/uniswapV3Pool.json');
const abi_position_manager = require('./abis/positionManager.json');
const poolAddress = "0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36";
const poolImmutablesAbi = [
  "function factory() external view returns (address)",
  "function token0() external view returns (address)",
  "function token1() external view returns (address)",
  "function fee() external view returns (uint24)",
  "function tickSpacing() external view returns (int24)",
  "function maxLiquidityPerTick() external view returns (uint128)",
];

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

  async function getPoolImmutables(poolContract) {
    const PoolImmutables = {
      factory: await poolContract.factory(),
      token0: await poolContract.token0(),
      token1: await poolContract.token1(),
      fee: await poolContract.fee(),
      tickSpacing: await poolContract.tickSpacing(),
      maxLiquidityPerTick: await poolContract.maxLiquidityPerTick(),
    };
    console.log(PoolImmutables);
    return PoolImmutables;
  }

  async function getPoolState(poolContract) {
    const [liquidity, slot] = await Promise.all([
      poolContract.liquidity(),
      poolContract.slot0(),
    ]);

    const PoolState = {
      liquidity,
      sqrtPriceX96: slot[0],
      tick: slot[1],
      observationIndex: slot[2],
      observationCardinality: slot[3],
      observationCardinalityNext: slot[4],
      feeProtocol: slot[5],
      unlocked: slot[6],
    };
    console.log(PoolState);
    return PoolState;
  }


  describe('Test Uni V2 liquidity pool', () => {

    it('Should convert 2 ETH to USDT Token(s) from MakerDao via Uniswap', async () => {

      const zeroAddress = process.env.ZERO_ADDRESS;
      const userSlippageTolerance = config.userSlippageTolerance;
      const daiToken = new ethers.Contract(usdtTokenAddress, abi, provider);
      const poolContract = new ethers.Contract(
        poolAddress,
        abi_uniswap,
        provider
      );
      const positionManager_contract = new ethers.Contract(
        addr.swaps.positionManager.mainnet,
        abi_position_manager,
        provider
      );
      const [immutables, state] = await Promise.all([
        getPoolImmutables(poolContract),
        getPoolState(poolContract),
      ]);
      const TokenB = new Token(3, immutables.token0, 6, "USDT", "USD Tether");

      const TokenA = new Token(3, immutables.token1, 18, "WETH", "Wrapped Ether");

      const poolExample = new Pool(
        TokenA,
        TokenB,
        immutables.fee,
        state.sqrtPriceX96.toString(),
        state.liquidity.toString(),
        state.tick
      );
      console.log(poolExample);
      const tickLower = nearestUsableTick(state.tick, immutables.tickSpacing) - immutables.tickSpacing * 2;
      const tickUpper = nearestUsableTick(state.tick, immutables.tickSpacing) + immutables.tickSpacing * 2;
      console.log("tick lower %s - tick Upper %s", tickLower, tickUpper);
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
      const path = [incentiveId, incentiveId];
      let wrapParams = {
        sourceToken: zeroAddress,
        destinationTokens: paths,
        paths: path,
        amount: amountPlaceholder,
        minAmounts: [0, 3019546166],
        poolFee: 3000,
        tickLower: tickLower,
        tickUpper: tickUpper,
        userSlippageTolerance: userSlippageTolerance,
        deadline: deadline,
      };
      const { status } = await (await wrapper.connect(addr1).wrap(wrapParams, overrides)).wait();
      expect(status).to.equal(1);

      // Check conversion is successful
      if (status === 1) {

        // Check the dai token balance in the contract account
        const daiTokenBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));

        // Check if the conversion is successful and the user has some dai tokens in their wallet
        log("User USDT Token balance AFTER ETH conversion: ", daiTokenBalance);
        expect(daiTokenBalance).to.be.gt(0);
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethBalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
        log('User ETH balance AFTER ETH conversion is: ', ethBalance);
      }
      const valuesForUnwrap2 = [
        usdtTokenAddress,
        3000,
        wethAddress]
      const valuesForUnwrap1 = [
        wethAddress,
        3000,
        wethAddress]
      const encodedKey2 = ethers.utils.defaultAbiCoder.encode(types, valuesForUnwrap2)
      const incentiveId2 = ethers.utils.keccak256(encodedKey2)
      console.log(incentiveId2);
      const encodedKey1 = ethers.utils.defaultAbiCoder.encode(types, valuesForUnwrap1)
      const incentiveId1 = ethers.utils.keccak256(encodedKey1)
      await hre.network.provider.send("hardhat_setBalance", [wrapper.address, "0xDE0B6B3A7640000",]);
      let unwrapParams = {
        tokenId: 108575,
        destinationToken: zeroAddress,
        paths: [incentiveId1, "0xdac17f958d2ee523a2206206994597c13d831ec7000bb8c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"],
        amount: amountPlaceholder,
        userSlippageTolerance: userSlippageTolerance,
        deadline: deadline,
      };
      await positionManager_contract.connect(addr1).approve(wrapper.address, 108575);
      const { status1 } = await (await wrapper.connect(addr1).unwrap(unwrapParams)).wait();
        // Check the usdt token balance in the contract account
        const daiTokenBalance = Number(ethers.utils.formatUnits(await daiToken.balanceOf(owner.address), `ether`));

        // Check if the conversion is successful and the user has some usdt tokens in their wallet
        log("User USDT Token balance AFTER unwrap to ETH conversion: ", daiTokenBalance);
        // Check that the users ETH balance has reduced regardless of the conversion status
        const ethBalance = Number(ethers.utils.formatEther(await addr1.getBalance()));
        log('User ETH balance AFTER unwraping to ETH is: ', ethBalance);
        expect(ethBalance).to.be.lt(10001);
    });

  });

});