const console = require('console');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');

async function main() {
    ;[owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners()

    var options = { gasPrice: 250000000000, gasLimit: 30000000 }
    const ownerWallet = new ethers.Wallet('fc22cb995181f45fc0d9bf6a26bd686bcc30c6e1a2c0e02df08497809ba84931', ethers.provider)

    const wallets = getWallets();

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
    console.log('Arcane Weaver -', arcaneWeaver.address);
    
    
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