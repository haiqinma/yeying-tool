require("@nomiclabs/hardhat-ethers");
const fs = require('fs');
const path = require('path');
const { Wallet } = require('ethers');

// 添加缓存
let cachedAccounts = null;

function loadKeystoreAccounts(keystoreDir, passwordFile) {
  if (cachedAccounts) {
    console.log("Using cached accounts");
    return cachedAccounts;
  }

  console.log("Loading keystore accounts...");
  try {
    const password = (fs.readFileSync(passwordFile, 'utf8')).trim();
    const files = fs.readdirSync(keystoreDir);
    
    const accounts = [];
    for (const file of files) {
      const keystorePath = path.join(keystoreDir, file);
      const keystore = fs.readFileSync(keystorePath, 'utf8');
      const wallet = Wallet.fromEncryptedJsonSync(keystore, password);
      accounts.push(wallet.privateKey);
    }
    return accounts;
  } catch (error) {
    console.error('Error loading keystore accounts:', error);
    return [];
  }
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.6.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    local: {
      url: "http://localhost:8545",
      accounts: loadKeystoreAccounts("/Users/liuxin2/.network/DevNet/accounts", "/Users/liuxin2/.network/DevNet/config/password.txt"),
      chainId: 5432,
      name: "DevNet"
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./tests",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
