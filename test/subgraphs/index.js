const { USER_LP_PAIR_DETAILS } = require('./queries');
const request = require('graphql-request').request;

// The subgraph endpoints
const uniUrl = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2";
const sushiUrl =  "https://api.thegraph.com/subgraphs/name/sushiswap/exchange";

const queryUserLPTokenDetails = async(dex) => {

    try {
      let data = {};

      if (dex === "Uniswap") {
        // UNI ETH/USDC LP TOKEN: https://etherscan.io/address/0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc
        // WHALE ADDRESS: https://etherscan.io/address/0xecaa8f3636270ee917c5b08d6324722c2c4951c7
        const params = { address: "0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc".toLowerCase(), 
                        user: "0xecaa8f3636270ee917c5b08d6324722c2c4951c7".toLowerCase()
                      };
        data = await request(uniUrl, USER_LP_PAIR_DETAILS, params);
      } else {
        // SUSHI ETH/USDC LP TOKEN: https://etherscan.io/address/0x397ff1542f962076d0bfe58ea045ffa2d347aca0
        // WHALE ADDRESS: 0x7aC049b7D78bC930E463709eC5e77855A5DCA4C4
        const params = { 
                        address: "0x397FF1542f962076d0BFE58eA045FfA2d347ACa0".toLowerCase(), 
                        user: "0x7aC049b7D78bC930E463709eC5e77855A5DCA4C4".toLowerCase()
                      };
        data = await request(sushiUrl, USER_LP_PAIR_DETAILS, params);
      }

      if (data.user?.liquidityPositions) return data.user.liquidityPositions[0];
      return null;
    } catch (e) {
      console.log(e);

      return null;
    }
}

const fetchLpTokensDetails = async (dex) => {
    let LpTokenDetails = {};
    try {
        LpTokenDetails = await queryUserLPTokenDetails(dex);
    } catch (e) {
      console.log(e);
    }
    return LpTokenDetails;
};


const getLPTokenDetails = async (
    dex,
    slippagePercentage = 1
  ) => {
    try {

      const { liquidityTokenBalance, pair } = await fetchLpTokensDetails(dex);
      const { reserveUSD, totalSupply } = pair;
      const lpTokenPrice = parseFloat(reserveUSD) / parseFloat(totalSupply);
      const liquidityTokenBalanceInUSD = parseFloat(lpTokenPrice) * parseFloat(liquidityTokenBalance);
      const proccesedLiquidityTokenBalanceInUSD = liquidityTokenBalanceInUSD * (1 - slippagePercentage / 100);
     
      return {
        proccesedLiquidityTokenBalanceInUSD, //lp token balance in USD with slippage
        liquidityTokenBalanceInUSD, //lp token balance in USD without slippage
        liquidityTokenBalance, // lp token amount
        lpTokenPrice, // lp token price
        totalSupply
      };
    } catch (e) {
      console.log(e);
      return {
        error: `Error calculation of Lp Token Price`,
      };
    }
};

module.exports = { getLPTokenDetails };
