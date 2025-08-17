require('dotenv').config();
const { ethers } = require('ethers');

async function main() {
  const rpcUrl = process.env.YEYING_RPC_URL;
  const privateKey = process.env.YEYING_PRIVATE_KEY;

  if (!rpcUrl || !privateKey) {
    console.error("Please set RPC_URL and PRIVATE_KEY in your .env file");
    process.exit(1);
  }

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  // 从命令行参数获取目标地址和ETH数量
  const targetAddress = process.argv[2];
  const ethAmount = process.argv[3];

  if (!targetAddress || !ethAmount) {
    console.error("Usage: node transfer.js <targetAddress> <ethAmount>");
    process.exit(1);
  }

  console.log(`Transferring ${ethAmount} ETH to ${targetAddress} from ${wallet.address}`);

  // 将 ETH 数量转换为 wei
  const amountInWei = ethers.utils.parseEther(ethAmount);

  // 创建交易
  const tx = await wallet.sendTransaction({
    to: targetAddress,
    value: amountInWei,
  });

  console.log("Transaction hash:", tx.hash);

  // 等待交易被挖矿
  await tx.wait();

  console.log("Transaction confirmed");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
