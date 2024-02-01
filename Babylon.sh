#!/bin/bash

sudo apt update && sudo apt upgrade -y

# Install Build Tools
sudo apt -qy install curl git jq lz4 build-essential

# Install GO
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.20.12.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

# Clone project repository
cd $HOME
rm -rf babylon
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.7.2

# Build binaries
make build

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.babylond/cosmovisor/genesis/bin
mv build/babylond $HOME/.babylond/cosmovisor/genesis/bin/
rm -rf build

# Create application symlinks
sudo ln -s $HOME/.babylond/cosmovisor/genesis $HOME/.babylond/cosmovisor/current -f
sudo ln -s $HOME/.babylond/cosmovisor/current/bin/babylond /usr/local/bin/babylond -f

# Download and install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

# Create and start service
sudo tee /etc/systemd/system/babylon.service > /dev/null << EOF
[Unit]
Description=babylon node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.babylond"
Environment="DAEMON_NAME=babylond"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.babylond/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable babylon.service

# Ask for moniker input
read -p "输入节点名称: " MONIKER

# Set node configuration
babylond config chain-id bbn-test-2
babylond config keyring-backend test
babylond config node tcp://localhost:16457

# Initialize the node
babylond init $MONIKER --chain-id bbn-test-2

# Download genesis and addrbook
curl -Ls https://snapshots.kjnodes.com/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

# Add seeds
sed -i -e 's|^seeds *=.*|seeds = "03ce5e1b5be3c9a81517d415f65378943996c864@18.207.168.204:26656,a5fabac19c732bf7d814cf22e7ffc23113dc9606@34.238.169.221:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656"|' $HOME/.babylond/config/config.toml

# Set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ubbn\"|" $HOME/.babylond/config/app.toml

# Set pruning
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.babylond/config/app.toml

# Set custom ports
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:16458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:16457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:16460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:16456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":16466\"%" $HOME/.babylond/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:16417\"%; s%^address = \":8080\"%address = \":16480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:16490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:16491\"%; s%:8545%:16445%; s%:8546%:16446%; s%:6065%:16465%" $HOME/.babylond/config/app.toml

curl -L https://snapshots.kjnodes.com/babylon-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.babylond
[[ -f $HOME/.babylond/data/upgrade-info.json ]] && cp $HOME/.babylond/data/upgrade-info.json $HOME/.babylond/cosmovisor/genesis/upgrade-info.json

cd
PEERS="dda2f3f84f033d7f76e5af41beb8b25149ae8242@176.37.119.156:16456,09f250b1766d19631a1729f2378ecf33781ac47d@161.97.93.8:16456,a34f6e8692f0aa1cefdadc079a0d7c72c641b286@109.228.160.58:16456,791fa91aab32a11100ebc5961d87d33455035146@62.68.130.19:16456,21af6c66c8ab043e0d9b35bcbeb3ed7b12e96232@168.119.77.61:16456,5ec2acd58b5da27e172e387442397f661450df04@37.60.230.112:16456,8c9854441d2fd5b7526776fb89deba75f14fb276@37.60.227.161:16456,e94e79c769febc9f5ce82f5bba8d0d86c72e41f5@135.181.197.68:16456,30e5bf213a3c4f3b07502709fbab93bc3111c994@204.216.221.134:26656,93820dc6ef82e0a38042a2efb717124071df58db@144.91.93.154:26656,1ba06acd1ca678168ffb3b6a4345bff71296dd51@193.233.233.94:31156,a2a480604f4d34400ff2b838ba0d9b1d11d71555@62.171.191.9:16456,19b6c506de674a4d8ac5b95b68e7fd5d20b2a8c5@147.45.41.160:26656,ffb621fe9b2228542a64e4a8b5e12c4d754ee98f@5.250.182.152:16456,4052b23defbe35101bea9aaaf4145cf17a7a97c7@62.76.31.21:16456,62df42cb3dfb4d2eef8d40c4a95e3072836ab788@95.111.255.125:16456,36a93fae1cf2343e6497822366b48cbc8de5f322@84.247.185.173:26656,ef2c98cf4536a3ba958fbc9ba23e27a8d15b902b@38.242.148.58:16456,b4abb45ce5d0367a192189207ee90ac51647bb2d@195.14.6.2:26656,dcfb244d9a84cd2bd1e2c9c443f2318b42db7028@207.180.240.70:16456,edb007e236f318c5dc3b301af313934c7180ca42@161.97.118.136:16456,ffc6b50fe43a9956fd2c9091b3f9354a4c057af7@20.82.255.177:16456,a98484ac9cb8235bd6a65cdf7648107e3d14dab4@116.202.231.58:16456,bb41c659e2cb6f7ee9dadd81c7229b095705722b@147.45.41.14:16456,29c1960f9776efe70f6ee5e7e05bc4f5baee7bf2@109.123.244.43:26656,a907c7e1fa63c1bb558bb06c0f13c82b286dfa8f@217.76.58.70:16456,deb8e72f504c33a20a3c02ff1fe6e26d93564eb2@84.247.185.43:16456,1c1a77f600f9f2fd463f8afb799b08e0ffa0da51@45.77.230.114:26656,c133cf05d6e2c225601862e74073b706e36e9c1c@217.76.55.133:16456,22e2fa9ce4aebe6be19cde8c0e69f74027c2c6e8@65.108.124.109:16456,406c79ca6ea705447b252c7cbffb550d58719a76@84.247.184.25:26656,d13873a660420c60f3ab4af6d6e9d0983568199e@149.102.158.107:16456,f3882fd388294d6cf087c90a7b08480817a23b27@31.220.73.66:16456,258079f20f606cb6437007fdd9bfa62e1674c7e4@158.220.106.113:16456,692aa438e54d8f9c621a5b0429ccf33d9cb9d1a8@161.97.68.83:16456,e4acc3ee591be550860ffcb65a72c97253d59f07@195.35.22.85:26656,042099e48a767e6caf8908325cf76930abbc658f@84.247.130.87:16456,6f603467c142a9a5865419a0057e91e89afdbb63@185.193.67.253:26656,d648b382c29ec9087c557d05e9f4ea6ad862a949@49.12.60.233:16456,97f0ec8ee918a63933ddcf01a8e8c7d7bab00574@207.180.252.249:16456,063e854249a20b713ebc9dceca83b709e5262923@20.26.124.252:16456,ce0d1e8692e01c831473c7ac2c5d911e2c41d66c@173.212.228.219:16456,e63fe16a6f6d771bc2a1e26d37d7778908eb053a@37.120.189.81:31156"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml

sudo systemctl restart babylon
sudo journalctl -u babylon -f --no-hostname -o cat

sudo systemctl start babylon.service && sudo journalctl -u babylon.service -f --no-hostname -o cat
