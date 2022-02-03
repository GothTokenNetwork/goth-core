const console = require('console')
const { ethers } = require('hardhat')
const { delay } = require('lodash')

function delay2 (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()
    var options = { gasPrice: 250000000000, gasLimit: 30000000 }

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const addr2Key = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'
    const addr3Key = '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6'
    const addr4Key = '0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a'

    const ownerWallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider)

    console.log('Ownder Address:', owner.address)

    const gothSource = await ethers.getContractFactory('contracts/gothtoken.sol:gothtoken')
    const gothToken = await gothSource.deploy()
    console.log('GOTH Token:', gothToken.address)

    const dustSource = await ethers.getContractFactory('contracts/core/ArcaneDust.sol:ArcaneDust')
    const dustToken = await dustSource.deploy(owner.address)
    console.log("Arcane Dust: ", dustToken.address)

    const gothStakeSource = await ethers.getContractFactory('contracts/core/GothStake.sol:GothStake')
    const gothStake = await gothStakeSource.deploy(gothToken.address, dustToken.address)
    console.log("GOTH Stake: ", gothStake.address)
    await dustToken.connect(ownerWallet).transferOwnership(gothStake.address)

    console.log('--------------------------------------')
    console.log('STAKING GOTH')

    const wallet1 = new ethers.Wallet(addr1Key, ethers.provider);
    const wallet2 = new ethers.Wallet(addr2Key, ethers.provider)
    const wallet3 = new ethers.Wallet(addr3Key, ethers.provider)
    const wallet4 = new ethers.Wallet(addr4Key, ethers.provider)

    await StakeGoth(wallet2, ethers.BigNumber.from('55462878822000000000000000000'), gothToken, gothStake, options)
    await StakeGoth(wallet1, ethers.BigNumber.from('55462878822000000000000000000'), gothToken, gothStake, options)
    await StakeGoth(wallet3, ethers.BigNumber.from('547435354000000000000000000'), gothToken, gothStake, options)
    await StakeGoth(wallet4, ethers.BigNumber.from('85623345000000000000000000'), gothToken, gothStake, options)

    await delay2(5)

    console.log('--------------------------------------')
    console.log('UNSTAKING GOTH')

    await UnstakeGoth(wallet2, gothStake, dustToken, '1474584583000000000000000000', options)
    await UnstakeGoth(wallet1, gothStake, dustToken, await gothStake.balanceOf(wallet1.address), options);
    await UnstakeGoth(wallet3, gothStake, dustToken, await gothStake.balanceOf(wallet3.address), options)
    await UnstakeGoth(wallet4, gothStake, dustToken, await gothStake.balanceOf(wallet4.address), options)

}

async function StakeGoth (wallet, amount, gothToken, gothStake, options) 
{
    console.log('--------------------------------------')
    console.log('ADDRESS:', wallet.address)
    await gothToken.transfer(wallet.address, amount)
    console.log('---] GOTH Balance:', ethers.utils.formatEther(await gothToken.balanceOf(wallet.address)))
    await gothToken.connect(wallet).approve(gothStake.address, amount)
    const gothStakeSigner1 = await gothStake.connect(wallet).stakeGOTH(amount, options)
    console.log('--------------------------------------')
}

async function UnstakeGoth (wallet, gothStake, dustToken, amount, options)
{
    console.log('--------------------------------------')
    console.log('ADDRESS:', wallet.address)
    await gothStake.connect(wallet).unstakeGOTH(amount, options)
    console.log('---] Goth Unstaked:', ethers.utils.formatEther(amount))
    console.log('---] Goth Remaining Staked:', ethers.utils.formatEther(await gothStake.balanceOf(wallet.address)));
    console.log('---] Arcane Dust:', ethers.utils.formatEther(await dustToken.balanceOf(wallet.address)))
    console.log('--------------------------------------')
}

main()