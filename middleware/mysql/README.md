
如何启动mysql容器？

第一步：创建环境变量，并修改配置
mv .env.template .env 

第二步：在目录`init.db`中，添加初始化脚本，可以是创建数据库，以及授权给某个用户

第三步：启动容器
docker compose up -d

如何新建数据库？

1. 进入容器
docker compose exec mysql bash

2. 登录，以root用户登录
mysql -h localhost -u root -p

3. 建库，例如建库bookstack
create database bookstack

4. 授权，授权数据库给用户，例如将bookstack授权给yiying用户
GRANT ALL PRIVILEGES ON bookstack.* TO 'yeying'@'%';

5. 查看数据库的所有者
select * from information_schema.SCHEMA_PRIVILEGES;


