const console = require('console')
const { ethers } = require('hardhat')
const { delay } = require('lodash')

function delay2(n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main() {
  var options = { gasPrice: 250000000000, gasLimit: 30000000 }
  const privateKey = process.env.FUJI_PRIVATE_KEY

  const ownerWallet = new ethers.Wallet(privateKey, ethers.provider)

  console.log('Ownder Address:', ownerWallet.address)

  const gothStakeSource = await ethers.getContractFactory('contracts/GothStake.sol:GothStake')

  const gothStake = await gothStakeSource.deploy(
    '0x164909A78Ed1b08A9D16B5640dcb0454fDeE3C74',
  )

  console.log('GOTH Stake: ', gothStake.address)
}

main()
