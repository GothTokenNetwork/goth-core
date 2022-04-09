import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "hardhat-tracer";
import { task, HardhatUserConfig } from "hardhat/config";
import "ts-node/register";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const FUJI_PRIVATE_KEY = process.env.FUJI_PRIVATE_KEY

if(typeof process.env.FUJI_PRIVATE_KEY === 'undefined') {
    throw new Error('The FUJI_PRIVATE_KEY variable is not defined in the environment.\n'
        + 'This can be set to a dummy value if you are not deploying to Fuji.')
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.5.16"
      },
      {
        version: "0.6.2"
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      },
      {
        version: "0.7.0"
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      },
       {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      },
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      },
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          outputSelection: {
            "*": {
                "*": ["storageLayout"],
            },
          },
        }
      }
    ]
  },
  networks: {
    localhost: {
      gasPrice: 470000000000,
      chainId: 43114,
      url: "http://127.0.0.1:8545/ext/bc/C/rpc"
    },
    hardhat: {
      gasPrice: 470000000000,
      chainId: 43114,
      initialDate: "2020-10-10",
      forking: {
        url: 'https://api.avax.network/ext/bc/C/rpc', 
        enabled: true
      },
      accounts: {
        accountsBalance: "1000000000000000000000000000000", 
        count: 50
      }
    },
    avash: {
      url: 'http://localhost:9650/ext/bc/C/rpc',
      gasPrice: 470000000000,
      chainId: 43112,
      accounts: ["0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027"]
    },
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      gasPrice: 470000000000,
      chainId: 43113,
      accounts: ["fc22cb995181f45fc0d9bf6a26bd686bcc30c6e1a2c0e02df08497809ba84931"]
    },
    mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gasPrice: 470000000000,
      chainId: 43114,
      accounts: []
    }
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  gasReporter: {
    currency: 'USD',
    token: 'AVAX',
    enabled: true,
    showTimeSpent: true, 
    gasPrice: 41,
    src: 'contracts'
  },
};

export default config;
