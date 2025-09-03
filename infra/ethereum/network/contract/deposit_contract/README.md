编译存款合约获得字节码：

npm install

npm hardhart compile


存款合约字节码在artifacts/contracts/DepositContract.sol/DepositContract.json中的deployedBytecode字段


部署执行节点后查看存款合约状态：

npx hardhat run scripts/check_status.js --network local




