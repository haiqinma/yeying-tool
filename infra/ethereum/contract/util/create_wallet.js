const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

/**
 * 生成指定数量的以太坊钱包
 * @param {number} count - 要生成的钱包数量
 */
function generateWallets(count = 1) {
    // 生成时间戳
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const filename = `wallets_${timestamp}.txt`;
    const filepath = path.join(__dirname, filename);
    
    console.log(`正在生成 ${count} 个钱包...`);
    console.log(`结果将保存到: ${filename}\n`);
    
    let output = `以太坊钱包生成结果\n生成时间: ${new Date().toLocaleString()}\n生成数量: ${count}\n${'='.repeat(80)}\n\n`;
    
    for (let i = 1; i <= count; i++) {
        try {
            // 生成随机钱包
            const wallet = ethers.Wallet.createRandom();
            
            const walletInfo = `钱包 #${i}:\n` +
                             `助记词: ${wallet.mnemonic.phrase}\n` +
                             `地址:   ${wallet.address}\n` +
                             `私钥:   ${wallet.privateKey}\n` +
                             `${'-'.repeat(80)}\n\n`;
            
            // 输出到控制台
            console.log(walletInfo);
            
            // 添加到输出字符串
            output += walletInfo;
            
        } catch (error) {
            const errorMsg = `生成钱包 #${i} 时出错: ${error.message}\n\n`;
            console.error(errorMsg);
            output += errorMsg;
        }
    }
    
    // 写入文件
    try {
        fs.writeFileSync(filepath, output, 'utf8');
        console.log(`\n✅ 成功生成 ${count} 个钱包并保存到 ${filename}`);
    } catch (error) {
        console.error(`❌ 保存文件时出错: ${error.message}`);
    }
}

/**
 * 从命令行参数获取钱包数量
 */
function getWalletCount() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        return 1; // 默认生成1个钱包
    }
    
    const count = parseInt(args[0]);
    
    if (isNaN(count) || count <= 0) {
        console.error('❌ 请输入有效的钱包数量（正整数）');
        process.exit(1);
    }
    
    if (count > 1000) {
        console.warn('⚠️  生成大量钱包可能需要较长时间');
    }
    
    return count;
}

// 主程序
function main() {
    console.log('🔐 以太坊钱包生成器\n');
    
    const count = getWalletCount();
    generateWallets(count);
    
    console.log('\n⚠️  安全提醒:');
    console.log('1. 请妥善保管助记词和私钥');
    console.log('2. 不要在不安全的环境中运行此脚本');
    console.log('3. 建议在离线环境中生成钱包');
    console.log('4. 及时删除或加密保存生成的文件');
}

// 运行主程序
if (require.main === module) {
    main();
}

module.exports = { generateWallets };

