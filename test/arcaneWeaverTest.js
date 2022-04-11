const console = require('console');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const fs = require('fs')

function delay (n) {
    return new Promise(function (resolve) {
      setTimeout(resolve, n * 1000)
    })
  }

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()

    var options = { gasPrice: 250000000000, gasLimit: 30000000 }
    var withValue = { value: 10000000000000000000n, gasPrice: 250000000000, gasLimit: 30000000 }
    const ownerWallet = new ethers.Wallet('fc22cb995181f45fc0d9bf6a26bd686bcc30c6e1a2c0e02df08497809ba84931', ethers.provider)

    const wallets = getWallets();
    console.log('Retrieved wallets...');

    let gothPairJson = ''
    await fs.readFile('F:/GOTH Project/goth-core/artifacts/contracts/swap/pairs/GothPair.sol/GothPair.json', 'utf8' , (err, data) => { gothPairJson = JSON.parse(data); })

    const gothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken');
    const goth = await gothSource.deploy();
    console.log('Deployed goth token...');

    const wavaxSource = await ethers.getContractFactory('contracts/swap/WAVAX.sol:WAVAX');
    const wavax = await wavaxSource.deploy();
    console.log('Deployed wavax token...');

    await wavax.connect(owner).deposit(withValue);

    console.log("GOTH Balance:", await goth.balanceOf(owner.address));
    console.log("WAVAX Balance:", await wavax.balanceOf(owner.address));

    const factorySource = await ethers.getContractFactory('contracts/swap/pairs/GothFactory.sol:GothFactory')
    const factoryContract = await factorySource.deploy(ownerWallet.address)
    console.log('Deployed factory...');

    const routerSource = await ethers.getContractFactory('contracts/swap/pairs/GothRouter.sol:GothRouter')
    const routerContract = await routerSource.deploy(factoryContract.address, wavax.address)
    console.log('Goth Router deployed at...', routerContract.address)

    await goth.connect(owner).approve(routerContract.address, 10000000000000000000n);
    await wavax.connect(owner).approve(routerContract.address, 10000000000000000000n);

    await delay(2);

    await routerContract.connect(owner).addLiquidity(goth.address, wavax.address, 10000000000000000000n, 10000000000000000000n, 1, 1, owner.address, 1681129337, options);
    let pairAddress = ''

    await factoryContract.on("PairCreated", (token0, token1, pair, value) => {
        console.log(token0, token1, pair, value);
        console.log('Created goth/wavax pair...');
        pairAddress = pair;
    });

    await delay(5);

    const pairContract = await new ethers.Contract(pairAddress, gothPairJson.abi, ethers.provider);
    console.log('GothPair:', pairContract.address);

    const sigilSource = await ethers.getContractFactory('contracts/court/ArcaneSigils.sol:ArcaneSigils')
    const sigil = await sigilSource.deploy();
    console.log('Arcane Sigils -', sigil.address);

    const weaverSource = await ethers.getContractFactory('contracts/ArcaneWeaver.sol:ArcaneWeaver')
    const arcaneWeaver = await weaverSource.deploy(
        sigil.address,
        wallets[0].address,
        wallets[1].address,
        wallets[2].address,
        4133333333333333333n,
        Math.floor(Date.now() / 1000),
        200,
        200,
        100
    );

    await sigil.connect(owner).transferOwnership(arcaneWeaver.address);

    console.log('Arcane Weaver -', arcaneWeaver.address);
    const dispenserSource = await ethers.getContractFactory('contracts/dispensers/BasicDispenserPerSec.sol:BasicDispenserPerSec');
    const dispenser = await dispenserSource.deploy(
        goth.address,
        pairAddress,
        4133333333333333333n,
        arcaneWeaver.address,
        false
    );

    await goth.connect(owner).transfer(dispenser.address, 10000000000000000000000000n);

    await arcaneWeaver.on("FarmAdd", (var1, var2, var3, var4) => {
        console.log("FarmAdd Event: | ID: " + var1 + " | Allocation: " + var2 + " | LP Token: " + var3 + " | Dispenser: " + var4);
        });  
    console.log(await arcaneWeaver.owner());
    await arcaneWeaver.connect(owner).addFarm(1000, pairAddress, dispenser.address, options);

    console.log("GOTH Balance:", await goth.balanceOf(owner.address));
    console.log("WAVAX Balance:", await wavax.balanceOf(owner.address));
    console.log("GSL Balance:", await pairContract.balanceOf(owner.address));

    const gslBalance = await pairContract.balanceOf(owner.address);

    await pairContract.connect(owner).approve(arcaneWeaver.address, gslBalance);

    await delay(2);

    await arcaneWeaver.on("Deposit", (var1, var2, var3) => {
        console.log("Deposit Event: | Weaver: " + var1 + " | FarmID: " + var2 + " | Amount: " + var3);
        });  
    
    await arcaneWeaver.connect(owner).deposit(0, gslBalance);

    await delay(10);

    await arcaneWeaver.on("Deposit", (var1, var2, var3) => {
        console.log("Deposit Event: | Weaver: " + var1 + " | FarmID: " + var2 + " | Amount: " + var3);
        });  
    
    await arcaneWeaver.on("Withdraw", (var1, var2, var3) => {
        console.log("Withdraw Event: | Weaver: " + var1 + " | FarmID: " + var2 + " | Amount: " + var3);
        });  
    
    await arcaneWeaver.on("UpdateFarm", (var1, var2, var3, var4) => {
        console.log("UpdateFarm Event: | FarmID: " + var1 + " | Last Reward Time: " + var2 + " | LP Supply: " + var3 + " | ACC Sigil Per share: " + var4);
        });  

    await arcaneWeaver.on("Collection", (var1, var2, var3) => {
        console.log("Collection Event: | Weaver: " + var1 + " | FarmID: " + var2 + " | Amount: " + var3);
        }); 

    await arcaneWeaver.connect(owner).updateFarm(0);
    await delay(3);

    console.log("Pending Tokens:", await arcaneWeaver.pendingTokens(0, owner.address));

    console.log("Farm GSL Balance:", await pairContract.balanceOf(arcaneWeaver.address));
    console.log("Dispenser GOTH Balance:", await goth.balanceOf(dispenser.address));
    console.log("Farm SIGIL Balance:", await sigil.balanceOf(arcaneWeaver.address));
    await arcaneWeaver.connect(owner).withdraw(0, 0, options);
}

function getWallets ()
{
    const wallets = [];
    wallets[0] = new ethers.Wallet('0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a', ethers.provider)
    wallets[1] = new ethers.Wallet('0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6', ethers.provider)
    wallets[2] = new ethers.Wallet('0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a', ethers.provider)
    wallets[3] = new ethers.Wallet('0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba', ethers.provider)
    wallets[4] = new ethers.Wallet('0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e', ethers.provider)
    wallets[5] = new ethers.Wallet('0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356', ethers.provider)
    wallets[6] = new ethers.Wallet('0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97', ethers.provider)
    return wallets;
}

main()