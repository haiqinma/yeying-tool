echo "Java 脚手架"
echo "根据 yeying-idl 初始化 spring-boot 工程"
set -x
current_dir=$(pwd)
output_path=$1
if [ -z "$output_path" ]; then
    echo "生成错误，spring-boot工程目录不能为空"
    exit 1
else
    echo "您的spring-boot工程目录为: $output_path"
fi
if [ -d "$output_path" ]; then
    echo "生成错误，$output_path 该目录已存在，请重新指定spring-boot工程目录"
    exit 1
else
    echo "开始生成spring-boot工程"
    mkdir -p "$output_path"
fi

go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
# 将 proto 定义 转换成 json 定义
go_path=$(go env GOPATH)

## 安装 swagger2openapi 命令
npm install -g swagger2openapi

## 生成合并的 json
protoc -I ../yeying-idl \
  -I "$go_path/pkg/mod" \
  --openapiv2_out . \
  --openapiv2_opt json_names_for_fields=true \
  --openapiv2_opt allow_merge=true \
  ../yeying-idl/yeying/api/**/*.proto

swagger2openapi apidocs.swagger.json -o apidocs.openapi.json
rm -f apidocs.swagger.json
mv apidocs.openapi.json "$output_path"/apidocs.openapi.json

# 生成 spring-boot 脚手架
npm install -g @openapitools/openapi-generator-cli
openapi-generator-cli version

export OPENAPI_GENERATOR_CLI_MIRROR=https://maven.aliyun.com/repository/public
openapi-generator-cli generate \
  -i "$output_path"/apidocs.openapi.json \
  -g spring \
  -o "$output_path" \
  --additional-properties=generatorVersion=7.14.0,repoUrl=https://maven.aliyun.com/repository/public,useSpringBoot3=True,java23=True,dateLibrary=java23,openApiNullable=False,library=spring-boot,jakarta=True,useJakartaEe=True,useTags=True,invokerPackage=com.yeying,apiPackage=com.yeying.api,modelPackage=com.yeying.model,configPackage=com.yeying.config

# 修改 java 版本到23
sed -i '' 's|<java.version>17</java.version>|<java.version>23</java.version>|g' "$output_path"/pom.xml
# 修改 spring-boot 版本 3.5.0
sed -i '' '/<parent>/,/<\/parent>/ s|<version>3.1.3</version>|<version>3.5.0</version>|' "$output_path"/pom.xml
cd "$current_dir"
pwd
cp community/openapi/java/README.md "$output_path/README.md"
cp community/openapi/java/runner.sh "$output_path/runner.sh"
pwd
tar -zcf "$output_path".tar.gz "$output_path"
#rm -rf "$output_path"
echo "$output_path".tar.gz
echo "生成的spring-boot工程路径：$output_path；请解压后使用"
set +x