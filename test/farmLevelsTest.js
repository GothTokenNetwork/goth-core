const console = require('console');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');

async function main() 
{

    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()

    const price = ethers.utils.formatUnits(await ethers.provider.getGasPrice(), 'gwei')
    const options = {gasLimit: 10000000, gasPrice: ethers.utils.parseUnits(price, 'gwei')}

    const ownerWallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', ethers.provider)
    const testWallet = new ethers.Wallet('0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6', ethers.provider);

    console.log('----------------------------------------');

    
}

async function setupFarmEvents (contract)
{
    await contract.on("Deposit", (var1, var2, var3) => {
        console.log("Deposit Event: | Sender: " + var1 + " | Amount: " + eParse(var2) + " | FarmID: " + var3);
        });   

    await contract.on("Withdraw", (var1, var2, var3) => {
        console.log("Withdraw Event: | Sender: " + var1 + " | Amount: " + eParse(var2) + " | FarmID: " + var3);
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


    await contract.on("SetEmergencyBenefactor", (var1) => {
        console.log("SetEmergencyBenefactor Event: | New Benefactor: " + var1);
        });   
    
    await contract.on("EmergencyRemove", (var1, var2) => {
        console.log("EmergencyRemove Event: | Farm ID: " + var1 + " | Amount Removed: " + var2);
        }); 

    await contract.on("ClaimReward", (var1, var2, var3) => {
        console.log("ClaimReward Event: | Sender: " + var1 + " | Amount: " + eParse(var2) + " | FarmID: " + var3);
        });  
}

function setupUserLevelsEvents (contract)
{
        
    await contract.on("ApplyExpBoost", (var1, var2, var3, var4, var5) => {
        console.log("ApplyExpBoost Event: | FarmID: " + var1 + " | Boost: " + var2 + " | Expires: " + var3 + " | PotionID: " + var4 + " | User: " + var5);
        }); 

    await contract.on("IncrementExperience", (var1, var2, var3) => {
        console.log("IncrementExperience Event: | Sender: " + var1 + " | Experience: " + var2 + " | Level: " + var3);
        });   

    await contract.on("SetPotionMaster", (var1) => {
        console.log("SetPotionMaster Event: | New Potion Master: " + var1);
        }); 

    event SetAccessor(address accessor);
    event RevokeAccessor(address revoked);
    event LevelUp(address user, uint256 level, uint256 experienceRequired);
    event PotionEffectExpired(address user, string potionId);
}

main()