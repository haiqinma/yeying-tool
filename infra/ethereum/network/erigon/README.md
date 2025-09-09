
# 查看erigon命令行参数

docker run --rm erigontech/erigon:latest help


# 用户和用户组

容器启动的时候使用的erigon账户, uid和gid是1000，在指定要挂载的宿主机目录时，需要修改目录的所有者，使用如下命令:
sudo chown -R 1000:1000 <./data>



