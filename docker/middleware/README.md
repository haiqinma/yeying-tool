

how to use postgresql in local docker?

在当前docker-compose.yml中配置外部命名网络
  psql-network:
    external: true
    name: psql-network

在当前服务中引入这个网络：
    networks:
      - psql-network

在服务的配置文件中使用配置<service name, like postgres>:<internal port>, 需要说明的是，postgresql服务没有绑定外部端口也能正常工作。

