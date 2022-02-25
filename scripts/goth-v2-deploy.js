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

    const newGothBytecode = ''
    const newGothABI = ''

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const ownerWallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider)
    const testWallet = new ethers.Wallet(addr1Key, ethers.provider);

    console.log('Owner Address:', owner.address)

    const gothSource = await ethers.getContractFactory('contracts/gothtoken.sol:gothtoken')
    const gothTokenOld = await gothSource.deploy()
    console.log('GOTH Token Old:', gothTokenOld.address)  

    const gothV2ExchangeSource = await ethers.getContractFactory('contracts/gothV2Exchange.sol:gothV2Exchange')
    const gothV2Exchange = await gothV2ExchangeSource.deploy(gothTokenOld.address,'0x0000000000000000000000000000000000000001')
    console.log('GOTH v2 Exchange Address:', gothV2Exchange.address)

    console.log('Owner Wallet Avax:', await ethers.provider.getBalance(ownerWallet.address))
    console.log('Test Wallet Avax:', await ethers.provider.getBalance(testWallet.address))

    const tx = await ownerWallet.sendTransaction({
      from: ownerWallet.address,
      to: gothV2Exchange.address,
      value: ethers.BigNumber.from('10')
    });

    console.log('GOTHv2Exchange Avax:', await ethers.provider.getBalance(gothV2Exchange.address))
    console.log('GOTHv2Exchange New GOTH:', await gothV2Exchange.balanceOf(gothV2Exchange.address))

    await gothTokenOld.connect(ownerWallet).transfer(testWallet.address, ethers.BigNumber.from('1000000000'));
    console.log('Test Wallet Old GOTH:', await gothTokenOld.balanceOf(testWallet.address));
    
    await gothTokenOld.connect(testWallet).approve(gothV2Exchange.address, ethers.BigNumber.from('1000000000'));
    console.log('Approved new GOTH token contract to spend test wallet old GOTH');

    await gothV2Exchange.connect(testWallet).swapForNewGoth(ethers.BigNumber.from('1000000000'), options)
    console.log('Test wallet attempted to swap old goth for new goth.');

    console.log('Test Wallet New GOTH:', await gothV2Exchange.balanceOf(testWallet.address));
    console.log('Test Wallet Old GOTH:', await gothTokenOld.balanceOf(testWallet.address));
}

main()