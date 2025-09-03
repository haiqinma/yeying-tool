echo "typescript-express 脚手架"
echo "根据 yeying-idl 初始化 typescript-express 工程"
set -x
current_dir=$(pwd)
output_path=$1
if [ -z "$output_path" ]; then
    echo "生成错误，typescript-express工程目录不能为空"
    exit 1
else
    echo "您的typescript-express工程目录为: $output_path"
fi
if [ -d "$output_path" ]; then
    echo "生成错误，$output_path 该目录已存在，请重新指定typescript-express工程目录"
    exit 1
else
    echo "开始生成typescript-express工程"
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
cp apidocs.openapi.json "$output_path"/apidocs.openapi.json
cp apidocs.openapi.json script/typescript//apidocs.openapi.json

# 生成 typescript-express 脚手架
echo "初始化 typescript-express 工程"
cp script/typescript/package.json "$output_path"/

dir_name=$(basename "$output_path")
sed -i '' "s/\${sdk_name}/$dir_name/g" "$output_path/package.json"
cd "$output_path"
pwd
# 安装生产依赖
npm install express
# 安装开发依赖
npm install --save-dev typescript ts-node @types/express @types/node nodemon
npm install @openapi-generator-plus/typescript-express-passport-server-generator
npm install -g openapi-generator-plus
openapi-generator-plus -c "$current_dir/script/typescript/config.yaml"
cd "$current_dir"
pwd
mv script/typescript/src "$output_path/"
cp script/typescript/tsconfig.json "$output_path/tsconfig.json"
cp script/typescript/server.ts "$output_path/src/server.ts"
pwd

cd "$output_path"

pwd

npm run build
echo "$output_path".tar.gz
echo "生成的typescript-express工程路径：$output_path"
set +x