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
    var options = { value: ethers.BigNumber.from('5000000000000000000000000'), gasPrice: 250000000000, gasLimit: 30000000 }
    var options = { gasPrice: 2500000000, gasLimit: 30000000 }
    var options3 = { value: ethers.BigNumber.from('20000000000000000000000'),  gasPrice: 250000000000, gasLimit: 30000000 }
    var options4 = { value: ethers.BigNumber.from('750000000000000000000000'),  gasPrice: 250000000000, gasLimit: 30000000 }

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const addr2Key = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'
    const addr3Key = '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    let gothPairJson = ''
    await fs.readFile('F:/GOTH Project/goth-core/artifacts/contracts/swap/pairs/GothPair.sol/GothPair.json', 'utf8' , (err, data) => { gothPairJson = JSON.parse(data); })

    console.log('Owner Address:', owner.address);
    const ownerWallet = new ethers.Wallet(ownerKey, ethers.provider)
    const testWallet = new ethers.Wallet(addr1Key, ethers.provider);
    const test2Wallet = new ethers.Wallet(addr2Key, ethers.provider);
    const test3Wallet = new ethers.Wallet(addr3Key, ethers.provider);

    var options = { gasPrice: 2500000000, gasLimit: 30000000 }
    const wavaxSource = await ethers.getContractFactory('contracts/swap/WAVAX.sol:WAVAX')
    const wavaxContract = await wavaxSource.deploy(options);

    const oldGothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const oldGothContract = await oldGothSource.deploy();

    const gothV2SwapSource = await ethers.getContractFactory('contracts/swap/GothV2Swap.sol:GothV2Swap')
    const gothV2Swap = await gothV2SwapSource.deploy(oldGothContract.address, '0x0000000000000000000000000000000000000001');
    console.log('Goth v2 Swap deployed at...', gothV2Swap.address)  

    const factorySource = await ethers.getContractFactory('contracts/swap/pairs/GothFactory.sol:GothFactory')
    const factoryContract = await factorySource.deploy(owner.address)
    console.log('Goth Factory deployed at...', factoryContract.address)  
    console.log('Fee To Setter:', owner.address) 
    
    const routerSource = await ethers.getContractFactory('contracts/swap/pairs/GothRouter.sol:GothRouter')
    const routerContract = await routerSource.deploy(factoryContract.address, wavaxContract.address)
    console.log('Goth Router deployed at...', routerContract.address)

    console.log('------------------------------------------------------')
    console.log('------------CONTRACTS DEPLOYED NOW TESTING------------')
    console.log('------------------------------------------------------')

    await gothV2Swap.connect(ownerWallet).withdraw(ethers.BigNumber.from('200000000000000000000000'))
    console.log('Owner withdrew from contract...', await gothV2Swap.balanceOf(ownerWallet.address))

    await gothV2Swap.connect(ownerWallet).transfer(testWallet.address, ethers.BigNumber.from('200000000000000000000000'))
    console.log('Owner transfered to...', testWallet.address)
    
    console.log('------------------------------------------------------')
    console.log('------------CHECKING TEST WALLET BALANCES-------------')
    console.log('------------------------------------------------------')

    console.log('AVAX:', ethers.utils.formatEther(await ethers.provider.getBalance(testWallet.address)))
    console.log('GOTH v2:', ethers.utils.formatEther(await gothV2Swap.balanceOf(testWallet.address)))

    console.log('------------------------------------------------------')
    console.log('--------CREATING TOKEN PAIR WITH TEST ACCOUNT---------')
    console.log('------------------------------------------------------')

    await gothV2Swap.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('2000000000000000000000000'));
    console.log('Approved router to spend test wallet goth.');

    await wavaxContract.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('2000000000000000000000000'));
    console.log('Approved router to spend test wallet wavax.');

    const result = await factoryContract.createPair(wavaxContract.address, gothV2Swap.address);
    console.log(result);

    // const result2 = await routerContract.connect(testWallet).addLiquidityAVAX(
    //     gothV2Swap.address,
    //     ethers.BigNumber.from('10000000000000000000000000'),
    //     ethers.BigNumber.from('0'),
    //     ethers.BigNumber.from('0'),
    //     testWallet.address,
    //     1683666252,
    //     options
    //     );

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

    await gothV2Swap.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('5000000000000000000000000000000'));
    await gothV2Swap.connect(test2Wallet).approve(routerContract.address, ethers.BigNumber.from('5000000000000000000000000000000'));
    await gothV2Swap.connect(test3Wallet).approve(routerContract.address, ethers.BigNumber.from('5000000000000000000000000000000'));
    console.log('Approved router to spend test wallet goth.');

    await wavaxContract.connect(testWallet).approve(routerContract.address, ethers.BigNumber.from('5000000000000000000000000000000'));
    await wavaxContract.connect(test2Wallet).approve(routerContract.address, ethers.BigNumber.from('5000000000000000000000000000000'));
    await wavaxContract.connect(test3Wallet).approve(routerContract.address, ethers.BigNumber.from('5000000000000000000000000000000'));
    console.log('Approved router to spend test wallet goth.');

    // console.log('Attemping swap exact GOTH for Avax');
    // const amounts = await routerContract.connect(testWallet).swapExactTokensForAVAX(ethers.BigNumber.from('50000000000000000000000'), 0, [gothV2Swap.address, wavaxContract.address], testWallet.address, 1683666252, options2);
    // console.log('Swap complete...');

    const reserves2 = await pairContract.getReserves()
    const reserve02 = reserves2["_reserve0"]
    const reserve12 = reserves2["_reserve1"]
    console.log('GOTH V2:', ethers.utils.formatEther(reserve02));
    console.log('WAVAX:', ethers.utils.formatEther(reserve12));

    // console.log('Attemping to add liquidity with test wallet');
    // const addliq = await routerContract.connect(testWallet).addLiquidityAVAX(gothV2Swap.address, ethers.BigNumber.from('50000000000000000000000'), 0, 0, testWallet.address, 1683666252, options);
    // const addliq2 = await routerContract.connect(test2Wallet).addLiquidityAVAX(gothV2Swap.address, ethers.BigNumber.from('2000000000000000000000'), 0, 0, test2Wallet.address, 1683666252, options3);
    // const addliq3 = await routerContract.connect(test3Wallet).addLiquidityAVAX(gothV2Swap.address, ethers.BigNumber.from('75000000000000000000000'), 0, 0, test3Wallet.address, 1683666252, options4);

    const reserves23 = await pairContract.getReserves()
    const reserve023 = reserves23["_reserve0"]
    const reserve123 = reserves23["_reserve1"]
    console.log('GOTH V2:', ethers.utils.formatEther(reserve023));
    console.log('WAVAX:', ethers.utils.formatEther(reserve123));

    console.log('Pair GOTH v2 Balance:', await gothV2Swap.balanceOf(pairContract.address));

    const sigilSource = await ethers.getContractFactory('contracts/court/ArcaneSigils.sol:ArcaneSigils')
    const sigil = await sigilSource.deploy();
    console.log('Arcane Sigils -', sigil.address);

    const weaverSource = await ethers.getContractFactory('contracts/ArcaneWeaver.sol:ArcaneWeaver')
    const arcaneWeaver = await weaverSource.deploy(
        sigil.address,
        testWallet.address,
        test2Wallet.address,
        test3Wallet.address,
        4133333333333333333n,
        Math.floor(Date.now() / 1000),
        200,
        200,
        100
    );
    console.log('Arcane Weaver -', arcaneWeaver.address);

    const dispenserSource = await ethers.getContractFactory('contracts/dispensers/BasicDispenserPerSec.sol:BasicDispenserPerSec')
    const dispenser = await dispenserSource.deploy(gothV2Swap.address, pairContract.address, 4133333333333333333n, arcaneWeaver.address, false);
    console.log('Arcane Dispenser -', dispenser.address);

    // console.log('------------------------------------------------------')
    // console.log('---------------DEPLOYING ESSENCE FARMS----------------')
    // console.log('------------------------------------------------------')

    // const essenceFarmSource = await ethers.getContractFactory('contracts/Farm/EssenceFarm.sol:EssenceFarm')
    // const essenceFarm = await essenceFarmSource.deploy(pairAddress);
    // console.log('Essence Farms deployed at...', essenceFarm.address);  

    // const gslAmount = await pairContract.balanceOf(testWallet.address);
    // const gslAmount2 = await pairContract.balanceOf(testWallet2.address);
    // const gslAmount3 = await pairContract.balanceOf(testWallet3.address);

    // await pairContract.connect(testWallet).approve(essenceFarm.address, gslAmount);
    // console.log('Approved farm to transfer test wallet GSL tokens.');

    // console.log('--| Test Wallet GSL Tokens: ', ethers.utils.formatEther(gslAmount));

    // await essenceFarm.connect(testWallet).enterFarm(gslAmount, 0);
    // await essenceFarm.connect(test2Wallet).enterFarm(gslAmount2, 0);
    // await essenceFarm.connect(test3Wallet).enterFarm(gslAmount3, 0);

    // await essenceFarm.on("EnterFarm", (sender, amount, essenceType) => {
    //   console.log('Sender:', sender);
    //   console.log('Amount Entered:', ethers.utils.formatEther(amount));
    //   console.log('Farm ID:', essenceType);
    // });

    // console.log('Waiting 5 seconds for EnterFarm event...');
    // await delay2(5);

    // console.log('Farm 0 GSL Staked:', ethers.utils.formatEther(await essenceFarm.connect(testWallet).farmBalance(0)));
    // console.log('Farm 0 Last Claim:', parseTimestamp(await essenceFarm.connect(testWallet).farmLastClaim(0)));
    // console.log('Farm 0 GSL Balance:',  ethers.utils.formatEther(await pairContract.balanceOf(await essenceFarm.essenceFarm(0))));
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