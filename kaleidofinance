#!/bin/bash

# 更新系统并安装必要的依赖项
sudo apt-get update
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo apt-get install -y git
sudo apt-get install -y screen

# 克隆仓库
git clone https://github.com/airdropinsiders/KaleidoFinance-Auto-Bot.git
cd KaleidoFinance-Auto-Bot

# 安装项目依赖
npm install

# 提示输入钱包地址
echo "请输入您的钱包地址（每行一个），输入完毕后按 Ctrl+D 保存："
cat > wallets.txt

# 启动一个新的 screen 会话并在后台运行项目
screen -dmS kaleido-bot npm run start

echo "项目正在后台运行。使用 'screen -r kaleido-bot' 重新连接到会话。"
