require("dotenv").config();

const { expect } = require('chai');
const abi = require('human-standard-token-abi');
const { setupContracts, setupContractsForProxyTest, log } = require('./helper');

describe('Re-deploying the plexus ecosystem for Proxy test', () => {
  // Global test vars
  let wrapper, wrapperSushi, tokenRewards, plexusOracle, tier1Staking, core, tier2Farm, tier2Aave, tier2Pickle, plexusCoin, owner, addr1;

  // Deploy and setup the contracts
  before(async () => {
    [ wrapper,
      wrapperProxy,
      wrapperSushi,
      wrapperSushiProxy,
      tokenRewards,
      tokenRewardsProxy,
      plexusOracle,
      plexusOracleProxy,
      tier1Staking,
      tier1StakingProxy,
      core,
      coreProxy,
      tier2Farm,
      tier2FarmProxy,
      tier2Aave,
      tier2AaveProxy,
      tier2Pickle,
      tier2PickleProxy,
      owner,
      addr1
      ] = await setupContracts();

    [ wrapper1,
      wrapperSushi1,
      tokenRewards1,
      plexusOracle1,
      tier1Staking1,
      core1,
      tier2Farm1,
      tier2Aave1,
      tier2Pickle1,
    ] = await setupContractsForProxyTest({ wrapperProxy, wrapperSushiProxy, tokenRewardsProxy, plexusOracleProxy, tier1StakingProxy, coreProxy, tier2FarmProxy, tier2AaveProxy, tier2PickleProxy, owner, addr1 });
  });

  describe('Test proxy pattern', () => {
    // we'll always need the user ETH balance to be greater than 3 ETH, because we use 2 ETH as the base amount for token conversions e.t.c
    it('Previous variables should be saved after deployed again', async () => {
      expect(await tokenRewards.oracleAddress()).to.equal(await tokenRewards1.oracleAddress());
      expect(await tokenRewards.stakingTokensAddress()).to.equal(await tokenRewards1.stakingTokensAddress());
      expect(await plexusOracle.rewardAddress()).to.equal(await plexusOracle1.rewardAddress());
      expect(await plexusOracle.coreAddress()).to.equal(await plexusOracle1.coreAddress());
      expect(await plexusOracle.tier1Address()).to.equal(await plexusOracle1.tier1Address());
      expect(await core.oracleAddress()).to.equal(await core1.oracleAddress());
      expect(await core.stakingAddress()).to.equal(await core1.stakingAddress());
      expect(await core.converterAddress()).to.equal(await core1.converterAddress());
      expect(await tier1Staking.oracleAddress()).to.equal(await tier1Staking1.oracleAddress());
    });
  });

});