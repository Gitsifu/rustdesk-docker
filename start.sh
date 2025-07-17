#!/bin/bash

set -e

# Step 1: 启动 hbbs 容器
echo "🌱 启动 hbbs 容器..."
docker-compose up -d hbbs

# Step 2: 等待 id_ed25519.pub 文件生成（改进的等待机制）
echo "⏳ 等待 id_ed25519.pub 生成..."
KEY_PATH="./data/hbbs/id_ed25519.pub"

# 设置初始等待时间和最大等待时间
INITIAL_WAIT=60  # 初始等待60秒
MAX_WAIT=300     # 最大等待5分钟
RETRY=0

# 使用旋转动画字符
SPIN=('-' '\\' '|' '/')

# 初始等待阶段
while [ $RETRY -lt $INITIAL_WAIT ]; do
  if [ -f "$KEY_PATH" ]; then
    echo "🔑 检测到公钥文件: $KEY_PATH"
    break
  fi

  # 显示旋转动画和计时
  printf "\r[%s] 等待密钥生成... %d/%d " "${SPIN[$((RETRY % 4))]}" "$RETRY" "$INITIAL_WAIT"
  sleep 1
  RETRY=$((RETRY+1))
done

# 如果初始等待后仍未找到密钥文件，提供额外等待选项
if [ $RETRY -ge $INITIAL_WAIT ] && [ ! -f "$KEY_PATH" ]; then
  echo -e "\n⚠️ 已等待 ${INITIAL_WAIT} 秒，但未检测到密钥文件。"
  echo "这可能是因为网络较慢或服务器负载较高。"

  read -p "是否继续等待更长时间? (y/n): " CONTINUE_WAITING

  if [[ "$CONTINUE_WAITING" =~ ^[Yy]$ ]]; then
    echo "继续等待密钥生成，最多额外等待 $(($MAX_WAIT-$INITIAL_WAIT)) 秒..."

    while [ $RETRY -lt $MAX_WAIT ]; do
      if [ -f "$KEY_PATH" ]; then
        echo "🔑 检测到公钥文件: $KEY_PATH"
        break
      fi

      # 显示进度
      printf "\r[%s] 继续等待... %d/%d " "${SPIN[$((RETRY % 4))]}" "$RETRY" "$MAX_WAIT"
      sleep 1
      RETRY=$((RETRY+1))
    done
  fi
fi

# 最终检查
if [ ! -f "$KEY_PATH" ]; then
  echo -e "\n❌ 超时，未检测到 id_ed25519.pub！请检查 hbbs 是否正常运行或替换docker镜像源后重试 。"
  echo "💡 提示: 你可以尝试以下命令查看问题:"
  echo "  - docker-compose logs hbbs"
  echo "  - docker-compose ps"
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
