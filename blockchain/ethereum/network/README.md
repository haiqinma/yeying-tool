安装依赖？

执行./install_dependency.sh

Docker
Python3.12
Go
Node24

注意，安装完依赖以后，执行命令source ~/.bashrc 或者 source ~/.zshrc，确保环境变量生效

如何部署eth2？

部署创世节点

准备工作：一定要修改`.env`文件中的NAT_IP为外网IP

1、部署执行节点geth
2、部署存款合约，验证者需要通过存款合约质押ETH，从而参与共识
3、部署共识节点beacon
4、部署验证节点validator, 确保验证者有足够ETH

部署入网节点

准备工作：一定要修改`.env`文件中的NAT_IP为外网IP

1、准备工作，执行层创世文件data/execution/genesis.json、启动节点config/enode.txt，共识层配置文件data/consensus/config.yaml、创世文件data/consensus/genesis.ssz、启动节点config/beacon_enr.txt；
2、部署执行节点geth
3、部署共识节点prysm
4、部署验证节点validator，确保验证者有足够ETH

如何质押ETH？

1、准备阶段：生成验证者密钥对；设置提取地址（你的以太坊地址）；准备32 ETH
2、存款阶段：调用存款合约；发送32 ETH到存款合约；提交验证者公钥和存款数据
3、激活阶段：信标链检测到存款；验证者进入激活队列；等待激活（可能需要几天到几周）
4、验证阶段：验证者开始参与共识；获得质押奖励；承担惩罚风险；

如何连接到执行节点？
geth attach ${HOME}/.network/<network name>/execution/geth.ipc


当前重启节点存在问题？

整个geth的无法正常出块，beacon chain的日志如下：level=error msg="Could not compute head from new attestations" error="0x577fda890fb731bff1a2d28a89e8106a0b88e208624d699940ff4daa723b7ea6: unknown justified root" prefix=blockchain

