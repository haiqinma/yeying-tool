const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("Deploying DepositContract...");

  // 获取部署账户
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // 获取当前 nonce
  const currentNonce = await deployer.getTransactionCount();
  console.log("当前 nonce:", currentNonce);

  // 部署合约
  const DepositContract = await ethers.getContractFactory("DepositContract");

  // 发送部署交易，但不等待确认
  console.log("发送部署交易...");
  const deployTx = await DepositContract.getDeployTransaction();
  
  // 手动发送交易
  const tx = await deployer.sendTransaction({
    ...deployTx,
    nonce: currentNonce,
    gasLimit: 2000000,
    gasPrice: ethers.utils.parseUnits("20", "gwei")
  });

  console.log("交易已发送:");
  console.log("交易哈希:", tx.hash);
  console.log("Nonce:", tx.nonce);

  // 计算合约地址
  const contractAddress = ethers.utils.getContractAddress({
    from: deployer.address,
    nonce: currentNonce
  });
  
  console.log("预计合约地址:", contractAddress);
  
  // 保存交易信息
  const deployInfo = {
    txHash: tx.hash,
    contractAddress: contractAddress,
    deployer: deployer.address,
    nonce: currentNonce,
    timestamp: new Date().toISOString(),
    status: "pending"
  };

  // 将地址写入文件
  const addressPath = path.join("/Users/liuxin2/.network/DevNet/config", "deposit_contract_address.txt");
  fs.writeFileSync(addressPath, contractAddress); 

  fs.writeFileSync("/Users/liuxin2/.network/DevNet/contracts/deploy-info.json", JSON.stringify(deployInfo, null, 2));
  return contractAddress;
}

main().then((address) => { process.exit(0); }).catch((error) => {
  console.error(error);
  process.exit(1);
});
