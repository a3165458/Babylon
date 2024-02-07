一键运行即可：wget -O Babylon.sh https://raw.githubusercontent.com/a3165458/Babylon/main/Babylon.sh && chmod +x Babylon.sh && ./Babylon.sh

一键运行 wget -O $HOME/manage_babylon.sh https://raw.githubusercontent.com/a3165458/Babylon/main/babylon1.sh && chmod +x manage_babylon.sh && ./manage_babylon.sh

日志检查:sudo journalctl -u babylon.service -f --no-hostname -o cat

状态查询:systemctl status babylon

查看同步信息：babylond status | jq .SyncInfo
