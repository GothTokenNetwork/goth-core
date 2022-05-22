const console = require('console')
const { ethers } = require('hardhat')
const fs = require('fs')

function delay (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()
    var options2 = { gasPrice: 70000000000, gasLimit: 30000000 }

    var enterFee = { value: ethers.BigNumber.from('2750000000000000000'),  gasPrice: 250000000000, gasLimit: 30000000 }
    var leaveFee = { value: ethers.BigNumber.from('10000000000000000'),  gasPrice: 250000000000, gasLimit: 30000000 }

    // LOCALHOST
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    console.log('Owner Address:', owner.address);
    const ownerWallet = new ethers.Wallet(ownerKey, ethers.provider)

    // FUJI
    //const ownerWallet = new ethers.Wallet('fc22cb995181f45fc0d9bf6a26bd686bcc30c6e1a2c0e02df08497809ba84931', ethers.provider)

    const oldGothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const oldGothContract = await oldGothSource.deploy();
    console.log('Old GOTH...', oldGothContract.address)  

    const gothV2Source = await ethers.getContractFactory('contracts/swap/GothTokenV2.sol:GothTokenV2')
    const gothV2 = await gothV2Source.deploy(oldGothContract.address);
    console.log('New GOTH...', gothV2.address)  

    const gothStakeSource = await ethers.getContractFactory('contracts/swap/GothStake.sol:GothStake')
    const gothStake = await gothStakeSource.deploy('0x03d16b3dB01a8f4401D56A0FC82dE424533F1e58');
    console.log('Goth Stake...', gothStake.address)  

    await gothV2.connect(ownerWallet).transferOwnership(gothStake.address);

    console.log('------------------------------------------------------')
    console.log('-------------------GOTH V2 TESTING--------------------')
    console.log('------------------------------------------------------')

    await gothV2.on("SwapOldGOTH", (account, oldGothBurnt, newGothMinted) => {
        console.log(account, oldGothBurnt, newGothMinted);
    });

    const oldGothBalance = await oldGothContract.balanceOf(ownerWallet.address);
    console.log("GOTH v1 Balance: ", oldGothBalance);

    await oldGothContract.connect(ownerWallet).approve(gothV2.address, ethers.BigNumber.from('500000000000000000000000000000'));
    console.log("Goth v2 approved old Goth spend");

    await gothV2.connect(ownerWallet).swapOldGOTH(ethers.BigNumber.from('500000000000000000000000000000'), options2);
    console.log("GOTH v2 Balance: ", await gothV2.balanceOf(ownerWallet.address));

    console.log('------------------------------------------------------')
    console.log('------------------GOTH STAKE TESTING------------------')
    console.log('------------------------------------------------------')

    await gothStake.on("Enter", (account, amount) => {
        console.log("Enter", account, amount);
    });

    await gothStake.on("Leave", (account, amount) => {
        console.log("Leave: ", account, amount);
    });

    await gothStake.on("MintGoth", (rate, amount) => {
        console.log("Goth Minted: ", rate, amount);
    });

    await gothV2.connect(ownerWallet).approve(gothStake.address, ethers.BigNumber.from('550000000000000000000000000'));
    console.log("GothStake approved Goth v2 spend");

    await gothStake.connect(ownerWallet).enter(ethers.BigNumber.from('550000000000000000000000000'), enterFee);
    console.log("GothV2 Balance:", await gothV2.balanceOf(ownerWallet.address));
    console.log("bGOTH balance:", await gothStake.balanceOf(ownerWallet.address));

    console.log("Waiting 60 seconds...");
    await delay(60);

    await gothStake.connect(ownerWallet).approve(gothStake.address, await gothStake.balanceOf(ownerWallet.address));
    console.log("GothStake approved bGOTH spend");   
    
    await gothStake.connect(ownerWallet).leave(await gothStake.balanceOf(ownerWallet.address), leaveFee);
    console.log("GothV2 Balance:", await gothV2.balanceOf(ownerWallet.address));
    console.log("bGOTH balance:", await gothStake.balanceOf(ownerWallet.address));
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