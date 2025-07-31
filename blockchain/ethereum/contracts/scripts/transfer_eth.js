const { Web3 } = require('web3');
const fs = require('fs');
const path = require('path');

// 获取命令行参数
const args = process.argv.slice(2);
const options = parseArgs(args);

// 设置 Web3 提供者
const web3 = new Web3(options.rpc || 'http://localhost:8545');

async function main() {
    try {
        // 获取账户信息
        const account = await getAccount(options);
        console.log('✅ 账户加载成功!');
        console.log('账户地址:', account.address);
        
        // 检查目标地址
        if (!options.to) {
            console.error('错误: 未指定目标地址，请使用 --to 参数');
            process.exit(1);
        }
        
        // 检查目标地址格式
        if (!web3.utils.isAddress(options.to)) {
            console.error('错误: 无效的以太坊地址格式');
            process.exit(1);
        }
        
        // 发送交易
        await sendTransaction(account, options);
        
    } catch (error) {
        console.error('程序执行失败:', error.message);
        process.exit(1);
    }
}

// 解析命令行参数
function parseArgs(args) {
    const options = {
        amount: '1',       // 默认发送 1 ETH
        gasPrice: '20',    // 默认 gas 价格 20 Gwei
        unit: 'ether'      // 默认单位是 ether
    };
    
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        
        if (arg === '--keystore' && i + 1 < args.length) {
            options.keystore = args[++i];
        } else if (arg === '--password' && i + 1 < args.length) {
            options.password = args[++i];
        } else if (arg === '--privateKey' && i + 1 < args.length) {
            options.privateKey = args[++i];
        } else if (arg === '--to' && i + 1 < args.length) {
            options.to = args[++i];
        } else if (arg === '--amount' && i + 1 < args.length) {
            options.amount = args[++i];
        } else if (arg === '--unit' && i + 1 < args.length) {
            options.unit = args[++i];
        } else if (arg === '--gasPrice' && i + 1 < args.length) {
            options.gasPrice = args[++i];
        } else if (arg === '--rpc' && i + 1 < args.length) {
            options.rpc = args[++i];
        } else if (arg === '--help') {
            showHelp();
            process.exit(0);
        }
    }
    
    return options;
}

// 获取账户信息
async function getAccount(options) {
    // 优先使用私钥
    if (options.privateKey) {
        // 如果私钥不是以 0x 开头，添加前缀
        const privateKey = options.privateKey.startsWith('0x') 
            ? options.privateKey 
            : '0x' + options.privateKey;
            
        return web3.eth.accounts.privateKeyToAccount(privateKey);
    }
    
    // 其次使用 keystore
    if (options.keystore && options.password) {
        let keystore, password;
        
        try {
            // 尝试直接读取文件
            if (fs.existsSync(options.keystore)) {
                keystore = fs.readFileSync(options.keystore, 'utf8');
            } else {
                // 如果不是文件路径，假设是 JSON 字符串
                keystore = options.keystore;
            }
            
            // 尝试读取密码文件
            if (fs.existsSync(options.password)) {
                password = fs.readFileSync(options.password, 'utf8').trim();
            } else {
                // 如果不是文件路径，直接使用作为密码
                password = options.password;
            }
            
            return web3.eth.accounts.decrypt(keystore, password);
        } catch (error) {
            throw new Error(`无法解密 keystore: ${error.message}`);
        }
    }
    
    throw new Error('未提供有效的账户信息，请使用 --privateKey 或 --keystore 和 --password 参数');
}

// 发送交易
async function sendTransaction(account, options) {
    try {
        console.log(`准备发送 ${options.amount} ${options.unit} 到地址: ${options.to}`);
        
        // 获取 nonce
        const nonce = await web3.eth.getTransactionCount(account.address);
        console.log(`当前账户 nonce: ${nonce}`);
        
        // 获取当前网络 gas 价格
        let gasPrice;
        try {
            const networkGasPrice = await web3.eth.getGasPrice();
            console.log(`网络建议 gas 价格: ${web3.utils.fromWei(networkGasPrice, 'gwei')} Gwei`);
            gasPrice = options.gasPrice ? web3.utils.toWei(options.gasPrice, 'gwei') : networkGasPrice;
        } catch (error) {
            console.warn(`无法获取网络 gas 价格，使用默认值: ${options.gasPrice} Gwei`);
            gasPrice = web3.utils.toWei(options.gasPrice, 'gwei');
        }
        
        // 构建交易
        const tx = {
            from: account.address,
            to: options.to,
            value: web3.utils.toWei(options.amount, options.unit),
            gas: 21000, // 标准 ETH 转账的 gas 限制
            gasPrice: gasPrice,
            nonce: nonce
        };
        
        // 检查余额
        const balance = await web3.eth.getBalance(account.address);
        const totalCost = BigInt(tx.gas) * BigInt(tx.gasPrice) + BigInt(tx.value);
        
        if (BigInt(balance) < totalCost) {
            throw new Error(`余额不足。当前余额: ${web3.utils.fromWei(balance, 'ether')} ETH, 需要: ${web3.utils.fromWei(totalCost.toString(), 'ether')} ETH`);
        }
        
        console.log(`交易详情:`);
        console.log(`- 发送方: ${tx.from}`);
        console.log(`- 接收方: ${tx.to}`);
        console.log(`- 金额: ${web3.utils.fromWei(tx.value, 'ether')} ETH`);
        console.log(`- Gas 价格: ${web3.utils.fromWei(tx.gasPrice, 'gwei')} Gwei`);
        console.log(`- Gas 限制: ${tx.gas}`);
        
        // 签名交易
        console.log('正在签名交易...');
        const signedTx = await account.signTransaction(tx);
        
        // 发送交易
        console.log('正在发送交易...');
        const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
        
        console.log('\n✅ 交易成功!');
        console.log('- 交易哈希:', receipt.transactionHash);
        console.log('- 区块号:', receipt.blockNumber);
        console.log('- Gas 使用量:', receipt.gasUsed);
        
        // 计算交易费用
        const txFee = BigInt(receipt.gasUsed) * BigInt(tx.gasPrice);
        console.log('- 交易费用:', web3.utils.fromWei(txFee.toString(), 'ether'), 'ETH');
        
    } catch (error) {
        throw new Error(`交易失败: ${error.message}`);
    }
}

// 显示帮助信息
function showHelp() {
    console.log(`
以太坊交易工具 - 使用说明

选项:
  --privateKey <key>     直接使用私钥 (优先级高于 keystore)
  --keystore <path>      keystore 文件路径或 JSON 字符串
  --password <path>      密码文件路径或明文密码
  --to <address>         目标地址 (必需)
  --amount <number>      发送金额 (默认: 1)
  --unit <unit>          金额单位 (默认: ether, 可选: wei, gwei, ether)
  --gasPrice <gwei>      Gas 价格，单位为 Gwei (默认: 20)
  --rpc <url>            RPC 节点 URL (默认: http://localhost:8545)
  --help                 显示此帮助信息

示例:
  # 使用私钥发送 1 ETH
  node scripts/transfer_eth.js --privateKey 0x123... --to 0x456... --amount 1

  # 使用 keystore 发送 0.5 ETH
  node scripts/transfer_eth.js --keystore /path/to/keystore --password /path/to/password.txt --to 0x456... --amount 0.5
    `);
}

// 执行主函数
main();
