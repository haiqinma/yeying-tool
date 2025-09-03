import { ENR } from '@chainsafe/enr';

async function main() {
  // 你的 ENR 字符串
  let enrString = process.argv[2];

  // 自动去掉前缀
  if (enrString.startsWith('enr:')) {
    enrString = enrString.slice(4);
  }

  // 去掉空格和不可见字符
  enrString = enrString.trim();

  console.log(enrString);
  // 解析 ENR
  const enr = ENR.decode(enrString);

  console.log('=== ENR 解析结果 ===');
  console.log('IP:', enr.ip);
  console.log('TCP:', enr.tcp);
  console.log('UDP:', enr.udp);
  console.log('Public Key:', enr.publicKey?.toString('hex'));
  console.log('全部字段:', enr);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
