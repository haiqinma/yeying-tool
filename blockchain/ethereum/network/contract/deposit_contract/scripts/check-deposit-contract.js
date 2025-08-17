const { ethers } = require("hardhat");

async function main() {
  // 读取合约地址
  const contractAddress = "0x1234123412341234123412341234123412341234";
  const depositContract = await ethers.getContractAt("DepositContract", contractAddress);

  console.log("=== 存款合约状态 ===");
  console.log("合约地址:", contractAddress);
  console.log("网络:", await ethers.provider.getNetwork());
  try {
    // 1. 获取存款计数
    const depositCount = await depositContract.get_deposit_count();
    console.log("总存款数量:", ethers.BigNumber.from(depositCount).toString());

    // 2. 获取存款根
    const depositRoot = await depositContract.get_deposit_root();
    console.log("存款根:", depositRoot);

    // 3. 检查合约余额
    const balance = await ethers.provider.getBalance(contractAddress);
    console.log("合约余额:", ethers.utils.formatEther(balance), "ETH");

    // 4. 获取最新区块信息
    const latestBlock = await ethers.provider.getBlockNumber();
    console.log("当前区块高度:", latestBlock);
    // 5. 监听存款事件
    console.log("\n=== 最近的存款事件 ===");
    const filter = depositContract.filters.DepositEvent();
    const events = await depositContract.queryFilter(filter, latestBlock - 1000, latestBlock);

    if (events.length > 0) {
      events.forEach((event, index) => {
        console.log("  公钥:", event.args.pubkey);
        console.log("  提取凭证:", event.args.withdrawal_credentials);
        console.log("  金额:", ethers.utils.formatEther(event.args.amount), "ETH");
        console.log("  签名:", event.args.signature);
        console.log("  区块:", event.blockNumber);
        console.log("  交易哈希:", event.transactionHash);
        console.log("---");
      });
    } else {
      console.log("暂无存款记录");
    }
  } catch (error) {
    console.error("查询合约状态失败:", error.message);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
