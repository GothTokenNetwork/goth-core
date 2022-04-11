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

    const moneyMakerSource = await ethers.getContractFactory('contracts/MoneyMaker.sol:MoneyMaker')
    const moneyMaker = await moneyMakerSource.deploy(
        '0x904420195b88D7483c46A97e13C3c76f5C4800a1', 
        '0x56d93478E96E3ca7faeAcd4E271104650406cae8', 
        '0x6110914Ad53FFb445579D49AD1C78592B6ca2B40',
        '0x5e6e168933f96e62d721982123c5a11b0e288440'
        )
    console.log('MoneyMaker deployed at...', moneyMaker.address)  

}

main()