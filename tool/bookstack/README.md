
部署bookstack

1. 拷贝.env.template到.env
2. 配置数据库
3. 配置密钥（可以使用script/generate_key.sh生成）并上前缀base64:
4. docker compose up -d

初始化工作

1. 部署成功后，需要使用默认管理员登陆（admin@admin.com/password）
2. 修改管理员密码和邮箱信息
3. 通过管理配置是否能够注册、角色权限、应用描述等信息。
