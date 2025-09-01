如何启动minio服务？

1. 拷贝.env.template到.env，然后根据需要修改里面的参数，如果你想使用新密码，请使用common/generate_password.sh <password length>生成

2. 执行命令：docker compose up -d


使用nginx代理Web和API的方法：

1. 使用location /web/ 和 location / 来区分，前面的location代理web端访问，后面的location代理API访问
2. 启动容器配置环境变量MINIO_BROWSER_REDIRECT_URL=<url>/web


如何测试？

1. python3 -m venv venv
2. source venv/bin/activate
3. pip3 install minio
4. pip3 install dotenv
5. 配置.env文件
6. python3 test.py

