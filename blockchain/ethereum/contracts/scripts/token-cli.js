// token-cli.js
const { ethers } = require('ethers');
const readline = require('readline');

// 创建命令行交互界面
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Erc20Token ABI (简化版，只包含我们需要的函数)
const tokenABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function owner() view returns (address)",
  "function mint(address to, uint256 amount)",
  "function burn(uint256 amount)",
  "event Transfer(address indexed from, address indexed to, uint256 value)"
];

// 全局变量
let provider;
let signer;
let tokenContract;
let userAddress;
let isOwner = false;
let tokenDecimals = 18; // 默认值，后续会从合约获取

// 主菜单
async function showMainMenu() {
  console.clear();
  console.log('=== Erc20 Token CLI Tool ===');
  console.log('1. Connect to Wallet');
  console.log('2. Show Token Information');
  console.log('3. Transfer Tokens');
  console.log('4. Mint Tokens (Owner Only)');
  console.log('5. Burn Tokens');
  console.log('6. Exit');
  console.log('===========================');
  
  if (signer) {
    console.log(`Connected Account: ${userAddress}`);
    if (isOwner) {
      console.log('You are the contract owner');
    }
  } else {
    console.log('Not connected to wallet');
  }
  
  rl.question('Select an option (1-6): ', async (answer) => {
    switch (answer) {
      case '1':
        await connectWallet();
        break;
      case '2':
        await showTokenInfo();
        break;
      case '3':
        await transferTokens();
        break;
      case '4':
        await mintTokens();
        break;
      case '5':
        await burnTokens();
        break;
      case '6':
        console.log('Exiting...');
        rl.close();
        process.exit(0);
        break;
      default:
        console.log('Invalid option. Please try again.');
        setTimeout(showMainMenu, 1000);
    }
  });
}

// 连接钱包
async function connectWallet() {
  console.clear();
  console.log('=== Connect to Wallet ===');
  
  rl.question('Enter RPC URL (e.g., http://localhost:8545 or https://sepolia.infura.io/v3/YOUR_API_KEY): ', async (rpcUrl) => {
    try {
      // 创建 provider
      provider = new ethers.JsonRpcProvider(rpcUrl);
      
      rl.question('Enter your private key: ', async (privateKey) => {
        try {
          // 创建 signer
          signer = new ethers.Wallet(privateKey, provider);
          userAddress = await signer.getAddress();
          
          console.log(`Connected as: ${userAddress}`);
          
          rl.question('Enter token contract address: ', async (contractAddress) => {
            try {
              // 创建合约实例
              tokenContract = new ethers.Contract(contractAddress, tokenABI, signer);
              
              // 获取代币小数位
              tokenDecimals = await tokenContract.decimals();
              
              // 检查是否是合约所有者
              const ownerAddress = await tokenContract.owner();
              isOwner = (ownerAddress.toLowerCase() === userAddress.toLowerCase());
              
              if (isOwner) {
                console.log('You are the contract owner');
              }
              
              console.log('Successfully connected to the token contract');
              setTimeout(() => {
                showMainMenu();
              }, 2000);
              
            } catch (error) {
              console.error('Error connecting to contract:', error.message);
              setTimeout(() => {
                connectWallet();
              }, 2000);
            }
          });
          
        } catch (error) {
          console.error('Error with private key:', error.message);
          setTimeout(() => {
            connectWallet();
          }, 2000);
        }
      });
      
    } catch (error) {
      console.error('Error connecting to RPC:', error.message);
      setTimeout(() => {
        connectWallet();
      }, 2000);
    }
  });
}

// 显示代币信息
async function showTokenInfo() {
  console.clear();
  console.log('=== Token Information ===');
  
  if (!tokenContract) {
    console.log('Not connected to a token contract. Please connect first.');
    setTimeout(() => {
      showMainMenu();
    }, 2000);
    return;
  }
  
  try {
    // 获取代币信息
    const name = await tokenContract.name();
    const symbol = await tokenContract.symbol();
    const decimals = await tokenContract.decimals();
    const totalSupply = await tokenContract.totalSupply();
    const userBalance = await tokenContract.balanceOf(userAddress);
    const ownerAddress = await tokenContract.owner();
    
    // 格式化数值
    const formattedTotalSupply = ethers.formatUnits(totalSupply, decimals);
    const formattedUserBalance = ethers.formatUnits(userBalance, decimals);
    
    console.log(`Token Name: ${name}`);
    console.log(`Token Symbol: ${symbol}`);
    console.log(`Decimals: ${decimals}`);
    console.log(`Total Supply: ${formattedTotalSupply} ${symbol}`);
    console.log(`Your Balance: ${formattedUserBalance} ${symbol}`);
    console.log(`Contract Owner: ${ownerAddress}`);
    console.log(`Your Address: ${userAddress}`);
    console.log(`Is Owner: ${isOwner ? 'Yes' : 'No'}`);
    
  } catch (error) {
    console.error('Error fetching token information:', error.message);
  }
  
  rl.question('\nPress Enter to return to main menu...', () => {
    showMainMenu();
  });
}

// 转账代币
async function transferTokens() {
  console.clear();
  console.log('=== Transfer Tokens ===');
  
  if (!tokenContract) {
    console.log('Not connected to a token contract. Please connect first.');
    setTimeout(() => {
      showMainMenu();
    }, 2000);
    return;
  }
  
  rl.question('Enter recipient address: ', (toAddress) => {
    if (!ethers.isAddress(toAddress)) {
      console.log('Invalid address format. Please try again.');
      setTimeout(() => {
        transferTokens();
      }, 2000);
      return;
    }
    
    rl.question(`Enter amount to transfer: `, async (amount) => {
      try {
        const amountFloat = parseFloat(amount);
        if (isNaN(amountFloat) || amountFloat <= 0) {
          console.log('Invalid amount. Please enter a positive number.');
          setTimeout(() => {
            transferTokens();
          }, 2000);
          return;
        }
        
        // 转换为 wei
        const amountWei = ethers.parseUnits(amount, tokenDecimals);
        
        // 检查余额
        const balance = await tokenContract.balanceOf(userAddress);
        if (balance < amountWei) {
          console.log('Insufficient balance for this transfer.');
          setTimeout(() => {
            transferTokens();
          }, 2000);
          return;
        }
        
        console.log(`Transferring ${amount} tokens to ${toAddress}...`);
        
        // 发送交易
        const tx = await tokenContract.transfer(toAddress, amountWei);
        console.log(`Transaction submitted: ${tx.hash}`);
        console.log('Waiting for confirmation...');
        
        // 等待交易确认
        const receipt = await tx.wait();
        console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed.toString()}`);
        
      } catch (error) {
        console.error('Error transferring tokens:', error.message);
      }
      
      rl.question('\nPress Enter to return to main menu...', () => {
        showMainMenu();
      });
    });
  });
}

// 铸造代币
async function mintTokens() {
  console.clear();
  console.log('=== Mint Tokens (Owner Only) ===');
  
  if (!tokenContract) {
    console.log('Not connected to a token contract. Please connect first.');
    setTimeout(() => {
      showMainMenu();
    }, 2000);
    return;
  }
  
  if (!isOwner) {
    console.log('Only the contract owner can mint tokens.');
    setTimeout(() => {
      showMainMenu();
    }, 2000);
    return;
  }
  
  rl.question('Enter recipient address: ', (toAddress) => {
    if (!ethers.isAddress(toAddress)) {
      console.log('Invalid address format. Please try again.');
      setTimeout(() => {
        mintTokens();
      }, 2000);
      return;
    }
    
    rl.question(`Enter amount to mint: `, async (amount) => {
      try {
        const amountFloat = parseFloat(amount);
        if (isNaN(amountFloat) || amountFloat <= 0) {
          console.log('Invalid amount. Please enter a positive number.');
          setTimeout(() => {
            mintTokens();
          }, 2000);
          return;
        }
        
        // 转换为 wei
        const amountWei = ethers.parseUnits(amount, tokenDecimals);
        
        console.log(`Minting ${amount} tokens to ${toAddress}...`);
        
        // 发送交易
        const tx = await tokenContract.mint(toAddress, amountWei);
        console.log(`Transaction submitted: ${tx.hash}`);
        console.log('Waiting for confirmation...');
        
        // 等待交易确认
        const receipt = await tx.wait();
        console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed.toString()}`);
        
      } catch (error) {
        console.error('Error minting tokens:', error.message);
      }
      
      rl.question('\nPress Enter to return to main menu...', () => {
        showMainMenu();
      });
    });
  });
}

// 销毁代币
async function burnTokens() {
  console.clear();
  console.log('=== Burn Tokens ===');
  
  if (!tokenContract) {
    console.log('Not connected to a token contract. Please connect first.');
    setTimeout(() => {
      showMainMenu();
    }, 2000);
    return;
  }
  
  rl.question(`Enter amount to burn: `, async (amount) => {
    try {
      const amountFloat = parseFloat(amount);
      if (isNaN(amountFloat) || amountFloat <= 0) {
        console.log('Invalid amount. Please enter a positive number.');
        setTimeout(() => {
          burnTokens();
        }, 2000);
        return;
      }
      
      // 转换为 wei
      const amountWei = ethers.parseUnits(amount, tokenDecimals);
      
      // 检查余额
      const balance = await tokenContract.balanceOf(userAddress);
      if (balance < amountWei) {
        console.log('Insufficient balance for this burn operation.');
        setTimeout(() => {
          burnTokens();
        }, 2000);
        return;
      }
      
      console.log(`Burning ${amount} tokens...`);
      
      // 发送交易
      const tx = await tokenContract.burn(amountWei);
      console.log(`Transaction submitted: ${tx.hash}`);
      console.log('Waiting for confirmation...');
      
      // 等待交易确认
      const receipt = await tx.wait();
      console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
      console.log(`Gas used: ${receipt.gasUsed.toString()}`);
      
    } catch (error) {
      console.error('Error burning tokens:', error.message);
    }
    
    rl.question('\nPress Enter to return to main menu...', () => {
      showMainMenu();
    });
  });
}

// 启动程序
console.log('Starting Erc20 Token CLI Tool...');
showMainMenu();

