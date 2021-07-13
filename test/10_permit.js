require("dotenv").config();

const { expect } = require('chai');
const { waffle } = require('hardhat');
const provider = waffle.provider;
const abi = require('human-standard-token-abi');
const { ecsign } = require('ethereumjs-util');
const { setupContracts } = require('./helper');
const { BigNumber } = require("ethers");


const TOTAL_SUPPLY = ethers.utils.parseEther("1000000")
const TEST_AMOUNT = ethers.utils.parseEther("10")

const PERMIT_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
);

const getDomainSeparator = (name, chainId, tokenAddress) => {
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
      [
        ethers.utils.keccak256(
          ethers.utils.toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
        ),
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes(name)),
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes('1')),
        chainId,
        tokenAddress
      ]
    )
  );
}

const getApprovalDigest = async (token, approve, nonce, deadline, chainId) => {
  const name = await token.name();
  const DOMAIN_SEPARATOR = getDomainSeparator(name, chainId, token.address);
  return ethers.utils.keccak256(
    ethers.utils.solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        ethers.utils.keccak256(
          ethers.utils.defaultAbiCoder.encode(
            ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
            [PERMIT_TYPEHASH, approve.owner, approve.spender, approve.value, nonce, deadline]
          )
        )
      ]
    )
  );
}

describe('Re-deploying the plexus ecosystem for ERC-20 Permit test', () => {
  let plexusCoin, airdrop, owner, other;
  let chainId;
  let erc20;

  // Deploy and setup the contracts
  before(async () => {
    const { deployedContracts } = await setupContracts();
    plexusCoin = deployedContracts.plexusCoin;
    airdrop = deployedContracts.airdrop;
    const wallets = provider.getWallets();
    owner = wallets[0];
    other = wallets[1];

    const netinfo = await ethers.provider.getNetwork();
    chainId = netinfo.chainId;

    erc20 = new ethers.Contract(plexusCoin.address, abi, provider);

    const amount = ethers.utils.parseEther("100000");
    plexusCoin.transfer(airdrop.address, amount);
  });

  describe('Test PlexusTestCoin for ERC-20 Permit', () => {

    it('name, symbol, decimals, totalSupply, balanceOf, DOMAIN_SEPARATOR, PERMIT_TYPEHASH', async () => {
      const name = await plexusCoin.name();
      expect(name).to.eq('Plexus');
      expect(await plexusCoin.symbol()).to.eq('PLX');
      expect(await plexusCoin.decimals()).to.eq(18);
      expect(await plexusCoin.totalSupply()).to.eq(TOTAL_SUPPLY);
      expect(await plexusCoin.DOMAIN_SEPARATOR()).to.eq(
        getDomainSeparator(name, chainId, plexusCoin.address)
      );
      expect(await plexusCoin.PERMIT_TYPEHASH()).to.eq(PERMIT_TYPEHASH);
    });

    it('permit', async () => {
      const nonce = await plexusCoin.nonces(owner.address);
      const deadline = ethers.constants.MaxUint256;
      const digest = await getApprovalDigest(
        plexusCoin,
        { owner: owner.address, spender: other.address, value: TEST_AMOUNT },
        nonce,
        deadline,
        chainId
      );

      const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(owner.privateKey.slice(2), 'hex'));

      await expect(plexusCoin.permit(owner.address, other.address, TEST_AMOUNT, deadline, v, ethers.utils.hexlify(r), ethers.utils.hexlify(s)))
        .to.emit(plexusCoin, 'Approval')
        .withArgs(owner.address, other.address, TEST_AMOUNT);
      expect(await plexusCoin.allowance(owner.address, other.address)).to.eq(TEST_AMOUNT);
      expect(await plexusCoin.nonces(owner.address)).to.eq(BigNumber.from(1));
    })
  });

});