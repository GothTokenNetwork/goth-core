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
    var options = { gasPrice: 250000000000, gasLimit: 30000000 }

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const ownerWallet = new ethers.Wallet(ownerKey, ethers.provider)
    const testWallet = new ethers.Wallet(addr1Key, ethers.provider);

    const gothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const gothContract = await gothSource.deploy();

    await gothContract.connect(ownerWallet).transfer(testWallet.address, ethers.BigNumber.from('200000000000000000000000'));

    const essenceFarmSource = await ethers.getContractFactory('contracts/swap/farm/EssenceFarm.sol:EssenceFarm')
    const essenceFarm = await essenceFarmSource.deploy(gothContract.address);

    await essenceFarm.on("Deposit", (sender, amount, farmId) => {
      console.log("Deposit Event: " + sender + " | Deposit: " + ethers.utils.formatEther(amount) + " | Farm ID: " + farmId);
    });

    await essenceFarm.on("Withdraw", (sender, amount, farmId) => {
      console.log("Withdraw Event: " + sender + " | Deposit: " + ethers.utils.formatEther(amount) + " | Farm ID: " + farmId);
    });

    await essenceFarm.on("EssenceClaimed", (sender, amount, farmId) => {
      console.log("Claim Event: " + sender + " | Essence: " + ethers.utils.formatEther(amount) + " | Farm ID: " + farmId);
    });

    console.log('Essence Farms deployed at...', essenceFarm.address);

    console.log('Goth Pair Address:', await essenceFarm.gothPair());

    console.log('Earth Farm:', await essenceFarm.essenceFarm(0));
    console.log('Air Farm:', await essenceFarm.essenceFarm(1));
    console.log('Spirit Farm:', await essenceFarm.essenceFarm(2));
    console.log('Water Farm:', await essenceFarm.essenceFarm(3));
    console.log('Fire Farm:', await essenceFarm.essenceFarm(4));

    let userInfo = await essenceFarm.connect(testWallet).userInfo();
    console.log(testWallet.address + " | Experience: " + ethers.utils.formatEther(userInfo[0]) + " | Level: " + userInfo[1] + " | XP To Next Level: " + userInfo[2]);

    await gothContract.connect(testWallet).approve(essenceFarm.address, ethers.BigNumber.from('200000000000000000000000'));
    console.log('Essence Farm Allowance:', ethers.utils.formatEther(await gothContract.allowance(testWallet.address, essenceFarm.address)));
    await essenceFarm.connect(testWallet).deposit(ethers.BigNumber.from('100000000000000000000000'), 0, options);


    await delay(6);
    console.log('Waiting 6 seconds...');

    console.log('Earth Farm GSL Balance:', ethers.utils.formatEther(await essenceFarm.essenceFarmBalance(0)));
    //console.log('Essence Farm GSL Balance:', ethers.utils.formatEther(await essenceFarm.essenceFarmBalance(0)));

    userInfo = await essenceFarm.connect(testWallet).farmInfo(0);
    console.log(testWallet.address + " | Total Staked: " + ethers.utils.formatEther(userInfo[0]) + " | Accrued Essence: " + userInfo[1] + " | Last Interaction: " + parseTimestamp(userInfo[2]));

    await delay(6);
    console.log('Waiting 6 seconds...');

    await gothContract.connect(testWallet).approve(await essenceFarm.essenceFarm(0), ethers.BigNumber.from('100000000000000000000000'));
    console.log('Essence Farm Allowance:', ethers.utils.formatEther(await gothContract.allowance(testWallet.address, await essenceFarm.essenceFarm(0))));

    await essenceFarm.connect(testWallet).withdraw(ethers.BigNumber.from('50000000000000000000000'), 0, options);

    userInfo = await essenceFarm.connect(testWallet).farmInfo(0);
    console.log(testWallet.address + " | Total Staked: " + ethers.utils.formatEther(userInfo[0]) + " | Accrued Essence: " + ethers.utils.formatEther(userInfo[1]) + " | Last Interaction: " + parseTimestamp(userInfo[2]));

    await delay(6);
    console.log('Waiting 6 seconds...');
    
    userInfo = await essenceFarm.connect(testWallet).farmInfo(0);
    console.log(testWallet.address + " | Total Staked: " + ethers.utils.formatEther(userInfo[0]) + " | Accrued Essence: " + ethers.utils.formatEther(userInfo[1]) + " | Last Interaction: " + parseTimestamp(userInfo[2]));

    await essenceFarm.connect(testWallet).withdraw(ethers.BigNumber.from('50000000000000000000000'), 0, options);

    userInfo = await essenceFarm.connect(testWallet).farmInfo(0);
    console.log(testWallet.address + " | Total Staked: " + ethers.utils.formatEther(userInfo[0]) + " | Accrued Essence: " + ethers.utils.formatEther(userInfo[1]) + " | Last Interaction: " + parseTimestamp(userInfo[2]));
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