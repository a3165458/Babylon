#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/manage_babylon.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="babylondf"
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
#!/bin/bash

# 更新系统并安装构建工具
sudo apt update && sudo apt upgrade -y
sudo apt -qy install curl git jq lz4 build-essential

# 安装指定版本的Golang
sudo rm -rvf /usr/local/go/
wget https://golang.org/dl/go1.21.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go vesion

# 克隆 Babylon 项目仓库
cd $HOME
if [ -d "babylon" ]; then
    rm -rf babylon
fi
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.8.3

# 构建和安装 babylond
make install


# 安装创世文件
wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
mv genesis.json ~/.babylond/config/genesis.json

# 设置种子节点和peers
SEEDS="49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656"
PEERS="5463943178cdb57a02d6d20964e4061dfcf0afb4@142.132.154.53:20656,3774fb9996de16c2f2280cb2d938db7af88d50be@162.62.52.147:26656,9d840ebd61005b1b1b1794c0cf11ef253faf9a84@43.157.95.203:26656,0ccb869ba63cf7730017c357189d01b20e4eb277@185.84.224.125:20656,3f5fcc3c8638f0af476e37658e76984d6025038b@134.209.203.147:26656,163ba24f7ef8f1a4393d7a12f11f62da4370f494@89.117.57.201:10656,1bdc05708ad36cd25b3696e67ac455b00d480656@37.60.243.219:26656,59df4b3832446cd0f9c369da01f2aa5fe9647248@65.109.97.139:26656,e3b214c693b386d118ea4fd9d56ea0600739d910@65.108.195.152:26656,c0ee3e7f140b2de189ce853cfccb9fb2d922eb66@95.217.203.226:26656,e46f38454d4fb889f5bae202350930410a23b986@65.21.205.113:26656,35abd10cba77f9d2b9b575dfa0c7c8c329bf4da3@104.196.182.128:26656,6f3f691d39876095009c223bf881ccad7bd77c13@176.227.202.20:56756,1ecc4a9d703ad52d16bf30a592597c948c115176@165.154.244.14:26656,0c9f976c92bcffeab19944b83b056d06ea44e124@5.78.110.19:26656,c3e82156a0e2f3d5373d5c35f7879678f29eaaad@144.76.28.163:46656,b82b321380d1d949d1eed6da03696b1b2ef987ba@148.251.176.236:3000,eee116a6a816ca0eb2d0a635f0a1b3dd4f895638@84.46.251.131:26656,894d56d58448a158ed150b384e2e57dd7895c253@164.92.216.48:26656,ddd6f401792e0e35f5a04789d4db7dc386efc499@135.181.182.162:26656,326fee158e9e24a208e53f6703c076e1465e739d@193.34.212.39:26659,86e9a68f0fd82d6d711aa20cc2083c836fb8c083@222.106.187.14:56000,fad3a0485745a49a6f95a9d61cda0615dcc6beff@89.58.62.213:26501,ce1caddb401d530cc2039b219de07994fc333dcf@162.19.97.200:26656,66045f11c610b6041458aa8553ffd5d0241fd11e@103.50.32.134:56756,82191d0763999d30e3ddf96cc366b78694d8cee1@162.19.169.211:26656"
CONFIG_TOML="$HOME/.babylond/config/config.toml"
APP_TOML="$HOME/.babylond/config/app.toml"

sed -i -e "s|^seeds =.*|seeds = \"$SEEDS\"|" $CONFIG_TOML
sed -i -e 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $CONFIG_TOML
sed -i -e "s|^\(network = \).*|\1\"signet\"|" $APP_TOML
sed -i -e "s|^minimum-gas-prices =.*|minimum-gas-prices = \"0.00001ubbn\"|" $APP_TOML

# 安装 Cosmovisor
export PATH=$PATH:$(go env GOPATH)/bin
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

# 创建Cosmovisor文件夹结构
mkdir -p ~/.babylond/cosmovisor/genesis/bin
mkdir -p ~/.babylond/cosmovisor/upgrades

# 复制babylond二进制到Cosmovisor
cp $(go env GOPATH)/bin/babylond ~/.babylond/cosmovisor/genesis/bin/babylond


# 获取用户输入的节点名称
read -p "输入节点名称: " MONIKER

# 初始化节点
babylond init "$MONIKER" --chain-id bbn-test-3

# 创建并启动babylond服务
SERVICE_FILE="/etc/systemd/system/babylond.service"
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Babylon Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
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

sudo systemctl daemon-reload
sudo systemctl enable babylond
sudo systemctl start babylond

echo "Babylon 节点安装完成。"
}

# 创建钱包
function add_wallet() {
    read -p "请输入钱包名称: " wallet_name
    babylond keys add "$wallet_name"
}

# 导入钱包
function import_wallet() {
    read -p "请输入钱包名称: " wallet_name
    babylond keys add "$wallet_name" --recover
}

# 查看节点同步状态
function check_sync_status() {
    babylond status | jq .SyncInfo
}

# 查看babylon服务状态
function check_service_status() {
    systemctl status babylond
}

# 节点日志查询
function view_logs() {
    sudo journalctl -u babylond.service -f --no-hostname -o cat
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
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 创建钱包"
    echo "3. 导入钱包"
    echo "4. 查看节点同步状态"
    echo "5. 查看当前服务状态"
    echo "6. 运行日志查询"
    echo "7. 卸载脚本"
    echo "8. 设置快捷键"  
    read -p "请输入选项（1-8）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) add_wallet ;;
    3) import_wallet ;;
    4) check_sync_status ;;
    5) check_service_status ;;
    6) view_logs ;;
    7) uninstall_script ;;
    8) check_and_set_alias ;;  
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
