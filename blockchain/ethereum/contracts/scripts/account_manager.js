// account_manager.js
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Wallet } = require('@ethereumjs/wallet');
const { program } = require('commander');
const chalk = require('chalk');

class AccountManager {
    constructor(keystoreDir = 'accounts', passwordFile = null) {
        this.keystoreDir = path.resolve(keystoreDir);
        this.passwordFile = passwordFile || path.join(this.keystoreDir, 'password.txt');
        this.ensureDirectoryExists();
    }
    
    ensureDirectoryExists() {
        if (!fs.existsSync(this.keystoreDir)) {
            fs.mkdirSync(this.keystoreDir, { recursive: true });
            console.log(chalk.green(`✅ Created keystore directory: ${this.keystoreDir}`));
        }
    }
    
    // 生成随机密码
    generateRandomPassword(length = 32) {
        const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
        let password = '';
        for (let i = 0; i < length; i++) {
            password += charset.charAt(Math.floor(Math.random() * charset.length));
        }
        return password;
    }
    
    // 获取密码
    getPassword(customPassword = null) {
        if (customPassword) {
            return customPassword;
        }
        
        if (fs.existsSync(this.passwordFile)) {
            return fs.readFileSync(this.passwordFile, 'utf8').trim();
        }
        
        // 生成新密码
        const newPassword = this.generateRandomPassword();
        fs.writeFileSync(this.passwordFile, newPassword);
        fs.chmodSync(this.passwordFile, 0o600);
        console.log(chalk.yellow(`🔑 Generated new password and saved to: ${this.passwordFile}`));
        return newPassword;
    }
    
    // 创建新账户
    async createAccount(customPassword = null) {
        try {
            console.log(chalk.blue('🚀 Creating new account...'));
            
            const password = this.getPassword(customPassword);
            
            // 生成新钱包
            const wallet = Wallet.generate();
            
            // 创建 keystore (V3 格式)
            const keystore = await wallet.toV3(password);
            
            // 生成文件名
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', 'T').split('.')[0] + '.000000000Z';
            const address = wallet.getAddressString().slice(2).toLowerCase();
            const filename = `UTC--${timestamp}--${address}`;
            const keystorePath = path.join(this.keystoreDir, filename);
            
            // 保存 keystore 文件
            fs.writeFileSync(keystorePath, JSON.stringify(keystore, null, 2));
            fs.chmodSync(keystorePath, 0o600);
            
            const accountInfo = {
                address: wallet.getAddressString(),
                privateKey: wallet.getPrivateKeyString(),
                publicKey: wallet.getPublicKeyString(),
                keystoreFile: filename,
                keystorePath: keystorePath,
                keystoreDir: this.keystoreDir,
                createdAt: new Date().toISOString()
            };
            
            console.log(chalk.green('✅ Account created successfully:'));
            console.log(chalk.cyan('Address:'), accountInfo.address);
            console.log(chalk.cyan('Private Key:'), accountInfo.privateKey);
            console.log(chalk.cyan('Keystore File:'), filename);
            console.log(chalk.cyan('Keystore Path:'), keystorePath);
            
            return accountInfo;
            
        } catch (error) {
            console.error(chalk.red('❌ Error creating account:'), error.message);
            throw error;
        }
    }
    
    // 从 keystore 加载账户
    async loadAccount(keystoreFile = null, customPassword = null) {
        try {
            console.log(chalk.blue('📂 Loading account...'));
            
            const password = this.getPassword(customPassword);
            
            let keystorePath;
            
            if (keystoreFile) {
                // 如果提供了具体的 keystore 文件
                if (path.isAbsolute(keystoreFile)) {
                    keystorePath = keystoreFile;
                } else {
                    keystorePath = path.join(this.keystoreDir, keystoreFile);
                }
            } else {
                // 自动查找第一个 keystore 文件
                const files = fs.readdirSync(this.keystoreDir);
                const keystoreFiles = files.filter(file => file.startsWith('UTC--'));
                
                if (keystoreFiles.length === 0) {
                    throw new Error(`No keystore files found in ${this.keystoreDir}`);
                }
                
                if (keystoreFiles.length > 1) {
                    console.log(chalk.yellow('⚠️  Multiple keystore files found, using the first one:'));
                    keystoreFiles.forEach((file, index) => {
                        const marker = index === 0 ? '→' : ' ';
                        console.log(chalk.gray(`  ${marker} ${file}`));
                    });
                }
                
                keystorePath = path.join(this.keystoreDir, keystoreFiles[0]);
                keystoreFile = keystoreFiles[0];
            }
            
            if (!fs.existsSync(keystorePath)) {
                throw new Error(`Keystore file not found: ${keystorePath}`);
            }
            
            // 读取并解析 keystore
            const keystoreContent = fs.readFileSync(keystorePath, 'utf8');
            const keystoreJson = JSON.parse(keystoreContent);
            
            // 从 keystore 恢复钱包
            const wallet = await Wallet.fromV3(keystoreJson, password);
            
            const accountInfo = {
                address: wallet.getAddressString(),
                privateKey: wallet.getPrivateKeyString(),
                publicKey: wallet.getPublicKeyString(),
                keystoreFile: path.basename(keystorePath),
                keystorePath: keystorePath,
                keystoreDir: this.keystoreDir
            };
            
            console.log(chalk.green('✅ Account loaded successfully:'));
            console.log(chalk.cyan('Address:'), accountInfo.address);
            console.log(chalk.cyan('Private Key:'), accountInfo.privateKey);
            console.log(chalk.cyan('Keystore File:'), accountInfo.keystoreFile);
            
            return accountInfo;
            
        } catch (error) {
            console.error(chalk.red('❌ Error loading account:'), error.message);
            throw error;
        }
    }
    
    // 列出所有账户
    listAccounts() {
        try {
            console.log(chalk.blue(`📋 Listing accounts in: ${this.keystoreDir}`));
            
            if (!fs.existsSync(this.keystoreDir)) {
                console.log(chalk.yellow('⚠️  Keystore directory does not exist'));
                return [];
            }
            
            const files = fs.readdirSync(this.keystoreDir);
            const keystoreFiles = files.filter(file => file.startsWith('UTC--'));
            
            if (keystoreFiles.length === 0) {
                console.log(chalk.yellow('⚠️  No keystore files found'));
                return [];
            }
            
            console.log(chalk.green(`✅ Found ${keystoreFiles.length} account(s):`));
            
            keystoreFiles.forEach((file, index) => {
                try {
                    // 从文件名提取地址
                    const addressFromFilename = '0x' + file.split('--')[2];
                    
                    // 读取文件获取更多信息
                    const keystorePath = path.join(this.keystoreDir, file);
                    const keystoreContent = fs.readFileSync(keystorePath, 'utf8');
                    const keystoreJson = JSON.parse(keystoreContent);
                    const addressFromKeystore = '0x' + keystoreJson.address;
                    
                    console.log(chalk.cyan(`${index + 1}.`), {
                        address: addressFromKeystore,
                        file: file,
                        path: keystorePath,
                        version: keystoreJson.version || 'unknown'
                    });
                } catch (error) {
                    console.log(chalk.red(`${index + 1}. Error reading ${file}:`, error.message));
                }
            });
            
            return keystoreFiles;
            
        } catch (error) {
            console.error(chalk.red('❌ Error listing accounts:'), error.message);
            return [];
        }
    }
    
    // 导出账户信息
    async exportAccount(keystoreFile = null, outputFile = null, customPassword = null) {
        try {
            console.log(chalk.blue('📤 Exporting account...'));
            
            const accountInfo = await this.loadAccount(keystoreFile, customPassword);
            
            if (!outputFile) {
                outputFile = path.join(this.keystoreDir, 'exported_account.json');
            }
            
            const exportData = {
                ...accountInfo,
                exportedAt: new Date().toISOString(),
                warning: "⚠️ This file contains your private key. Keep it secure and never share it!"
            };
            
            fs.writeFileSync(outputFile, JSON.stringify(exportData, null, 2));
            fs.chmodSync(outputFile, 0o600);
            
            console.log(chalk.green('✅ Account exported successfully:'));
            console.log(chalk.cyan('Output file:'), outputFile);
            console.log(chalk.red('⚠️  Keep this file secure - it contains your private key!'));
            
            return exportData;
            
        } catch (error) {
            console.error(chalk.red('❌ Error exporting account:'), error.message);
            throw error;
        }
    }
    
    // 导入私钥创建新的 keystore
    async importPrivateKey(privateKey, customPassword = null) {
        try {
            console.log(chalk.blue('📥 Importing private key...'));
            
            // 清理私钥格式
            const cleanPrivateKey = privateKey.startsWith('0x') ? privateKey.slice(2) : privateKey;
            
            if (cleanPrivateKey.length !== 64) {
                throw new Error('Invalid private key length. Expected 64 hex characters.');
            }
            
            const password = this.getPassword(customPassword);
            
            // 从私钥创建钱包
            const privateKeyBuffer = Buffer.from(cleanPrivateKey, 'hex');
            const wallet = Wallet.fromPrivateKey(privateKeyBuffer);
            
            // 创建 keystore
            const keystore = await wallet.toV3(password);
            
            // 生成文件名
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', 'T').split('.')[0] + '.000000000Z';
            const address = wallet.getAddressString().slice(2).toLowerCase();
            const filename = `UTC--${timestamp}--${address}`;
            const keystorePath = path.join(this.keystoreDir, filename);
            
            // 检查是否已存在相同地址的账户
            if (fs.existsSync(keystorePath)) {
                console.log(chalk.yellow('⚠️  Account with this address already exists'));
            }
            
            // 保存 keystore 文件
            fs.writeFileSync(keystorePath, JSON.stringify(keystore, null, 2));
            fs.chmodSync(keystorePath, 0o600);
            
            const accountInfo = {
                address: wallet.getAddressString(),
                privateKey: wallet.getPrivateKeyString(),
                publicKey: wallet.getPublicKeyString(),
                keystoreFile: filename,
                keystorePath: keystorePath,
                keystoreDir: this.keystoreDir,
                importedAt: new Date().toISOString()
            };
            
            console.log(chalk.green('✅ Private key imported successfully:'));
            console.log(chalk.cyan('Address:'), accountInfo.address);
            console.log(chalk.cyan('Keystore File:'), filename);
            
            return accountInfo;
            
        } catch (error) {
            console.error(chalk.red('❌ Error importing private key:'), error.message);
            throw error;
        }
    }
    
    // 验证密码
    async verifyPassword(keystoreFile = null, testPassword = null) {
        try {
            console.log(chalk.blue('🔐 Verifying password...'));
            
            const password = testPassword || this.getPassword();
            
            let keystorePath;
            if (keystoreFile) {
                keystorePath = path.isAbsolute(keystoreFile) ? keystoreFile : path.join(this.keystoreDir, keystoreFile);
            } else {
                const files = fs.readdirSync(this.keystoreDir);
                const keystoreFiles = files.filter(file => file.startsWith('UTC--'));
                if (keystoreFiles.length === 0) {
                    throw new Error('No keystore files found');
                }
                keystorePath = path.join(this.keystoreDir, keystoreFiles[0]);
            }
            
            const keystoreContent = fs.readFileSync(keystorePath, 'utf8');
            const keystoreJson = JSON.parse(keystoreContent);
            
            // 尝试解密
            await Wallet.fromV3(keystoreJson, password);
            
            console.log(chalk.green('✅ Password is correct!'));
            return true;
            
        } catch (error) {
            if (error.message.includes('Key derivation failed')) {
                console.log(chalk.red('❌ Incorrect password'));
                return false;
            }
            console.error(chalk.red('❌ Error verifying password:'), error.message);
            throw error;
        }
    }
    
    // 更改密码
    async changePassword(keystoreFile = null, oldPassword = null, newPassword = null) {
        try {
            console.log(chalk.blue('🔄 Changing password...'));
            
            // 加载账户（使用旧密码）
            const accountInfo = await this.loadAccount(keystoreFile, oldPassword);
            
            if (!newPassword) {
                newPassword = this.generateRandomPassword();
                console.log(chalk.yellow('🔑 Generated new random password'));
            }
            
            // 从私钥重新创建钱包
            const privateKeyBuffer = Buffer.from(accountInfo.privateKey.slice(2), 'hex');
            const wallet = Wallet.fromPrivateKey(privateKeyBuffer);
            
            // 用新密码创建 keystore
            const newKeystore = await wallet.toV3(newPassword);
            
            // 备份原文件
            const backupPath = accountInfo.keystorePath + '.backup.' + Date.now();
            fs.copyFileSync(accountInfo.keystorePath, backupPath);
            
            // 保存新的 keystore
            fs.writeFileSync(accountInfo.keystorePath, JSON.stringify(newKeystore, null, 2));
            fs.chmodSync(accountInfo.keystorePath, 0o600);
            
            // 更新密码文件
            if (!oldPassword) {
                fs.writeFileSync(this.passwordFile, newPassword);
                fs.chmodSync(this.passwordFile, 0o600);
            }
            
            console.log(chalk.green('✅ Password changed successfully!'));
            console.log(chalk.cyan('Backup created:'), backupPath);
            console.log(chalk.yellow('🔑 New password saved to password file'));
            
            return {
                success: true,
                backupPath: backupPath,
                keystorePath: accountInfo.keystorePath
            };
            
        } catch (error) {
            console.error(chalk.red('❌ Error changing password:'), error.message);
            throw error;
        }
    }
    
    // 删除账户
    deleteAccount(keystoreFile = null, confirm = false) {
        try {
            console.log(chalk.blue('🗑️  Deleting account...'));
            
            let keystorePath;
            if (keystoreFile) {
                keystorePath = path.isAbsolute(keystoreFile) ? keystoreFile : path.join(this.keystoreDir, keystoreFile);
            } else {
                const files = fs.readdirSync(this.keystoreDir);
                const keystoreFiles = files.filter(file => file.startsWith('UTC--'));
                if (keystoreFiles.length === 0) {
                    throw new Error('No keystore files found');
                }
                keystorePath = path.join(this.keystoreDir, keystoreFiles[0]);
            }
            
            if (!fs.existsSync(keystorePath)) {
                throw new Error(`Keystore file not found: ${keystorePath}`);
            }
            
            if (!confirm) {
                console.log(chalk.red('⚠️  This action cannot be undone!'));
                console.log(chalk.yellow('Use --confirm flag to proceed with deletion'));
                return false;
            }
            
            // 创建备份
            const backupPath = keystorePath + '.deleted.' + Date.now();
            fs.copyFileSync(keystorePath, backupPath);
            
            // 删除原文件
            fs.unlinkSync(keystorePath);
            
            console.log(chalk.green('✅ Account deleted successfully!'));
            console.log(chalk.cyan('Backup created:'), backupPath);
            console.log(chalk.yellow('💡 You can restore from backup if needed'));
            
            return {
                success: true,
                deletedFile: keystorePath,
                backupPath: backupPath
            };
            
        } catch (error) {
            console.error(chalk.red('❌ Error deleting account:'), error.message);
            throw error;
        }
    }
    
    // 获取账户余额（需要连接到以太坊节点）
    async getBalance(address, rpcUrl = 'http://localhost:8545') {
        try {
            console.log(chalk.blue('💰 Getting balance...'));
            
            const response = await fetch(rpcUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    jsonrpc: '2.0',
                    method: 'eth_getBalance',
                    params: [address, 'latest'],
                    id: 1
                })
            });
            
            const data = await response.json();
            
            if (data.error) {
                throw new Error(data.error.message);
            }
            
            const balanceWei = BigInt(data.result);
            const balanceEth = Number(balanceWei) / Math.pow(10, 18);
            
            console.log(chalk.green('✅ Balance retrieved:'));
            console.log(chalk.cyan('Address:'), address);
            console.log(chalk.cyan('Balance:'), `${balanceEth} ETH`);
            console.log(chalk.cyan('Balance (Wei):'), balanceWei.toString());
            
            return {
                address: address,
                balanceWei: balanceWei.toString(),
                balanceEth: balanceEth,
                rpcUrl: rpcUrl
            };
            
        } catch (error) {
            console.error(chalk.red('❌ Error getting balance:'), error.message);
            throw error;
        }
    }
}

// CLI 命令行接口
function setupCLI() {
    program
        .name('account-manager')
        .description('Ethereum Account Manager using @ethereumjs/wallet')
        .version('1.0.0');

    program
        .option('-d, --keystore-dir <dir>', 'Keystore directory path', 'accounts')
        .option('-p, --password <password>', 'Custom password')
        .option('-f, --password-file <file>', 'Password file path');

    program
        .command('create')
        .description('Create a new account')
        .action(async (options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.createAccount(program.opts().password);
        });

    program
        .command('load')
        .description('Load an existing account')
        .option('-k, --keystore <file>', 'Specific keystore file to load')
        .action(async (options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.loadAccount(options.keystore, program.opts().password);
        });

    program
        .command('list')
        .description('List all accounts')
        .action(() => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            manager.listAccounts();
        });

    program
        .command('export')
        .description('Export account information')
        .option('-k, --keystore <file>', 'Specific keystore file to export')
        .option('-o, --output <file>', 'Output file path')
        .action(async (options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.exportAccount(
                options.keystore,
                options.output,
                program.opts().password
            );
        });

    program
        .command('import')
        .description('Import account from private key')
        .argument('<privateKey>', 'Private key to import')
        .action(async (privateKey) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.importPrivateKey(privateKey, program.opts().password);
        });

    program
        .command('verify')
        .description('Verify password for keystore')
        .option('-k, --keystore <file>', 'Specific keystore file to verify')
        .action(async (options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.verifyPassword(options.keystore, program.opts().password);
        });

    program
        .command('change-password')
        .description('Change account password')
        .option('-k, --keystore <file>', 'Specific keystore file')
        .option('--old-password <password>', 'Old password')
        .option('--new-password <password>', 'New password')
        .action(async (options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.changePassword(
                options.keystore,
                options.oldPassword,
                options.newPassword
            );
        });

    program
        .command('delete')
        .description('Delete an account')
        .option('-k, --keystore <file>', 'Specific keystore file to delete')
        .option('--confirm', 'Confirm deletion')
        .action((options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            manager.deleteAccount(options.keystore, options.confirm);
        });

    program
        .command('balance')
        .description('Get account balance')
        .argument('<address>', 'Account address')
        .option('--rpc <url>', 'RPC endpoint URL', 'http://localhost:8545')
        .action(async (address, options) => {
            const manager = new AccountManager(
                program.opts().keystoreDir,
                program.opts().passwordFile
            );
            await manager.getBalance(address, options.rpc);
        });

    return program;
}

// 如果直接运行此文件，启动 CLI
if (require.main === module) {
    const program = setupCLI();
    program.parse();
}

module.exports = { AccountManager, setupCLI };

