一键运行即可：wget -O Babylon.sh https://raw.githubusercontent.com/a3165458/Babylon/main/Babylon.sh && chmod +x Babylon.sh && ./Babylon.sh

日志检查:sudo journalctl -u babylon.service -f --no-hostname -o cat

状态查询:systemctl status babylon

查看同步信息：babylond status | jq .SyncInfo
