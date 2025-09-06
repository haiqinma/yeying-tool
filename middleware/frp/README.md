
建议使用frp_0.64.0_linux_amd64.tar.gz 以及以上版本（20250906）
<通信端口>  server端和内网节点之间通信使用的端口
<代理端口>  需要暴露或者代理的的内网节点端口

server端节点的配置
1. sudo tar -zxf frp_<version>_linux_amd64.tar.gz -C /usr/local/frp-<代理端口>

2. cd /usr/local/frp-<代理端口>  更新frps.toml  
文件内容如下：
bindPort = <通信端口>

对应的服务配置文件/etc/systemd/system/frps-<代理端口>.service（文件需要创建）
[Unit]
Description = frp server s port <代理端口>
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/frp-<代理端口>/frps -c /usr/local/frp-<代理端口>/frps.toml

[Install]
WantedBy = multi-user.target


3. cd /usr/local/frp-<代理端口>  更新frpc.toml  
文件内容如下：
serverAddr = "127.0.0.1"
serverPort = <通信端口>

[[visitors]]
name = "secret_ssh_visitor"
type = "stcp"
serverName = "r730xd101"   # 根据实际情况进行修改
secretKey = "R|G~oSKL6W.;" # 根据实际情况进行修改，使用script/generate_password.sh生成密码，长度不低于12
bindAddr= "127.0.0.1"
bindPort = <代理端口>

对应的服务配置文件/etc/systemd/system/frpc-<代理端口>.service（文件需要创建）
[Unit]
Description = frp server c port <代理端口>
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/frp-<代理端口>/frpc -c /usr/local/frp-<代理端口>/frpc.toml

[Install]
WantedBy = multi-user.target


内网节点的配置
1. sudo tar -zxf frp_<version>_linux_amd64.tar.gz -C /usr/local/frp-<代理端口>

2. cd /usr/local/frp-<代理端口>  更新frpc.toml  
文件内容如下：
serverAddr = "<server端的公网ip>"
serverPort = <通信端口>

[[proxies]]
name = "r730xd101" # 根据实际情况进行修改， 与server端配置的serverName保持一致
type = "stcp"
secretKey = "R|G~oSKL6W.;" # 根据实际情况进行修改， 与server端配置的secretKey保持一致
localIP = "127.0.0.1"
localPort = <代理端口>


对应的服务配置文件/etc/systemd/system/frpc-<代理端口>.service（文件需要创建）
[Unit]
Description = frp port <代理端口>
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /usr/local/frp-<代理端口>/frpc -c /usr/local/frp-<代理端口>/frpc.toml

[Install]
WantedBy = multi-user.target


<last>
将上述配置的服务启动、验证、配置开机启动。
