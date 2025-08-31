echo "Python 脚手架"
echo "根据 yeying-idl 初始化 Flask 工程"
set -x

output_path=$1
if [ -z "$output_path" ]; then
    echo "生成错误，Flask工程目录不能为空"
    exit 1
else
    echo "您的Flask工程目录为: $output_path"
fi
if [ -d "$output_path" ]; then
    echo "生成错误，$output_path 该目录已存在，请重新指定Flask工程目录"
    exit 1
else
    echo "开始生成Flask工程"
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

# 生成 Flask 脚手架
npm install -g @openapitools/openapi-generator-cli
openapi-generator-cli version
dir_name=$(basename "$output_path")
export OPENAPI_GENERATOR_CLI_MIRROR=https://maven.aliyun.com/repository/public
openapi-generator-cli generate \
  -i "$output_path"/apidocs.openapi.json \
  -g python-flask \
  -o "$output_path" \
  --additional-properties=generatorVersion=7.14.0,projectName="$dir_name",packageVersion=0.1.0,packageName="$dir_name",supportPython2=false,serverPort=5000,apiPackage=apis,modelPackage=models,hideGenerationTimestamp=true,useConnexionMiddleware=true

tar -zcf "$output_path".tar.gz "$output_path"
#rm -rf "$output_path"
echo "$output_path".tar.gz
echo "生成的Flask工程路径：$output_path；请解压后使用"
set +x