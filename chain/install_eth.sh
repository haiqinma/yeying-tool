#!/bin/sh

# set directory to install
deploy_dir=/yeying

# set version, current latest version: 1.14.3
version=1.14.3

# check go version
go_version=$(go version | cut -d " " -f 3 | sed 's/go//')
go_clean_version=$(echo $go_version | sed -E 's/([0-9]+.[0-9]+).*/\1/')
result=$(echo $go_clean_version'>'1.21 | bc -l)
if [ "$result" -eq 1 ]; then
    echo "Go version is at least 1.21. Version found: $go_version"
else
    echo "Go version is less than 1.21. Version found: $go_version. Please update."
    exit 1
fi

# download and untar the ethereum code
package=v${version}.tar.gz
if [ -f "v${version}.tar.gz" ]; then
  echo "Exist the ethereum package."
else
  wget https://github.com/ethereum/go-ethereum/archive/refs/tags/${package}
fi

if [ -d "go-ethereum-${version}" ]; then
  echo "Exist the directory."
else
  tar -xvf ${package}
fi

# complie the ethereum for geth client and other tools.
cd go-ethereum-${version}
make all

# copy to target geth directory.
target_geth_dir=${deploy_dir}/eth-${version}
mkdir -p ${target_geth_dir}
cp -rf build/bin ${target_geth_dir}/

# link to the geth directory, add the ${linked_geth_dir}/bin to PATH environment variable.
linked_geth_dir=${deploy_dir}/geth
if [ -L ${linked_geth_dir} ]; then
  unlink ${linked_geth_dir}
fi
ln -s ${target_geth_dir} ${linked_geth_dir}

