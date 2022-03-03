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

    const wallets = getWallets();

    const addr1Key = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
    const ownerKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const ownerWallet = new ethers.Wallet(ownerKey, ethers.provider)
    const testWallet = new ethers.Wallet(addr1Key, ethers.provider);
    console.log(ownerWallet.address);

    const FiveHundred = ethers.BigNumber.from('500000000000000000000');
    const OneThousand = ethers.BigNumber.from('1000000000000000000000');
    const TenThousand = ethers.BigNumber.from('10000000000000000000000');
    const HundredThousand = ethers.BigNumber.from('100000000000000000000000');
    const FiveHundredThousand = ethers.BigNumber.from('500000000000000000000000');
    const OneMillion = ethers.BigNumber.from('1000000000000000000000000');
    const TenMillion = ethers.BigNumber.from('10000000000000000000000000');

    // DEPLOY CONTRACTS
    borderedLog('Deploying Contracts', '');

    const gothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const gothContract = await gothSource.deploy();
    console.log('Dummy GSL Token -', gothContract.address);

    const essenceFarmSource = await ethers.getContractFactory('contracts/swap/farm/EssenceFarm.sol:EssenceFarm')
    const essenceFarm = await essenceFarmSource.deploy(gothContract.address);
    console.log('Essence Farm -', essenceFarm.address);

    // INITIALIZE EVENT LISTENERS
    await essenceFarm.on("Deposit", (sender, amount, farmId) => {
      console.log("Deposit Event: " + resolveAddress(sender) + " | Amount: " + ethers.utils.formatEther(amount) + " | Farm ID: " + farmId);
    });

    await essenceFarm.on("Withdraw", (sender, amount, farmId) => {
      console.log("Withdraw Event: " + resolveAddress(sender) + " | Amount: " + ethers.utils.formatEther(amount) + " | Farm ID: " + farmId);
    });

    await essenceFarm.on("EssenceClaimed", (sender, amount, farmId) => {
      console.log("Claim Event: " + resolveAddress(sender) + " | Essence: " + amount + " | Farm ID: " + farmId);
    });

    await essenceFarm.on("CalculateTest", (levelMod, share, time) => {
      console.log("Level Mod: " + levelMod + " | Share: " + share + " | time: " + time);
    });

    underscoreLog('Deployments completeted, now listening for Essence Farm events...', '');

    console.log(await essenceFarm.farmCount());

    // SETUP WALLET BALANCES & APPROVALS
    borderedLog('Setting Up Wallet Balances For Testing', '');

    await gothContract.connect(ownerWallet).transfer(testWallet.address, TenMillion);
    await gothContract.connect(ownerWallet).transfer(wallets[0].address, TenMillion);
    await gothContract.connect(ownerWallet).transfer(wallets[1].address, TenMillion);
    await gothContract.connect(ownerWallet).transfer(wallets[2].address, TenMillion);
    await gothContract.connect(ownerWallet).transfer(wallets[3].address, TenMillion);
    await gothContract.connect(ownerWallet).transfer(wallets[4].address, TenMillion);
    console.log('Transfered Dummy GSL To Test Wallets -', eParse(await gothContract.balanceOf(testWallet.address)));

    await gothContract.connect(testWallet).approve(essenceFarm.address, TenMillion);
    await gothContract.connect(wallets[0]).approve(essenceFarm.address, TenMillion);
    await gothContract.connect(wallets[1]).approve(essenceFarm.address, TenMillion);
    await gothContract.connect(wallets[2]).approve(essenceFarm.address, TenMillion);
    await gothContract.connect(wallets[3]).approve(essenceFarm.address, TenMillion);
    await gothContract.connect(wallets[4]).approve(essenceFarm.address, TenMillion);
    console.log('Approved Essence Farm To Spend Test Wallets GSL Balance -', eParse(await gothContract.allowance(testWallet.address, essenceFarm.address)));
    underscoreLog('Wallet setup complete...', '');

    // TEST ESSENCE FARM FUNCTIONALITY
    borderedLog('Initiating Farm Tests', '');

    underscoreLog('Test One - Deposit & Withdraw All', '');
    await essenceFarm.connect(testWallet).deposit(OneThousand, 0, options);
    console.log('Deposited into Earth Farm - Amount >', OneThousand);
    await essenceFarm.connect(wallets[0]).deposit(FiveHundred, 0, options);
    console.log('Deposited into Earth Farm - Amount >', FiveHundred);
    await essenceFarm.connect(wallets[1]).deposit(TenThousand, 0, options);
    console.log('Deposited into Earth Farm - Amount >', TenThousand);
    await essenceFarm.connect(wallets[2]).deposit(OneMillion, 0, options);
    console.log('Deposited into Earth Farm - Amount >', OneMillion);
    await essenceFarm.connect(wallets[3]).deposit(TenMillion, 0, options);
    console.log('Deposited into Earth Farm - Amount >', TenMillion);
    await essenceFarm.connect(wallets[4]).deposit(TenThousand, 0, options);
    console.log('Deposited into Earth Farm - Amount >', TenThousand);
    
    console.log('Waiting 30 seconds...');
    await delay(25);

    await essenceFarm.connect(testWallet).withdraw(OneThousand, 0, options);
    console.log('Withdrew from Earth Farm - Amount <', eParse(OneThousand));

    await delay(5);

    const info = await essenceFarm.connect(testWallet).farmInfo(0);
    underscoreLog('Total Staked:', '');
    console.log(eParse(info[0]));
    underscoreLog('Essence Accrued', '');
    //console.log(eParse(info[1]));
    console.log(info[1]);
    underscoreLog('Last Interaction:', '');
    console.log(parseTimestamp(info[2]));

    underscoreLog('Test Two - Deposit & Withdraw Some', '');
    await essenceFarm.connect(testWallet).deposit(OneThousand, 0, options);
    console.log('Deposited into Earth Farm - Amount >', OneThousand);
    
    console.log('Waiting 30 seconds...');
    await delay(25);

    await essenceFarm.connect(testWallet).withdraw(FiveHundred, 0, options);
    console.log('Withdrew from Earth Farm - Amount <', eParse(FiveHundred));

    await delay(5);

    const info2 = await essenceFarm.connect(testWallet).farmInfo(0);
    underscoreLog('Total Staked:', '');
    console.log(eParse(info2[0]));
    underscoreLog('Essence Accrued', '');
    //console.log(eParse(info2[1]));
    console.log(info2[1]);
    underscoreLog('Last Interaction:', '');
    console.log(parseTimestamp(info2[2]));

    console.log('Waiting 30 seconds...');
    await delay(25);

    await essenceFarm.connect(testWallet).withdraw(FiveHundred, 0, options);
    console.log('Withdrew from Earth Farm - Amount <', eParse(FiveHundred));

    await delay(5);

    const info3 = await essenceFarm.connect(testWallet).farmInfo(0);
    underscoreLog('Total Staked:', '');
    console.log(eParse(info3[0]));
    underscoreLog('Essence Accrued', '');
    console.log(eParse(info3[1]));
    underscoreLog('Last Interaction:', '');
    console.log(parseTimestamp(info3[2]));

}

function eParse (value)
{
    return ethers.utils.formatEther(value);
}

function borderedLog (msg, value)
{
  var bar = '||' + new Array(msg.length + value.length + 3).join('·') + '||';

  console.log(bar);
  console.log("|| " + msg, value + "||");
  console.log(bar);
}

function underscoreLog (msg, value)
{
  var under = new Array(msg.length + value.length + 1).join('‾');
  var over = new Array(msg.length + value.length + 1).join('_');
  console.log(over);
  console.log(msg, value);
  console.log(under);
}

function resolveAddress (address)
{
    if (address == '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266')
    {
        return 'Owner Wallet';
    }
    if (address == '0x70997970C51812dc3A010C7d01b50e0d17dc79C8')
    {
        return 'Test Wallet';
    }

    return address;
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