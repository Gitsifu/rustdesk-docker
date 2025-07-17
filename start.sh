#!/bin/bash

set -e

# Step 1: 启动 hbbs 容器
echo "🌱 启动 hbbs 容器..."
docker-compose up -d hbbs

# Step 2: 等待 id_ed25519.pub 文件生成
echo "⏳ 等待 id_ed25519.pub 生成..."
MAX_RETRIES=60
RETRY=0
KEY_PATH="./data/hbbs/id_ed25519.pub"

while [ $RETRY -lt $MAX_RETRIES ]; do
  if [ -f "$KEY_PATH" ]; then
    echo "🔑 检测到公钥文件: $KEY_PATH"
    break
  fi
  sleep 1
  RETRY=$((RETRY+1))
done

if [ $RETRY -ge $MAX_RETRIES ]; then
  echo "❌ 超时，未检测到 id_ed25519.pub！请检查 hbbs 是否正常运行"
  exit 1
fi

# Step 3: 从宿主机读取公钥
SIGN_KEY=$(cat "$KEY_PATH")

# Step 4: 更新 .env，不删除原配置
echo "🔐 更新 .env 文件（保留已有配置）..."

# 如果 .env 文件不存在，先创建一个空文件
touch .env

# 替换或添加 RUSTDESK_API_KEY
if grep -q '^RUSTDESK_API_KEY=' .env 2>/dev/null; then
  sed -i "s|^RUSTDESK_API_KEY=.*|RUSTDESK_API_KEY=${SIGN_KEY}|" .env
else
  echo "RUSTDESK_API_KEY=${SIGN_KEY}" >> .env
fi

# Step 5: 启动其余服务
echo "🚀 启动剩余服务..."
docker-compose up -d
