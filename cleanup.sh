#!/bin/bash

# 定义需要处理的 screen 会话名称
screen_names=("hyper" "hyperspace")

for screen_name in "${screen_names[@]}"; do
    # 检查并删除现有会话
    if screen -ls | grep -q "$screen_name"; then
        echo "找到现有的 '$screen_name' 屏幕会话，正在停止并删除..."
        screen -S "$screen_name" -X quit
        sleep 2
    fi
done

# 停止 aios-cli 进程
echo "正在停止 'aios-cli' 进程..."
aios_cli_pids=$(pgrep -f "aios-cli")
if [ -n "$aios_cli_pids" ]; then
    kill -9 $aios_cli_pids
    echo "'aios-cli' 进程已停止。"
else
    echo "没有找到 'aios-cli' 进程。"
fi

# 删除 aios-cli 安装目录和相关文件
echo "正在删除 aios-cli 安装目录和相关文件..."
rm -rf /root/.aios-cli
rm -rf /root/.config/aios-cli
rm -rf /root/.local/share/aios-cli
rm -f /root/.bashrc

# 删除 Hyperspace.sh 脚本
echo "正在删除 Hyperspace.sh 脚本..."
rm -f /home/ubuntu/Hyperspace.sh

# 清理 Docker 相关内容
echo "正在清理 Docker 相关内容..."
docker rm -f $(docker ps -a -q)
docker rmi -f $(docker images -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q)

# 卸载 Docker
echo "正在卸载 Docker..."
apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-compose-plugin
apt-get autoremove -y --purge docker-engine docker docker.io docker-ce

# 清理残留文件
echo "正在清理残留文件..."
rm -rf /var/lib/docker
rm -rf /etc/docker
rm -rf /etc/systemd/system/docker.service.d
rm -rf /var/run/docker.sock

# 清理系统
echo "正在清理系统..."
apt-get autoremove -y
apt-get autoclean -y

echo "清理完成，所有相关文件和会话已删除。"
