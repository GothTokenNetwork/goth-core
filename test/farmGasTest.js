const console = require('console');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()
    var options = { gasPrice: 250000000000, gasLimit: 30000000 }
    let wallets = getWallets();
    const ownerWallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider)
    const testWallet = new ethers.Wallet('0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6', ethers.provider);

    // DEPLOY CONTRACTS
    console.log('Deploying Contracts', '');

    const gothSource = await ethers.getContractFactory('contracts/swap/OldGothToken.sol:OldGothToken')
    const gothContract = await gothSource.deploy();
    console.log('Dummy GSL Token -', gothContract.address);

    const essenceFarmSource = await ethers.getContractFactory('contracts/swap/farm/EssenceFarm.sol:EssenceFarm')
    const essenceFarm = await essenceFarmSource.deploy(gothContract.address);
    console.log('Essence Farm -', essenceFarm.address);
    
    await gothContract.connect(ownerWallet).transfer(testWallet.address, bParse('10000000'));
    console.log("totalUserLevels Gas Estimate", (await gothContract.connect(ownerWallet).estimateGas.transfer(testWallet.address, bParse('10000000'))).toString());
    await gothContract.connect(testWallet).approve(essenceFarm.address, bParse('10000000'));
    console.log("totalUserLevels Gas Estimate", (await gothContract.connect(testWallet).estimateGas.approve(essenceFarm.address, bParse('10000000'))).toString());

    console.log("Setting Up Events.....");
    await setupEvents(essenceFarm);

    await delay(5);


    console.log("baseMintRate Gas Estimate", (await essenceFarm.estimateGas.baseMintRate()).toString());

    console.log("baseMintRate Gas Estimate", (await essenceFarm.estimateGas.baseMintRate()).toString());
    console.log("totalUserLevels Gas Estimate", (await essenceFarm.estimateGas.totalUserLevels()).toString());
    console.log("setBaseMintRate Gas Estimate", (await essenceFarm.estimateGas.setBaseMintRate(bParse('1'))).toString());
    console.log("setPotionMaster Gas Estimate", (await essenceFarm.estimateGas.setPotionMaster(testWallet.address)).toString());
    console.log("potionMaster Gas Estimate", (await essenceFarm.estimateGas.potionMaster()).toString());
    console.log("setEmergencyBenefactor Gas Estimate", (await essenceFarm.estimateGas.setEmergencyBenefactor(testWallet.address)).toString());
    await essenceFarm.setEmergencyBenefactor(testWallet.address)
    console.log("emergencyBenefactor Gas Estimate", (await essenceFarm.estimateGas.emergencyBenefactor()).toString());

    console.log("userInfo Gas Estimate", (await essenceFarm.estimateGas.userInfo()).toString());
    console.log("forceLevelUpdate Gas Estimate", (await essenceFarm.estimateGas.forceLevelUpdate()).toString());
    console.log("farmAddress Gas Estimate", (await essenceFarm.estimateGas.farmAddress(0)).toString());
    console.log("farmerInfo Gas Estimate", (await essenceFarm.estimateGas.farmerInfo(0)).toString());
    console.log("farmCount Gas Estimate", (await essenceFarm.estimateGas.farmCount()).toString());
    console.log("farmBalance Gas Estimate", (await essenceFarm.estimateGas.farmBalance(0)).toString());
    console.log("farmBalanceOf Gas Estimate", (await essenceFarm.estimateGas.farmBalanceOf(0, testWallet.address)).toString());
    console.log("addFarm Gas Estimate", (await essenceFarm.estimateGas.addFarm("FARM", "FARM", 1, gothContract.address)).toString());
    await essenceFarm.addFarm("FARM", "FARM", 1, gothContract.address);
    console.log("removeFarm Gas Estimate", (await essenceFarm.estimateGas.removeFarm(5)).toString());
    console.log("emergencyRemove Gas Estimate", (await essenceFarm.estimateGas.emergencyRemove(0)).toString());

    console.log("deposit Gas Estimate", (await essenceFarm.connect(testWallet).estimateGas.deposit(bParse('1000000'), 0)).toString());
    await essenceFarm.connect(testWallet).deposit(bParse('1000000'), 0);
    console.log("withdraw Gas Estimate", (await essenceFarm.connect(testWallet).estimateGas.withdraw(bParse('10000'), 0)).toString());

    console.log("claimReward Gas Estimate", (await essenceFarm.estimateGas.claimReward(testWallet.address, 0)).toString());
}

main()

async function populateFarm (wallets, contract, gothContract, ownerWallet, options)
{
    for (let i = 0; i < wallets.length; i++) 
    {
        let number = getRndInteger(250000, 2000000);
        let textN = bParse(number.toString());
        await gothContract.connect(ownerWallet).transfer(wallets[i].address, textN);
        await approve(wallets[i], contract.address, textN, gothContract);
        await deposit(wallets[i], textN, 0, contract, options);
    }
}

async function GetEssenceBalances (wallets, contract, farmId)
{
    console.log("--| ---------------------------------------- |--");
    for (let i = 0; i < wallets.length; i++) 
    {
        console.log("Wallet " + i + " Essence Balance: ", eParse(await contract.farmBalanceOf(farmId, wallets[i].address)));
    }
    console.log("--| ---------------------------------------- |--");
}

async function getInfo (wallets, contract, options)
{
    for (let i = 0; i < wallets.length; i++) 
    {
        console.log("--| ---------------------------------------- |--");
        console.log("|| User & Farm Info Wallet " + i.toString() + " ||");
        let farmInfo = await getFarmerInfo(wallets[i], 0, contract);
        let userInfo = await getUserInfo(wallets[i], contract);

        console.log("--| User Level: " + userInfo[1].toString());
        console.log("--| Experience: " + userInfo[0].toString());
        console.log("--| Exp. Next: " + userInfo[2].toString());
        console.log("--| Staked: " + eParse(farmInfo[0]));
        console.log("--| Accumlated: " + eParse(farmInfo[1]));
        console.log("--| Last Interaction: " + parseTimestamp(farmInfo[2]));
        console.log("----| Reward To Claim: " + eParse(await getReward(wallets[i], contract, 0)));
        console.log("--| ---------------------------------------- |--");
        console.log("--| Claiming reward....");
        await claim(wallets[i], contract, 0);
        await delay(5);
        console.log("--| ---------------------------------------- |--");
    }
}

async function setupEvents (contract)
{
    await contract.on("Deposit", (var1, var2, var3) => {
    console.log("Deposit Event: | Sender: " + var1 + " | Amount: " + eParse(var2) + " | FarmID: " + var3);
    });   

    await contract.on("Withdraw", (var1, var2, var3) => {
    console.log("Withdraw Event: | Sender: " + var1 + " | Amount: " + eParse(var2) + " | FarmID: " + var3);
    });   

    await contract.on("ClaimReward", (var1, var2, var3) => {
    console.log("ClaimReward Event: | Sender: " + var1 + " | Amount: " + eParse(var2) + " | FarmID: " + var3);
    });  

    await contract.on("AddFarm", (var1, var2, var3, var4, var5) => {
    console.log("AddFarm Event: | Name: " + var1 + " | Symbol: " + var2 + " | Bonus: " + var3 + " | Pair Address: " + var3 + " | FarmID: " + var3);
    });  

    await contract.on("RemoveFarm", (var1, var2) => {
    console.log("RemoveFarm Event: | Message: " + var1 + " | FarmID: " + var2);
    }); 

    await contract.on("SetBaseMintRate", (var1) => {
    console.log("SetBaseMintRate Event: | New Mint Rate: " + eParse(var1));
    }); 

    await contract.on("IncrementExperience", (var1, var2, var3) => {
    console.log("IncrementExperience Event: | Sender: " + var1 + " | Experience: " + var2 + " | Level: " + var3);
    });   

    await contract.on("SetPotionMaster", (var1) => {
    console.log("SetPotionMaster Event: | New Potion Master: " + var1);
    }); 

    await contract.on("InstantEssencePayout", (var1, var2, var3) => {
    console.log("InstantEssencePayout Event: | FarmID: " + var1 + " | Amount: " + eParse(var2) + " | User: " + var3);
    });  

    await contract.on("ApplyBonusYield", (var1, var2, var3, var4, var5) => {
    console.log("ApplyBonusYield Event: | FarmID: " + var1 + " | Bonus: " + var2 + " | Expires: " + var3 + " | PotionID: " + var4 + " | User: " + var5);
    }); 

    await contract.on("ApplyFarmMorph", (var1, var2, var3, var4, var5) => {
    console.log("ApplyFarmMorph Event: | FarmID: " + var1 + " | Morph To: " + var2 + " | Expires: " + var3 + " | PotionID: " + var4 + " | User: " + var5);
    }); 

    await contract.on("ApplyExpBoost", (var1, var2, var3, var4, var5) => {
    console.log("ApplyExpBoost Event: | FarmID: " + var1 + " | Boost: " + var2 + " | Expires: " + var3 + " | PotionID: " + var4 + " | User: " + var5);
    }); 

    await contract.on("SetEmergencyBenefactor", (var1) => {
    console.log("SetEmergencyBenefactor Event: | New Benefactor: " + var1);
    });   
    
    await contract.on("EmergencyRemove", (var1, var2) => {
    console.log("EmergencyRemove Event: | Farm ID: " + var1 + " | Amount Removed: " + var2);
    }); 
}

async function claim (wallet, contract, farmId)
{
    await contract.connect(wallet).claimReward(wallet.address, farmId);
}

async function getReward (wallet, contract, farmId)
{
    let reward = await contract.connect(wallet).calculateReward(farmId);
    return reward;
}

async function getUserInfo (wallet, contract)
{
    let info = await contract.connect(wallet).userInfo();
    return info;
}

async function getFarmerInfo (wallet, farmId, contract)
{
    let info = await contract.connect(wallet).farmerInfo(farmId);
    return info;
}

function delay (n) {
    console.log('Waiting ' + n + ' seconds...');
    return new Promise(function (resolve) {
      setTimeout(resolve, n * 1000)
    })
}

function getRndInteger(min, max) 
{
    return Math.floor(Math.random() * (max - min) ) + min;
}

async function getFarmInfo ()
{

}

async function withdraw (wallet, amount, farmId, contract)
{

}

async function deposit (wallet, amount, farmId, contract, options)
{
    await contract.connect(wallet).deposit(amount, farmId, options);
}

async function approve (wallet, spender, amount, contract)
{
    await contract.connect(wallet).approve(spender, amount);
}

function bParse (value)
{
    return ethers.utils.parseUnits(value);
}

function eParse (value)
{
    return ethers.utils.formatEther(value);
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