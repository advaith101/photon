require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

INFURA_API_KEY = process.env.INFURA_API_KEY;
SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;
MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.5.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000,
          },
        },
      },
    ],
  },
  allowUnlimitedContractSize: true,
  networks: {
    hardhat: {
      forking: {
        url: process.env.MAINNET_RPC_URL,
      },
      chainId: 1,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [MAINNET_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
