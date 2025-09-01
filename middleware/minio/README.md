如何启动minio服务？

1. 拷贝.env.template到.env，然后根据需要修改里面的参数，如果你想使用新密码，请使用common/generate_password.sh <password length>生成

2. 执行命令：docker compose up -d


如何测试？

1. python3 -m venv venv
2. source venv/bin/activate
3. pip3 install minio
4. pip3 install dotenv
5. 配置.env文件
6. python3 test.py

