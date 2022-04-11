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

    // const wavaxSource = await ethers.getContractFactory('contracts/swap/WAVAX.sol:WAVAX');
    // const wavax = await wavaxSource.deploy();
    // console.log('Deployed wavax token...');

     const actualOwner = ownerWallet;
    // const wavaxAddress = '0x5e6e168933f96E62d721982123c5a11B0e288440';

    // const devAddr = '0xeC6cFe057ae9B9a04277E9E757DcDdA4b89B2Dfa'
    // const treasuryAddr = '0xA04AFC2530b1B6b6CefDbB0B3DCBFa406D0bfD90'
    // const investorAddr = '0xe5bF15FC04A15590614f3961381C3Fb631c86602'

    // const actualOwner = owner;
    // const wavaxAddress = wavax.address;

    // const devAddr = addr1.address
    // const treasuryAddr = addr2.address
    // const investorAddr = addr3.address


    // const oldGothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    // const oldGothContract = await oldGothSource.connect(actualOwner).deploy();
    // console.log("Old GOTH Token: ", oldGothContract.address);

    const gothV2Source = await ethers.getContractFactory('contracts/swap/GothTokenV2.sol:GothTokenV2')
    const gothV2 = await gothV2Source.connect(actualOwner).deploy('0xCcBeCdF71Ba5CA7f8242Ae582D80489ed2d76F8a');
    console.log('Goth v2 deployed at...', gothV2.address);

    // const factorySource = await ethers.getContractFactory('contracts/swap/pairs/GothFactory.sol:GothFactory')
    // const factoryContract = await factorySource.deploy(actualOwner.address)
    // console.log('Goth Factory deployed at...', factoryContract.address)  
    // console.log('Fee To Setter:', actualOwner.address) 
    
    // const routerSource = await ethers.getContractFactory('contracts/swap/pairs/GothRouter.sol:GothRouter')
    // const routerContract = await routerSource.deploy(factoryContract.address, wavaxAddress)
    // console.log('Goth Router deployed at...', routerContract.address)

    // const sigilSource = await ethers.getContractFactory('contracts/court/ArcaneSigils.sol:ArcaneSigils')
    // const sigil = await sigilSource.deploy();
    // console.log('Arcane Sigils -', sigil.address);

    // const weaverSource = await ethers.getContractFactory('contracts/ArcaneWeaver.sol:ArcaneWeaver')
    // const arcaneWeaver = await weaverSource.deploy(
    //     sigil.address,
    //     devAddr,
    //     treasuryAddr,
    //     investorAddr,
    //     4130000000000000000n,
    //     Math.floor(Date.now() / 1000),
    //     200,
    //     200,
    //     100
    // );
    // console.log('Arcane Weaver -', arcaneWeaver.address);

    // await sigil.connect(actualOwner).transferOwnership(arcaneWeaver.address);
    // console.log("SIGIL Ownership has been passed to ArcaneWeaver contract");

    // const gothStakeSource = await ethers.getContractFactory('contracts/swap/GothStake.sol:GothStake')
    // const gothStake = await gothStakeSource.deploy(gothV2.address)
    // console.log('GothStake deployed at...', gothStake.address)

    // const sigilStakeSource = await ethers.getContractFactory('contracts/swap/SigilStake.sol:SigilStake')
    // const sigilStake = await sigilStakeSource.deploy(sigil.address)
    // console.log('SigilStake deployed at...', sigilStake.address)
}

main()