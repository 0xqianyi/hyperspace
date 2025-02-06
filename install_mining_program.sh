#!/bin/bash

# Step 1: 安装 nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Step 2: 加载 nvm
echo "Loading nvm..."
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Step 3: 安装指定版本的 Node.js (Node.js 14)
echo "Installing Node.js version 14..."
nvm install 14

# Step 4: 使用指定版本的 Node.js
echo "Using Node.js version 14..."
nvm use 14

# Step 5: 验证安装
echo "Verifying Node.js and npm installation..."
node -v
npm -v

# Step 6: 下载并运行挖矿程序的安装脚本
echo "Downloading and running the mining program installation script..."
curl -o kaleidofinance.sh https://raw.githubusercontent.com/0xqianyi/hyperspace/refs/heads/main/kaleidofinance.sh && chmod +x kaleidofinance.sh && ./kaleidofinance.sh

echo "Mining program installation complete!"
