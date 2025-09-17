
# 登陆redis容器

docker compose exec redis sh

# 命令行模式
redis-cli

# 数据库操作
select 0                            # 切换数据库
flushdb                             # 清空当前数据库
flushall                            # 清空所有数据库
dbsize                              # 当前数据库键数量

# 查看键
keys *                              # 查看所有键（生产环境慎用）
keys user:*                         # 查看匹配模式的键
scan 0 match user:* count 100       # 安全地扫描键
exists mykey                        # 检查键是否存在
type mykey                          # 查看键的数据类型

# 字符串操作
get mykey   			    # 获取单个键的值
mget key1 key2 key3 		    # 获取多个键的值
getrange mykey 0 4  		    # 获取索引0到4的字符
