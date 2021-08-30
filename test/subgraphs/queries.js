const { gql } =  require('graphql-request');

const USER_LP_PAIR_DETAILS =  gql`
  query lpPositions($user: String,$address: String) {
    user (id: $user) {
      liquidityPositions (where: { pair: $address }){
        id,
        liquidityTokenBalance,
        pair {
          id,
          token0 {
            id,
            name,
            symbol
          },
          token1 {
            id,
            name,
            symbol
          },
          volumeUSD,
          reserve0,
          reserve1,
          totalSupply,
          reserveETH,
          reserveUSD,
          token0Price,
          token1Price
        }
      }
    }
  }
`; 

module.exports = { USER_LP_PAIR_DETAILS };