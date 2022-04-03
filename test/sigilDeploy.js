const console = require('console')
const { ethers } = require('hardhat')
const fs = require('fs')

function delay (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main ()
{
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()

    var options = { gasPrice: 250000000000, gasLimit: 30000000 }
    const ownerWallet = new ethers.Wallet('fc22cb995181f45fc0d9bf6a26bd686bcc30c6e1a2c0e02df08497809ba84931', ethers.provider)

    const factorySource = await ethers.getContractFactory('contracts/swap/pairs/GothFactory.sol:GothFactory')
    const factoryContract = await factorySource.deploy(ownerWallet.address)
    console.log('Goth Factory deployed at...', factoryContract.address)  
    console.log('Fee To Setter:', ownerWallet.address) 
    
    const routerSource = await ethers.getContractFactory('contracts/swap/pairs/GothRouter.sol:GothRouter')
    const routerContract = await routerSource.deploy(factoryContract.address, wavaxContract.address)
    console.log('Goth Router deployed at...', routerContract.address)
}

main()