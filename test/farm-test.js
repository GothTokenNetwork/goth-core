const console = require('console')
const { ethers } = require('hardhat')
const { delay } = require('lodash')
const fs = require('fs')

function delay (n) {
    return new Promise(function (resolve) {
      setTimeout(resolve, n * 1000)
    })
  }

  async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()
    var options = { value: ethers.BigNumber.from('100000000000000000000000'), gasPrice: 250000000000, gasLimit: 30000000 }
    var options2 = { gasPrice: 250000000000, gasLimit: 30000000 }

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    
}

main()