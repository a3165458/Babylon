#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi


# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if ! command -v node > /dev/null 2>&1; then
        echo "Node.js 未安装，正在安装..."
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs
        echo "Node.js 安装完成。"
    else
        echo "Node.js 已安装。"
    fi

    if ! command -v npm > /dev/null 2>&1; then
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
        echo "npm 安装完成。"
    else
        echo "npm 已安装。"
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if ! command -v pm2 > /dev/null 2>&1; then
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
        echo "PM2 安装完成。"
    else
        echo "PM2 已安装。"
    fi
}


# 脚本保存路径
SCRIPT_PATH="$HOME/Babylon.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="bbl"
    local shell_rc="$HOME/.bashrc"

    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "设置快捷键 '$alias_name' 到 $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        echo "快捷键 '$alias_name' 已设置。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
        echo "如果快捷键不起作用，请尝试运行 'source $shell_rc' 或重新打开终端。"
    fi
}

# 节点安装功能
function install_node() {
    sudo apt update && sudo apt upgrade -y
    sudo apt -qy install curl git jq lz4 build-essential

    install_nodejs_and_npm
    install_pm2

    rm -rf $HOME/go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    source $HOME/.bash_profile
    go version

    cd $HOME
    rm -rf babylon
    git clone https://github.com/babylonchain/babylon
    cd babylon
    git checkout v0.8.4
    make install

    read -p "请输入你想设置的节点名称: " MONIKER
    babylond init $MONIKER --chain-id bbn-test-3

    wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
    tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
    mv genesis.json ~/.babylond/config/genesis.json

    sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656"|' $HOME/.babylond/config/config.toml

    sed -i -e "s|^\(network = \).*|\1\"signet\"|" $HOME/.babylond/config/app.toml
    sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ubbn\"|" $HOME/.babylond/config/app.toml

    curl https://snapshots-testnet.nodejumper.io/babylon-testnet/babylon-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.babylond

    # 以 PM2 形式运行 babylond
    pm2 start babylond -- start && pm2 save && pm2 startup
    echo '====================== 安装完成 ==========================='
}


# 查看babylon 服务状态
function check_service_status() {
    pm2 list
}

# babylon 节点日志查询
function view_logs() {
    pm2 logs babylond
}

# 卸载节点功能
function uninstall_node() {
    echo "你确定要卸载 Babylon 节点程序吗？这将会删除所有相关的数据。[Y/N]"
    read -r -p "请确认: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "开始卸载节点程序..."
            pm2 stop babylond && pm2 delete babylond
            rm -rf $HOME/.babylond && rm -rf $HOME/babylon && sudo rm -rf /usr/local/bin/babylond
            echo "Babylon 节点程序卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

# 创建钱包
function add_wallet() {
    babylond keys add wallet
}

# 创建验证者
function add_validator() {
    read -p "请输入你的验证者名称: " validator_name
    sudo tee ~/validator.json >> /dev/null <<EOF
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
    babylond keys add wallet --recover
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

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
        echo "退出脚本，请按键盘ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装节点"
        echo "2. 创建钱包"
        echo "3. 导入钱包"
        echo "4. 查看钱包地址余额"
        echo "5. 查看节点同步状态"
        echo "6. 查看当前服务状态"
        echo "7. 运行日志查询"
        echo "8. 卸载节点"
        echo "9. 设置快捷键"  
        echo "10. 创建验证者"  
        read -p "请输入选项（1-10）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) add_wallet ;;
        3) import_wallet ;;
        4) check_balances ;;
        5) check_sync_status ;;
        6) check_service_status ;;
        7) view_logs ;;
        8) uninstall_node ;;
        9) check_and_set_alias ;;
        10) add_validator ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
