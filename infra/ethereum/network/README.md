# 部署

1.安装docker、python3.12、go、node24等工具, 执行如下命令：


./install_dependency.sh

注意，安装完依赖以后，执行命令source ~/.bashrc 或者 source ~/.zshrc，确保环境变量生效。

2.拷贝 .env.template 到 .env 根据需要修改里面的参数，然后如下执行命令，如果之前部署过，这个命令会清理掉之前的数据。

./config/setup-config.sh

3.启动网络节点，包括geth、beacon、validator服务，执行如下命令:

./start-network.sh



# 流程详解：

## 1.部署创世节点

准备工作：一定要修改`.env`文件中的NAT_IP为外网IP

1、部署执行节点geth
2、部署存款合约，验证者需要通过存款合约质押ETH，从而参与共识
3、部署共识节点beacon
4、部署验证节点validator, 确保验证者有足够ETH

## 2.部署入网节点

准备工作：一定要修改`.env`文件中的NAT_IP为外网IP

1、准备工作，执行层创世文件data/execution/genesis.json、启动节点config/enode.txt，共识层配置文件data/consensus/config.yaml、创世文件data/consensus/genesis.ssz、启动节点config/beacon_enr.txt；
2、部署执行节点geth
3、部署共识节点prysm
4、部署验证节点validator，确保验证者有足够ETH

# 质押ETH

1、准备阶段：生成验证者密钥对；设置提取地址（你的以太坊地址）；准备32 ETH
2、存款阶段：调用存款合约；发送32 ETH到存款合约；提交验证者公钥和存款数据
3、激活阶段：信标链检测到存款；验证者进入激活队列；等待激活（可能需要几天到几周）
4、验证阶段：验证者开始参与共识；获得质押奖励；承担惩罚风险；

如何连接到执行节点？
geth attach ${HOME}/.network/<network name>/execution/geth.ipc


# 问题汇总

## 当前重启beacon节点无法恢复

整个geth的无法正常出块，beacon chain的日志如下：level=error msg="Could not compute head from new attestations" error="0x577fda890fb731bff1a2d28a89e8106a0b88e208624d699940ff4daa723b7ea6: unknown justified root" prefix=blockchain

解决方案：清理掉数据从其他节点同步恢复

## beacon节点连接超过上限

time="2025-09-15 01:15:13" level=debug msg="Initiate peer disconnection" direction=Inbound error="peer is from a bad IP: collocation limit exceeded: got 9 - limit 5" multiaddr="/ip4/10.15.10.72/udp/13000/quic-v1/p2p/16Uiu2HAmBWU53j1n4qTwVpMGxBKL9558VpVagZ9ZFVfueZ95Eb5M" prefix=p2p remainingActivePeers=0

通过脚本 `beacon/get-peer.sh` 确认是否操作上限；
使用参数 `--p2p-static-id` 生成beacon的密钥，固定peer id；


