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
    var options = { value: ethers.BigNumber.from('100000000000000000000000'), gasPrice: 250000000000, gasLimit: 30000000 }
    var options2 = { gasPrice: 250000000000, gasLimit: 30000000 }

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    let gothPairJson = ''

    await fs.readFile('F:/GOTH Project/goth-swap-core/artifacts/contracts/Pairs/GothPair.sol/GothPair.json', 'utf8' , (err, data) => { gothPairJson = JSON.parse(data); })

    console.log('Owner Address:', owner.address);
    const ownerWallet = new ethers.Wallet(ownerKey, ethers.provider)
    const testWallet = new ethers.Wallet(addr1Key, ethers.provider);

    const wavaxSource = await ethers.getContractFactory('contracts/WAVAX.sol:WAVAX')
    const wavaxContract = await wavaxSource.deploy();

    const oldGothSource = await ethers.getContractFactory('contracts/OldGothToken.sol:OldGothToken')
    const oldGothContract = await wavaxSource.deploy();

    const gothV2SwapSource = await ethers.getContractFactory('contracts/GothV2Swap.sol:GothV2Swap')
    const gothV2Swap = await gothV2SwapSource.deploy(oldGothContract.address, '0x0000000000000000000000000000000000000001');
    console.log('Goth v2 Swap deployed at...', gothV2Swap.address)  

    const factorySource = await ethers.getContractFactory('contracts/Pairs/GothFactory.sol:GothFactory')
    const factoryContract = await factorySource.deploy(owner.address)
    console.log('Goth Factory deployed at...', factoryContract.address)  
    console.log('Fee To Setter:', owner.address) 
    
    const routerSource = await ethers.getContractFactory('contracts/Pairs/GothRouter.sol:GothRouter')
    const routerContract = await routerSource.deploy(factoryContract.address, wavaxContract.address)
    console.log('Goth Router deployed at...', routerContract.address)

    console.log('------------------------------------------------------')
    console.log('------------CONTRACTS DEPLOYED NOW TESTING------------')
    console.log('------------------------------------------------------')

    await gothV2Swap.connect(ownerWallet).withdraw(ethers.BigNumber.from('150000000000000000000000'))
    console.log('Owner withdrew from contract...', await gothV2Swap.balanceOf(ownerWallet.address))

    await gothV2Swap.connect(ownerWallet).transfer(testWallet.address, ethers.BigNumber.from('150000000000000000000000'))
    console.log('Owner transfered to...', testWallet.address)
    
    console.log('------------------------------------------------------')
    console.log('------------CHECKING TEST WALLET BALANCES-------------')
    console.log('------------------------------------------------------')

    console.log('AVAX:', ethers.utils.formatEther(await ethers.provider.getBalance(testWallet.address)))
    console.log('GOTH v2:', ethers.utils.formatEther(await gothV2Swap.balanceOf(testWallet.address)))

    console.log('------------------------------------------------------')
    console.log('--------CREATING TOKEN PAIR WITH TEST ACCOUNT---------')
    console.log('------------------------------------------------------')

    await gothV2Swap.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('150000000000000000000000'));
    console.log('Approved router to spend test wallet goth.');

    await wavaxContract.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('150000000000000000000000'));
    console.log('Approved router to spend test wallet wavax.');

    // const result = await factoryContract.createPair(wavaxContract.address, gothV2Swap.address);
    // console.log(result);

    const result2 = await routerContract.connect(testWallet).addLiquidityAVAX(
        gothV2Swap.address,
        ethers.BigNumber.from('100000000000000000000000'),
        ethers.BigNumber.from('0'),
        ethers.BigNumber.from('0'),
        testWallet.address,
        1648250407,
        options
        );

    let pairAddress = ''

    await factoryContract.on("PairCreated", (token0, token1, pair, value) => {
        console.log(token0, token1, pair, value);
        pairAddress = pair;
    });

    console.log('Waiting 5 seconds for pair creation event...');
    await delay2(5);

    const pairContract = await new ethers.Contract(pairAddress, gothPairJson.abi, ethers.provider);
    console.log('GothPair Created:', pairContract.address);
    const gslBalance = await pairContract.balanceOf(testWallet.address);
    console.log('Test Wallet GSL Balance:', ethers.utils.formatEther(gslBalance));

    console.log('------------------------------------------------------')
    console.log('--------------TESTING PAIR FUNCTIONALITY--------------')
    console.log('------------------------------------------------------')

    const reserves = await pairContract.getReserves()
    const reserve0 = reserves["_reserve0"]
    const reserve1 = reserves["_reserve1"]
    console.log('GOTH V2:', ethers.utils.formatEther(reserve0));
    console.log('WAVAX:', ethers.utils.formatEther(reserve1));

    await gothV2Swap.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('50000000000000000000000'));
    console.log('Approved router to spend test wallet goth.');

    console.log('Attemping swap exact GOTH for Avax');
    const amounts = await routerContract.connect(testWallet).swapExactTokensForAVAX(ethers.BigNumber.from('50000000000000000000000'), 0, [gothV2Swap.address, wavaxContract.address], testWallet.address, 1648250407, options2);
    console.log('Swap complete...');

    const reserves2 = await pairContract.getReserves()
    const reserve02 = reserves2["_reserve0"]
    const reserve12 = reserves2["_reserve1"]
    console.log('GOTH V2:', ethers.utils.formatEther(reserve02));
    console.log('WAVAX:', ethers.utils.formatEther(reserve12));

    console.log('Pair GOTH v2 Balance:', await gothV2Swap.balanceOf(pairContract.address));
}


main()