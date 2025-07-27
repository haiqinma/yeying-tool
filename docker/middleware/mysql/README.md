
如何启动mysql容器？

第一步：创建环境变量，并修改配置
mv .env.sample .env 

第二步：在目录`init.db`中，添加初始化脚本，可以是创建数据库，以及授权给某个用户

第三步：启动容器
docker compose up -d

