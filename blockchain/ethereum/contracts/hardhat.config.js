require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // 本地开发网络
    localhost: {
      url: process.env.LOCALHOST_RPC_URL || "http://127.0.0.1:8545",
      chainId: parseInt(process.env.LOCALHOST_CHAIN_ID || "32380"),
      accounts: process.env.LOCALHOST_PRIVATE_KEY ? [process.env.LOCALHOST_PRIVATE_KEY] : [],
      gas: 2100000,
      gasPrice: 8000000000, // 8 Gwei
      timeout: 60000
    },
    // YeYing 网络
    YeYing: {
      url: process.env.DEVNET_RPC_URL,
      chainId: parseInt(process.env.DEVNET_CHAIN_ID),
      accounts: process.env.DEVNET_PRIVATE_KEY ? [process.env.DEVNET_PRIVATE_KEY] : [],
      gas: 2100000,
      gasPrice: 20000000000, // 20 Gwei
      timeout: 60000
    }
  },
  // Gas 报告
  gasReporter: {
    enabled: process.env.DEVNET_REPORT_GAS !== undefined,
    currency: "USD"
  },
  paths: {
    sources: "./contracts",
    tests: "./tests",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
