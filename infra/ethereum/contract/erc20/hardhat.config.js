require("@nomiclabs/hardhat-ethers");
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
      url: process.env.LOCAL_RPC_URL || "http://127.0.0.1:8545",
      chainId: parseInt(process.env.LOCAL_CHAIN_ID || "32323"),
      accounts: process.env.LOCAL_PRIVATE_KEY ? [process.env.LOCAL_PRIVATE_KEY] : [],
      gas: 2100000,
      gasPrice: 8000000000, // 8 Gwei
      timeout: 60000
    },
    // YeYing 网络
    YeYing: {
      url: process.env.YEYING_RPC_URL,
      chainId: parseInt(process.env.YEYING_CHAIN_ID || "5432"),
      accounts: process.env.YEYING_PRIVATE_KEY ? [process.env.YEYING_PRIVATE_KEY] : [],
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
