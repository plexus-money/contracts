const fetch = require('isomorphic-fetch');

const getTokenPricesFromCoingecko = (tokens) => {
    return fetch(
        `https://api.coingecko.com/api/v3/simple/price?ids=${tokens}&vs_currencies=usd`
      ).then((res) => res.json());

}

module.exports = { getTokenPricesFromCoingecko };