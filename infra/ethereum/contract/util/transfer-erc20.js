require('dotenv').config();
const { ethers } = require('ethers');

// ERC20 ABI
const ERC20_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)",
  "function balanceOf(address owner) view returns (uint256)"
];

async function main() {
  const rpcUrl = process.env.RPC_URL;
  const privateKey = process.env.PRIVATE_KEY;

  if (!rpcUrl || !privateKey) {
    console.error("Please set RPC_URL and PRIVATE_KEY in your .env file");
    process.exit(1);
  }

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  // 从命令行参数获取代币合约地址、目标地址和代币数量
  const tokenAddress = process.argv[2];
  const targetAddress = process.argv[3];
  const tokenAmount = process.argv[4];

  if (!tokenAddress || !targetAddress || !tokenAmount) {
    console.error("Usage: node transferERC20.js <tokenAddress> <targetAddress> <tokenAmount>");
    process.exit(1);
  }

  // 创建代币合约实例
  const tokenContract = new ethers.Contract(tokenAddress, ERC20_ABI, wallet);

  try {
    // 获取代币信息
    const decimals = await tokenContract.decimals();
    const symbol = await tokenContract.symbol();
    
    console.log(`Transferring ${tokenAmount} ${symbol} to ${targetAddress} from ${wallet.address}`);

    // 将代币数量转换为正确的单位
    const amountInTokenUnits = ethers.utils.parseUnits(tokenAmount, decimals);

    // 创建转账交易
    const tx = await tokenContract.transfer(targetAddress, amountInTokenUnits);

    console.log("Transaction hash:", tx.hash);

    // 等待交易被挖矿
    await tx.wait();

    console.log("Transaction confirmed");
  } catch (error) {
    console.error("Transfer failed:", error.message);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

