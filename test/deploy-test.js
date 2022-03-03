const console = require('console')
const { ethers } = require('hardhat')
const { delay } = require('lodash')
const fs = require('fs')

function delay2 (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()
    var options = { value: ethers.BigNumber.from('5000000000000000000000000'), gasPrice: 250000000000, gasLimit: 30000000 }

    console.log('Owner Address:', owner.address);

    const wavaxSource = await ethers.getContractFactory('contracts/swap/WAVAX.sol:WAVAX')
    const wavaxContract = await wavaxSource.deploy();
    console.log('WAVAX:', wavaxContract.address);

    const oldGothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const oldGothContract = await oldGothSource.deploy();
    console.log('Old GOTH:', oldGothContract.address);

    const gothV2SwapSource = await ethers.getContractFactory('contracts/swap/GothV2Swap.sol:GothV2Swap')
    const gothV2Swap = await gothV2SwapSource.deploy(oldGothContract.address, '0x0000000000000000000000000000000000000001');
    console.log('GOTH v2 Swap/Token:', gothV2Swap.address)  

    const factorySource = await ethers.getContractFactory('contracts/swap/pairs/GothFactory.sol:GothFactory')
    const factoryContract = await factorySource.deploy(owner.address)
    console.log('Goth Factory:', factoryContract.address)  
    console.log('Fee To Setter:', owner.address) 
    
    const routerSource = await ethers.getContractFactory('contracts/swap/pairs/GothRouter.sol:GothRouter')
    const routerContract = await routerSource.deploy(factoryContract.address, wavaxContract.address)
    console.log('Goth Router:', routerContract.address)
}

function parseTimestamp (ts)
{
    var date = new Date(ts * 1000);
    var hours = date.getHours();
    var minutes = "0" + date.getMinutes();
    var seconds = "0" + date.getSeconds();
    var time = hours + ':' + minutes.substr(-2) + ':' + seconds.substr(-2);
    return date.getDate() + '/' + date.getMonth() + '/' + date.getFullYear() + ' - ' + time;
}

main()