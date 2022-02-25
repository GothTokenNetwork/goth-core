const console = require('console')
const { ethers } = require('hardhat')
const { delay } = require('lodash')

function delay2 (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main() {

    const privateKey = process.env.FUJI_PRIVATE_KEY

    const ownerWallet = new ethers.Wallet(
        privateKey,
        ethers.provider
    )

    const oldGoth = '0xCcBeCdF71Ba5CA7f8242Ae582D80489ed2d76F8a'
    const treasury = '0xbE7E39c715c46107614f743b95548ea26B0A6BED'
    const burn = '0x0000000000000000000000000000000000000001'

    const gothV2ExchangeSource = await ethers.getContractFactory('contracts/gothV2Exchange.sol:gothV2Exchange')
    const gothV2Exchange = await gothV2ExchangeSource.deploy(oldGoth,'0x0000000000000000000000000000000000000001')
    console.log('GOTH v2 Exchange Address:', gothV2Exchange.address)
}

main()