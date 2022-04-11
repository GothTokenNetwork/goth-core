const console = require('console')
const { ethers } = require('hardhat')

function delay (n) {
  return new Promise(function (resolve) {
    setTimeout(resolve, n * 1000)
  })
}

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()

    const oldGothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const oldGothContract = await oldGothSource.deploy();

    const gothV2Source = await ethers.getContractFactory('contracts/swap/GothTokenV2.sol:GothTokenV2')
    const gothV2 = await gothV2Source.deploy(oldGothContract.address);
    console.log('Goth v2 Swap deployed at...', gothV2.address);
    
    console.log("Old GOTH Balance:", await oldGothContract.balanceOf(owner.address));
    console.log("GOTH v2 Balance:", await gothV2.balanceOf(owner.address));

    const swapAmount = 1000000000000000000000000000n;

    await oldGothContract.connect(owner).approve(gothV2.address, swapAmount);
    await gothV2.on("SwapOldGOTH", (var1, var2, var3) => {
        console.log("SwapOldGOTH Event: | Account: " + var1 + " | Old GOTH Burnt: " + var2 + " | New GOTH Minted: " + var3);
        }); 

    const result = await gothV2.connect(owner).swapOldGOTH(swapAmount);
    console.log(result);

    console.log("Old GOTH Balance:", await oldGothContract.balanceOf(owner.address));
    console.log("GOTH v2 Balance:", await gothV2.balanceOf(owner.address));
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