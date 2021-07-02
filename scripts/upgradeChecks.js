const config = require('../config.json');
let network = 'mainnet'

async function main() {
    const addr = config.addresses;

    const netinfo = await ethers.provider.getNetwork();
    network = netinfo.name;
    if (network === "unknown")
        network = "mainnet";

    const chainId = netinfo.chainId;
    console.log("============================================================");
    console.log("");
    console.log("Deployment Started ...");
    console.log("Deploying on " + network + " (chainId: " + chainId + ") ...");
    console.log("");

    console.log("Getting contract factories ...");
    // get the contract factories
    const TokenRewards = await ethers.getContractFactory('TokenRewards');
    const OwnableProxy = await ethers.getContractFactory('OwnableProxy');

    // plexus reward token
    const PlexusCoin = await ethers.getContractFactory('PlexusTestCoin');

    // get the signers
    let owner, addr1;
    [owner, addr1, ...addrs] = await ethers.getSigners();

    const ownerAddress = await owner.getAddress();
    console.log("");
    console.log("Deploying from account: " + ownerAddress);
    console.log("");

    const tokenRewards = await deployWithProxy(
        TokenRewards,
        OwnableProxy,
        'TokenRewards'
    );
    console.log("TokenRewards is deployed at: ", tokenRewards.address);

    const plexusCoin = await (await PlexusCoin.deploy()).deployed();
    console.log("PlexusCoin is deployed at: ", plexusCoin.address);

    console.log("");
    // then setup the contracts
    console.log("Setting up contracts... ");
    await tokenRewards.updateStakingTokenAddress(plexusCoin.address);

    // Get owner
    let prevTokenRewardsProxyOwner = await tokenRewards.owner();
    let prevTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());
    let prevTokenRewardsContractOwner = await prevTokenRewardsContract.owner();

    // Get previous state variables from contracts.
    let prevStakingTokenAddr = await tokenRewards.stakingTokensAddress();
    const tokenAddress = '0x0000000000000000000000000000000000000000';
    await tokenRewards.addTokenToWhitelist(tokenAddress);
    await tokenRewards.updateLPStakingTokenAddress(tokenAddress);
    let prevStakingTokenWhitelistValue = await tokenRewards.getTokenWhiteListValue(tokenAddress);

    // Get addresses of original logic contracts.
    let prevTokenRewardsTarget = await tokenRewards.target();

    // Re-deploy
    await updateContract(TokenRewards, tokenRewards.address, 'TokenRewards');
    let newTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());

    console.log('### The Owner of proxy should be equal to the one of his logic contract ###');
    console.log('>> PrevTokenRewardsProxyOwner', prevTokenRewardsProxyOwner);
    console.log('>> PrevTokenRewardsContractOwner', prevTokenRewardsContractOwner);

    console.log('### The Owner of proxy should remains after updated logic contract ###');
    console.log('>> TokenRewardsProxyOwner ', await tokenRewards.owner());
    console.log('>> PrevTokenRewardsProxyOwner', prevTokenRewardsProxyOwner);

    console.log('### The Owner of proxy should be equal to logic contracts ###');
    console.log('>> PrevTokenRewardsProxyOwner', prevTokenRewardsProxyOwner);
    console.log('>> NewTokenRewardsContractOwner', await newTokenRewardsContract.owner());

    console.log('### Logic contracts from proxies should be different from original logic contracts after reset target of proxies ###');
    console.log('>> TokenRewardsTarget', await tokenRewards.target());
    console.log('>> PrevTokenRewardsTarget', prevTokenRewardsTarget);

    console.log('### Global state variables of original contracts should be preserved in new contracts after redeploy ###');
    console.log('>> StakingTokensAddress', await tokenRewards.stakingTokensAddress());
    console.log('>> PrevStakingTokenAddr', prevStakingTokenAddr);
    console.log('>> TokenWhiteListValue', await tokenRewards.getTokenWhiteListValue(tokenAddress));
    console.log('>> PrevStakingTokenWhitelistValue', prevStakingTokenWhitelistValue);

    await updateContract(TokenRewards, tokenRewards.address, 'TokenRewards');
    newTokenRewardsContract = await ethers.getContractAt("TokenRewards", await tokenRewards.target());

    console.log('### The Owner of proxy should be equal to the one of his logic contract ###');
    console.log('>> PrevTokenRewardsProxyOwner', prevTokenRewardsProxyOwner);
    console.log('>> PrevTokenRewardsContractOwner', prevTokenRewardsContractOwner);

    console.log('### The Owner of proxy should remains after updated logic contract ###');
    console.log('>> TokenRewardsProxyOwner ', await tokenRewards.owner());
    console.log('>> PrevTokenRewardsProxyOwner', prevTokenRewardsProxyOwner);

    console.log('### The Owner of proxy should be equal to logic contracts ###');
    console.log('>> PrevTokenRewardsProxyOwner', prevTokenRewardsProxyOwner);
    console.log('>> NewTokenRewardsContractOwner', await newTokenRewardsContract.owner());

    console.log('### Logic contracts from proxies should be different from original logic contracts after reset target of proxies ###');
    console.log('>> TokenRewardsTarget', await tokenRewards.target());
    console.log('>> PrevTokenRewardsTarget', prevTokenRewardsTarget);

    console.log('### Global state variables of original contracts should be preserved in new contracts after redeploy ###');
    console.log('>> StakingTokensAddress', await tokenRewards.stakingTokensAddress());
    console.log('>> PrevStakingTokenAddr', prevStakingTokenAddr);
    console.log('>> TokenWhiteListValue', await tokenRewards.getTokenWhiteListValue(tokenAddress));
    console.log('>> PrevStakingTokenWhitelistValue', prevStakingTokenWhitelistValue);
}

const deployWithProxy = async(contractFactory, proxyFactory, factoryName, ...params) => {
    let deployedContract = await (await contractFactory.deploy()).deployed();
    const deployedProxy = await (await proxyFactory.deploy(deployedContract.address)).deployed();
    await deployedContract.setProxy(deployedProxy.address);
    deployedContract = await ethers.getContractAt(factoryName, deployedProxy.address);
    await deployedContract.initialize(...params);

    return deployedContract;
}

const updateContract = async(contractFactory, deployedProxyAddr, factoryName) => {
    const deployedProxy = await ethers.getContractAt("OwnableProxy", deployedProxyAddr);
    let deployedContract = await (await contractFactory.deploy()).deployed();
    await deployedProxy.upgradeTo(deployedContract.address);
    await deployedContract.setProxy(deployedProxy.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
