如何部署多个节点？

1、先部署一个节点，如果多个节点不在一台机器上，一定要修改`.env`文件中的NAT_IP为外网IP
2、第一个节点做为bootnode，需要把生成的config/enode.txt 和config/beacon_enr.txt拷贝到其他机器上
3、拷贝执行层创世文件data/execution/genesis.json到其他机器上
4、拷贝共识层创始文件data/consensus/config.yaml和data/consensus/genesis.ssz到其他机器上
