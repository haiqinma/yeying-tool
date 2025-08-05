# 生成节点的密钥
docker run --rm -v $PWD:/data wakuorg/go-waku:v0.9.0 generate-key --key-file /data/nodekey --key-password your_password

