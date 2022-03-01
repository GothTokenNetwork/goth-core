const console = require('console')
const { ethers } = require('hardhat')
const { delay } = require('lodash')
const fs = require('fs')

function delay2 (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main()
{
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()

    const ownerWallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider)
    const testWallet = new ethers.Wallet('0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d', ethers.provider);

    const clubSource = await ethers.getContractFactory('contracts/club/HoldersClub.sol:HoldersClub')
    const clubContract = await clubSource.deploy();

    console.log('Holders Club Owner:', await clubContract.owner());

    await clubContract.on("Received", (from, amount, gas) => {
        console.log(ethers.utils.formatEther(amount) + " AVAX received from " + from + " | Gas Left: " + gas);
    });

    await clubContract.on("Send", (to, amount, gas) => {
        console.log(ethers.utils.formatEther(amount) + " was sent to " + to + " | Gas Left: " + gas);
    });

    clubContract.send(testWallet.address, { value: ethers.BigNumber.from('1000000000000000000') });
    testWallet.sendTransaction({ to: clubContract.address, value: ethers.BigNumber.from('1000000000000000000') });
}

main()