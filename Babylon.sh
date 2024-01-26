#!/bin/bash

# 安装基础环境
# 安装go
sudo rm -rf /usr/local/go;
curl https://dl.google.com/go/go1.21.5.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf - ;
cat <<'EOF' >>$HOME/.bashrc
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.bashrc

# 安装完成后运行以下命令查看版本
go version

# 安装其他必要的环境
sudo apt-get update -y
sudo apt-get install curl build-essential jq git lz4 -y;

# 下载源代码并编译
cd
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.7.2
make install

# 安装完成后可以运行 babylond version 检查是否安装成功。
# 显示应为 v0.7.2

# 运行节点
# 初始化节点
read -p "请输入你的节点名: " moniker
babylond init $moniker --chain-id=bbn-test-2
babylond config chain-id bbn-test-2
