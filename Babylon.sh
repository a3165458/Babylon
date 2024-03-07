#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Babylon.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="bbl"
    local shell_rc="$HOME/.bashrc"

    # 对于Zsh用户，使用.zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # 检查快捷键是否已经设置
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "设置快捷键 '$alias_name' 到 $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # 添加提醒用户激活快捷键的信息
        echo "快捷键 '$alias_name' 已设置。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        # 如果快捷键已经设置，提供一个提示信息
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
        echo "如果快捷键不起作用，请尝试运行 'source $shell_rc' 或重新打开终端。"
    fi
}

# 节点安装功能
function install_node() {

sudo apt update && sudo apt upgrade -y

# 安装构建工具
sudo apt -qy install curl git jq lz4 build-essential

# 安装 Go
cd $HOME
ver="1.22.0"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile


# 克隆项目仓库
cd $HOME
rm -rf babylon
git clone https://github.com/babylonchain/babylon
cd babylon
git checkout v0.8.4

# 创建安装
make install


# 创建节点名称
read -p "输入节点名称: " MONIKER

# 配置节点
babylond init $MONIKER --chain-id bbn-test-3


# 安装创世文件
wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
mv genesis.json ~/.babylond/config/genesis.json

# 设置种子节点
sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656"|' $HOME/.babylond/config/config.toml

# 设置BTC网络
sed -i -e "s|^\(network = \).*|\1\"signet\"|" $HOME/.babylond/config/app.toml

# 设置最小gas
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ubbn\"|" $HOME/.babylond/config/app.toml


# 设置peers
PEERS="8922e2644ed7af59a2a724819432aae5df8c1197@154.26.128.52:26656,724c8c4b382a2832b65b19462baaa879ede4a647@85.148.51.82:26656,79973384380cb9135411bd6d79c7159f51373b18@133.242.221.45:26656,5145171795b9929c41374ce02feef8d11228c33b@160.202.128.199:55706,75d9957d90caa8a457a94d33dc69f7e847f4b58c@37.60.248.54:26656,38b27d582d7fcbe9ce3ef0b30b4e8e70acad7b62@116.203.55.220:26656,f43d529b140714bc12745662185b5107d464410d@78.46.61.108:46656,1566d505b8fa40b067f2d881c380f5866c618561@94.228.162.187:26656,79befb0680b4d3670bc46777677b4e904faab5e1@154.26.130.53:26656,d328c6f74f5039a0d3d829a86c3c3911ddf03e7a@109.199.115.129:26656,faeb6f14ed03744e3bdda42f207224944c2d5e90@173.249.52.53:26656,2d241785bf3004d82be8d32c901d62d21d9e70f2@180.83.70.240:26656,4ba238c40cbd54b654cff009fbd02373a2235a61@207.180.218.52:26656,54fce5236ad360aaccc731a164f720d9eb62951c@109.199.115.132:26656,487cbabe4db1d1dcbf45ad271ad57a367f3bc138@45.94.58.53:26656,2c1de581a482ba5765f400d3e3bb144e6e6994c5@149.102.129.209:26656,9fafb42160d1a4d657ecd48c59060162b373c1bf@68.183.195.179:26656,e022461bf6ffc2d1880eca75e00dfd9920832ee7@147.45.71.126:26656,0be8a6aa4c29eb72b90bccced27574c1224ddb30@62.171.189.52:26656,3be7d5d891d5174865789ee32288a67ae37816ac@152.89.105.112:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml


# 设置启动服务
sudo tee /etc/systemd/system/babylond.service > /dev/null <<EOF
[Unit]
Description=Babylon daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which babylond) start
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=babylond"
Environment="DAEMON_HOME=${HOME}/.babylond"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"

[Install]
WantedBy=multi-user.target
EOF

sudo -S systemctl daemon-reload
sudo -S systemctl enable babylond
sudo -S systemctl start babylond

    echo '====================== 安装完成 ==========================='
    
}

# 创建钱包
function add_wallet() {
    read -p "请输入钱包名称: " wallet_name
    babylond keys add "$wallet_name"
}

# 创建验证者
function add_validator() {
    read -p "请输入你的验证者名称: " validator_name
    sudo tee ~/validator.json > /dev/null <<EOF
{
  "pubkey": $(babylond tendermint show-validator),
  "amount": "100000ubbn",
  "moniker": "$validator_name",
  "details": "dalubi",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
    /root/go/bin/babylond tx checkpointing create-validator ~/validator.json \
    --chain-id=bbn-test-3 \
    --gas="auto" \
    --gas-adjustment="1.5" \
    --gas-prices="0.025ubbn" \
    --from=wallet
}

# 导入钱包
function import_wallet() {
    read -p "请输入钱包名称: " wallet_name
    babylond keys add "$wallet_name" --recover
}

# 查询余额
function check_balances() {
    read -p "请输入钱包地址: " wallet_address
    babylond query bank balances "$wallet_address" 
}

# 查看节点同步状态
function check_sync_status() {
    babylond status | jq .sync_info
}

# 查看babylon服务状态
function check_service_status() {
    systemctl status babylond
}

# 节点日志查询
function view_logs() {
    sudo journalctl -f -u babylond.service 
}

# 卸载脚本功能
function uninstall_script() {
    local alias_name="babylondf"
    local shell_rc_files=("$HOME/.bashrc" "$HOME/.zshrc")

    for shell_rc in "${shell_rc_files[@]}"; do
        if [ -f "$shell_rc" ]; then
            # 移除快捷键
            sed -i "/alias $alias_name='bash $SCRIPT_PATH'/d" "$shell_rc"
        fi
    done

    echo "快捷键 '$alias_name' 已从shell配置文件中移除。"
    read -p "是否删除脚本文件本身？(y/n): " delete_script
    if [[ "$delete_script" == "y" ]]; then
        rm -f "$SCRIPT_PATH"
        echo "脚本文件已删除。"
    else
        echo "脚本文件未删除。"
    fi
}

# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "================================================================"
    echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
    echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 创建钱包"
    echo "3. 导入钱包"
    echo "4. 创建验证者"
    echo "5. 查看钱包地址余额"
    echo "6. 查看节点同步状态"
    echo "7. 查看当前服务状态"
    echo "8. 运行日志查询"
    echo "9. 卸载脚本"
    echo "10. 设置快捷键"  
    read -p "请输入选项（1-10）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) add_wallet ;;
    3) import_wallet ;;
    4) add_validator ;;
    5) check_balances ;;
    6) check_sync_status ;;
    7) check_service_status ;;
    8) view_logs ;;
    9) uninstall_script ;;
    10) check_and_set_alias ;;  
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
