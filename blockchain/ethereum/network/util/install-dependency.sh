#!/bin/bash

set -e

# 导入通用配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source ${PARENT_DIR}/share/common.sh

# 检测系统
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
PYTHON_VERSION=3.12
GO_VERSION=1.24.2
GETH_VERSION=v1.16.2
PRYSM_VERSION=v6.0.3
ETH2_VAL_TOOLS_VERSION=v0.1.1

echo "proxy=${CURL_PROXY}"

case $ARCH in
x86_64) ARCH="amd64" ;;
aarch64 | arm64) ARCH="arm64" ;;
armv7l) ARCH="arm" ;;
*)
    echo "❌ Unsupported architecture: $ARCH"
    return 1
    ;;
esac

printf "\033[32m[INFO]\033[0m Setting up Ethereum PoS Private Network on macOS...\n"

# 检查是否为 macOS 或 Ubuntu/Linux
if [[ "$(uname)" != "Darwin" && "$(uname)" != "Linux" ]]; then
    printf "\033[31m[ERROR]\033[0m This script is designed for macOS and Ubuntu/Linux only\n"
    exit 1
fi

# 检查并安装 make 命令
if ! command -v make &> /dev/null; then
    printf "\033[33m[WARNING]\033[0m make command not found, installing...\n"
    if [[ "$(uname)" == "Darwin" ]]; then
        xcode-select --install
    elif [[ "$(uname)" == "Linux" ]]; then
        sudo apt-get update && sudo apt-get install -y build-essential
    fi
fi

# 更新配置文件中的PATH环境变量
update_path() {
    local profile_file=$1
    local path_to_add=$2
    local comment=$3

    # 构建PATH更新行
    local path_line="export PATH=\$PATH:${path_to_add}"

    # 检查文件是否存在
    if [ -f "$profile_file" ]; then
        # 检查是否已经包含该路径
        if grep -q "export PATH=.*${path_to_add}" "$profile_file"; then
            printf "\033[33m[INFO]\033[0m %s already contains path: %s\n" "$profile_file" "$path_to_add"
        else
            printf "\033[32m[INFO]\033[0m Adding %s to PATH in %s\n" "$path_to_add" "$profile_file"
            echo "" >> "$profile_file"
            echo "# $comment" >> "$profile_file"
            echo "$path_line" >> "$profile_file"
        fi
    fi
}

install_python() {
    local MAJOR_VERSION=$(echo ${PYTHON_VERSION} | cut -d. -f1-2)

    # 检查Python是否已安装
    if command -v python${MAJOR_VERSION} &> /dev/null; then
        local INSTALLED_VERSION=$(python${MAJOR_VERSION} --version 2>&1 | cut -d' ' -f2)
        printf "\033[33m[INFO]\033[0m Python ${INSTALLED_VERSION} is already installed\n"
        return 0
    fi

    printf "\033[32m[INFO]\033[0m Installing Python ${PYTHON_VERSION}...\n"

    # 根据系统选择安装方法
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        echo "📦 Installing Python ${MAJOR_VERSION} using apt..."
        sudo apt-get update
        sudo apt-get install -y python${MAJOR_VERSION} python${MAJOR_VERSION}-venv python3-pip
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        echo "📦 Installing Python ${MAJOR_VERSION} using yum..."
        if command -v dnf &> /dev/null; then
            # RHEL/CentOS 8+
            sudo dnf install -y python${MAJOR_VERSION} python${MAJOR_VERSION}-pip
        else
            # RHEL/CentOS 7
            sudo yum install -y epel-release
            sudo yum install -y python${MAJOR_VERSION} python${MAJOR_VERSION}-pip
        fi
    elif command -v brew &> /dev/null; then
        # macOS with Homebrew
        echo "📦 Installing Python ${PYTHON_VERSION} using Homebrew..."
        brew install python@${MAJOR_VERSION}
    else
        # 如果没有找到包管理器
        echo "📦 No system package manager found, using pyenv..."
        return 1
    fi

    # 验证安装
    echo "🔍 Verifying Python installation..."
    if command -v python${MAJOR_VERSION} &> /dev/null; then
        echo "✅ Python $(python${MAJOR_VERSION} --version 2>&1) successfully installed!"
    else
        echo "❌ Python installation verification failed"
        return 1
    fi
}

# 安装GO
install_go() {
    printf "\033[32m[INFO]\033[0m Installing Go ${GO_VERSION}...\n"

    # 构建文件名和下载URL
    local FILENAME="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"

    # 获取当前 Go 版本
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')

    # 检查版本
    if [ "$CURRENT_VERSION" == "$GO_VERSION" ]; then
        printf "\033[33m[INFO]\033[0m Go ${GO_VERSION} is already installed\n"
        return 0
    fi

    # 检查是否已经下载过
    if [[ -f "${DOWNLOAD_DIR}/${FILENAME}" ]]; then
        printf "\033[33m[WARN]\033[0m Go already downloaded: ${GO_VERSION}\n"
    else
        # 下载Go安装包
        echo "📦 Downloading Go ${GO_VERSION}..."
        if ! curl ${CURL_PROXY} -L "https://dl.google.com/go/${FILENAME}" -o "${DOWNLOAD_DIR}/${FILENAME}"; then
            echo "❌ Failed to download Go"
            return 1
        fi
        echo "✅ Go ${GO_VERSION} downloaded"
    fi
    # 按照官方推荐方式安装：删除旧版本并解压新版本
    echo "🔄 Removing existing Go installation (if any)..."
    rm -rf /usr/local/go

    # 解压Go安装包
    echo "📦 Extracting Go ${GO_VERSION}..."
    if ! sudo tar -C /usr/local -xzf "${DOWNLOAD_DIR}/${FILENAME}"; then
        echo "❌ Failed to extract Go"
        return 1
    fi
    echo "✅ Go ${GO_VERSION} extracted to /usr/local/go"
    # 设置环境变量
    echo "🔧 Updating PATH environment variable..."

    # Go二进制目录
    local GO_BIN_PATH="/usr/local/go/bin"

    # 更新常见的配置文件
    update_path "$HOME/.bashrc" "$GO_BIN_PATH" "Go binary path"
    update_path "$HOME/.zshrc" "$GO_BIN_PATH" "Go binary path"
    # update_path "$HOME/.bash_profile" "$GO_BIN_PATH" "Go binary path"
    # update_path "$HOME/.profile" "$GO_BIN_PATH" "Go binary path"

    # 为当前会话设置环境变量
    export PATH=$PATH:${GO_BIN_PATH}
    # 验证安装
    echo "🔍 Verifying Go installation..."
    if go version; then
        echo "✅ Go ${GO_VERSION} successfully installed!"
        echo ""
        echo "To use Go in your current session, run:"
        echo "  export PATH=\$PATH:${GO_BIN_PATH}"
        echo ""
        echo "Go has been added to your PATH in shell profile files."
        echo "It will be available in new terminal sessions automatically."
    else
        echo "❌ Go installation verification failed"
        return 1
    fi
}

# 安装 Geth (Go Ethereum)
install_geth() {
    printf "\033[32m[INFO]\033[0m Installing Geth...\n"

    if command -v geth &>/dev/null; then
        printf "\033[33m[WARN]\033[0m Geth already installed: $(geth version | grep Version)\n"
        return
    fi

    # 从源码编译最新版本
    cd $DOWNLOAD_DIR
    if [[ ! -d ./go-ethereum ]]; then
        git clone https://github.com/ethereum/go-ethereum.git
    fi


    # 复制到系统路径, 请把这个路径<parent directory>build/bin添加到PATH环境变量中
    if [[ ! -f $BINARY_DIR/geth ]]; then
        cd go-ethereum
	git checkout $GETH_VERSION
        make geth
        printf "\033[32m[SUCCESS]\033[0m Geth installed: $(build/bin/geth version | head -n1)\n"
        cp -rf build/bin/* $BINARY_DIR
        cd ..
    fi
}

# 安装 beacon-chain
install_beacon_chain() {
    printf "\033[32m[INFO]\033[0m Installing beacon-chain binary...\n"
    local FILENAME=beacon-chain-${PRYSM_VERSION}-${OS}-${ARCH}
    if [[ -f "${DOWNLOAD_DIR}/${FILENAME}" ]]; then
        printf "\033[33m[WARN]\033[0m Beacon-chain installed: ${PRYSM_VERSION}\n"
        cp -f ${DOWNLOAD_DIR}/${FILENAME} ${BINARY_DIR}/beacon-chain
        chmod +x ${BINARY_DIR}/beacon-chain
        return
    fi

    # 下载二进制文件
    BASE_URL="https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}"
    echo "📦 Downloading beacon-chain..."
    if curl ${CURL_PROXY} -L "${BASE_URL}/${FILENAME}" -o ${DOWNLOAD_DIR}/${FILENAME}; then
        cp -f ${DOWNLOAD_DIR}/${FILENAME} ${BINARY_DIR}/beacon-chain
        chmod +x ${BINARY_DIR}/beacon-chain
        echo "✅ beacon-chain downloaded"
    else
        echo "❌ Failed to download beacon-chain"
        return 1
    fi
}

install_validator() {
    printf "\033[32m[INFO]\033[0m Installing validator binary...\n"
    local FILENAME=validator-${PRYSM_VERSION}-${OS}-${ARCH}
    if [[ -f "${DOWNLOAD_DIR}/${FILENAME}" ]]; then
        printf "\033[33m[WARN]\033[0m Validator installed: ${PRYSM_VERSION}\n"
        cp -f ${DOWNLOAD_DIR}/${FILENAME} ${BINARY_DIR}/validator
        chmod +x ${BINARY_DIR}/validator
        return
    fi

    # 下载二进制文件
    BASE_URL="https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}"
    echo "📦 Downloading validator..."
    if curl ${CURL_PROXY} -L "${BASE_URL}/${FILENAME}" -o ${DOWNLOAD_DIR}/${FILENAME}; then
        cp -f ${DOWNLOAD_DIR}/${FILENAME} ${BINARY_DIR}/validator
        chmod +x ${BINARY_DIR}/validator
        echo "✅ validator downloaded"
    else
        echo "❌ Failed to download validator"
        return 1
    fi
}

# 单独安装 prysmctl 二进制文件
install_prysmctl() {
    printf "\033[32m[INFO]\033[0m Installing prysmctl binary...\n"
    local FILENAME=prysmctl-${PRYSM_VERSION}-${OS}-${ARCH}
    if [[ -f "${DOWNLOAD_DIR}/${FILENAME}" ]]; then
        printf "\033[33m[WARN]\033[0m Prysmctl installed: ${PRYSM_VERSION}\n"
        cp -vf ${DOWNLOAD_DIR}/${FILENAME} ${BINARY_DIR}/prysmctl
        chmod +x ${BINARY_DIR}/prysmctl
        return
    fi


    BASE_URL="https://github.com/prysmaticlabs/prysm/releases/download/${PRYSM_VERSION}"
    echo "📦 Downloading prysmctl..."
    if curl ${CURL_PROXY} -L "${BASE_URL}/${FILENAME}" -o ${DOWNLOAD_DIR}/${FILENAME}; then
        cp -f ${DOWNLOAD_DIR}/${FILENAME} ${BINARY_DIR}/prysmctl
        chmod +x ${BINARY_DIR}/prysmctl
        echo "✅ prysmctl downloaded"
    else
        echo "❌ Failed to download prysmctl"
        return 1
    fi
}

# 安装 staking-deposit-cli
#install_staking_deposit_cli() {
#    printf "\033[32m[INFO]\033[0m Installing staking-deposit-cli from source...\n"
#
#    # 检查是否已存在
#    if [[ -d "staking-deposit-cli" ]]; then
#        printf "\033[33m[WARN]\033[0m staking-deposit-cli installed: $(cd staking-deposit-cli && git describe --tags)\n"
#        return
#    fi
#
#    # 克隆最新源代码
#    printf "\033[32m[INFO]\033[0m Cloning staking-deposit-cli repository...\n"
#    git clone https://github.com/ethereum/staking-deposit-cli.git
#    cd staking-deposit-cli
#
#    # 检出最新稳定版本
#    LATEST_TAG=$(git describe --tags --abbrev=0)
#    printf "\033[32m[INFO]\033[0m Checking out latest version: $LATEST_TAG\n"
#    git checkout $LATEST_TAG
#
#    # 创建虚拟环境
#    printf "\033[32m[INFO]\033[0m Creating Python virtual environment...\n"
#    python3 -m venv venv
#    source venv/bin/activate
#
#    # 升级 pip 和安装构建依赖
#    printf "\033[32m[INFO]\033[0m Installing build dependencies...\n"
#    pip install --upgrade pip setuptools wheel
#
#    # 安装项目依赖
#    printf "\033[32m[INFO]\033[0m Installing project dependencies...\n"
#    pip install -r requirements.txt
#
#    # 安装开发依赖（如果需要）
#    if [[ -f "requirements_test.txt" ]]; then
#        pip install -r requirements_test.txt
#    fi
#
#    # 以开发模式安装
#    printf "\033[32m[INFO]\033[0m Installing staking-deposit-cli in development mode...\n"
#    pip install -e .
#
#    # 验证安装
#    printf "\033[32m[INFO]\033[0m Verifying installation...\n"
#    python -m staking_deposit.deposit --help >/dev/null 2>&1
#
#    if [[ $? -eq 0 ]]; then
#        printf "\033[32m[SUCCESS]\033[0m staking-deposit-cli installed successfully from source\n"
#        printf "\033[32m[INFO]\033[0m Version: $LATEST_TAG\n"
#    else
#        printf "\033[31m[ERROR]\033[0m Failed to verify staking-deposit-cli installation\n"
#        exit 1
#    fi
#
#    # 返回上级目录
#    cd ..
#}

# 安装 eth2-val-tools
install_eth2_val_tools() {
    printf "\033[32m[INFO]\033[0m Installing eth2-val-tools...\n"

    if command -v eth2-val-tools &>/dev/null; then
        printf "\033[33m[WARN]\033[0m eth2-val-tools already installed\n"
        return 0
    fi

    # 检查是否安装了Go
    if ! command -v go &>/dev/null; then
        printf "\033[31m[ERROR]\033[0m Go is required but not installed. Please install Go first.\n"
        return 1
    fi

    # 从源码编译最新版本
    cd $DOWNLOAD_DIR
    if [[ ! -d ./eth2-val-tools ]]; then
        git clone https://github.com/protolambda/eth2-val-tools.git
    fi
    if [[ ! -f $BINARY_DIR/eth2-val-tools ]]; then
        cd eth2-val-tools
        git checkout $ETH2_VAL_TOOLS_VERSION

        # 编译
        printf "\033[32m[INFO]\033[0m Building eth2-val-tools...\n"
        go build -o eth2-val-tools .

        # 检查编译是否成功
        if [[ ! -f ./eth2-val-tools ]]; then
            printf "\033[31m[ERROR]\033[0m Failed to build eth2-val-tools\n"
            return 1
        fi

        # 复制到二进制目录
        printf "\033[32m[INFO]\033[0m Copying eth2-val-tools to $BINARY_DIR\n"
        cp -f ./eth2-val-tools $BINARY_DIR
        # 设置执行权限
        chmod +x $BINARY_DIR/eth2-val-tools

        printf "\033[32m[SUCCESS]\033[0m eth2-val-tools installed successfully\n"
        cd ..
    fi
}

# 安装 eth-beacon-genesis
install_eth_beacon_genesis() {
    printf "\033[32m[INFO]\033[0m Installing eth-beacon-genesis...\n"

    if command -v eth-beacon-genesis &>/dev/null; then
        printf "\033[33m[WARN]\033[0m eth-beacon-genesis already installed\n"
        return 0
    fi

    # 检查是否安装了Go
    if ! command -v go &>/dev/null; then
        printf "\033[31m[ERROR]\033[0m Go is required but not installed. Please install Go first.\n"
        return 1
    fi

    # 从源码编译最新版本
    cd $DOWNLOAD_DIR
    if [[ ! -d ./eth-beacon-genesis ]]; then
        git clone https://github.com/ethpandaops/eth-beacon-genesis.git
    fi
    if [[ ! -f $BINARY_DIR/eth-beacon-genesis ]]; then
        cd eth-beacon-genesis
        git pull origin master

        # 编译
        printf "\033[32m[INFO]\033[0m Building eth-beacon-genesis...\n"
        go build ./cmd/eth-genesis-state-generator
        # 检查编译是否成功
        if [[ ! -f ./eth-genesis-state-generator ]]; then
            printf "\033[31m[ERROR]\033[0m Failed to build eth-beacon-genesis\n"
            return 1
        fi

        # 向后兼容
        mv eth-genesis-state-generator eth-beacon-genesis

        # 复制到二进制目录
        printf "\033[32m[INFO]\033[0m Copying eth-beacon-genesis to $BINARY_DIR\n"
        cp -f ./eth-beacon-genesis $BINARY_DIR

        # 设置执行权限
        chmod +x $BINARY_DIR/eth-beacon-genesis

        printf "\033[32m[SUCCESS]\033[0m eth-beacon-genesis installed successfully\n"
        cd ..
    fi
}

# 主安装流程
main() {
    printf "\033[32m=== Ethereum PoS Private Network Setup for macOS ===\033[0m\n"
    install_python
    install_go
    install_geth
    install_beacon_chain
    install_validator
    install_prysmctl
    # install_staking_deposit_cli
    install_eth2_val_tools
    install_eth_beacon_genesis

    update_path "$HOME/.bashrc" "$BINARY_DIR" "Geth binary path"
    update_path "$HOME/.zshrc" "$BINARY_DIR" "Geth binary path"

    printf "\033[32m[SUCCESS]\033[0m All dependencies installed successfully!\n"
    printf "\n"
    printf "Next steps:\n"
    printf "1. Run: ./setup-config.sh\n"
    printf "2. Run: ./start-network.sh\n"
}

main "$@"
