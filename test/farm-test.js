const console = require('console')
const { ethers } = require('hardhat')
const fs = require('fs')
const internal = require('stream')
const { Interface } = require('ethers/lib/utils')

function delay (n) {
    return new Promise(function (resolve) {
      setTimeout(resolve, n * 1000)
    })
  }

  async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()
    var options = { value: ethers.BigNumber.from('100000000000000000000000'), gasPrice: 250000000000, gasLimit: 30000000 }
    var options2 = { gasPrice: 250000000000, gasLimit: 30000000 }

    let gothPairJson = ''
    await fs.readFile('F:/GOTH Project/goth-swap-core/artifacts/contracts/Pairs/IGothPair.sol/IGothPair.json', 'utf8' , (err, data) => { gothPairJson = JSON.parse(data); })

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const ownerWallet = new ethers.Wallet(ownerKey, ethers.provider)
    const testWallet = new ethers.Wallet(addr1Key, ethers.provider);

    const factorySource = await ethers.getContractFactory('contracts/Pairs/GothFactory.sol:GothFactory')
    const factory = await factorySource.deploy(owner.address)
    console.log('Goth Factory deployed at...', factory.address)  
    console.log('Fee To Setter:', owner.address) 

    const oldGothSource = await ethers.getContractFactory('contracts/OldGothToken.sol:OldGothToken')
    const oldGothContract = await oldGothSource.deploy();

    const gothV2SwapSource = await ethers.getContractFactory('contracts/GothV2Swap.sol:GothV2Swap')
    const gothV2Swap = await gothV2SwapSource.deploy(oldGothContract.address, '0x0000000000000000000000000000000000000001');
    console.log('Goth v2 Swap deployed at...', gothV2Swap.address)  

    const wavaxSource = await ethers.getContractFactory('contracts/WAVAX.sol:WAVAX')
    const wavaxContract = await wavaxSource.deploy();

    const result = await factory.createPair(wavaxContract.address, gothV2Swap.address);
    let pairAddress = "";

    await factory.on("PairCreated", (token0, token1, pair, value) => {
        console.log(token0, token1, pair, value);
        pairAddress = pair;
    });

    console.log('Waiting 5 seconds for pair creation event...');
    await delay(5);

    const pairContract = await new ethers.Contract(pairAddress, gothPairJson.abi, ethers.provider);

    const essenceFarmSource = await ethers.getContractFactory('contracts/Farm/EssenceFarm.sol:EssenceFarm')
    const essenceFarm = await essenceFarmSource.deploy(pairAddress);

    console.log('Essence Farms deployed at...', essenceFarm.address);
    console.log('Earth Essence:', essenceFarm.earthEssence.address);


}

main()