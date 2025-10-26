#!/usr/bin/env bash
set -euo pipefail

cyan()  { printf "\033[36m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

cyan "🚀 Telegram Bot 通知配置助手"
echo "------------------------------------"
echo "1) 打开 Telegram，搜索 @BotFather"
echo "2) 发送 /newbot，按提示创建 Bot（名字任意，用户名以 bot 结尾）"
echo "3) 复制 BotFather 返回的 Token（形如：1234567890:ABCDEF...）"
echo "------------------------------------"

read -rp "请输入你的 Bot Token: " BOT_TOKEN
BOT_TOKEN="${BOT_TOKEN// /}"

# 校验格式
if [[ ! "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
  red "❌ Token 格式不对，请确认后重试。"
  exit 1
fi

API="https://api.telegram.org/bot${BOT_TOKEN}"

yellow "➡️  现在请在 Telegram 给你的 Bot 发送一条消息（如 /start 或 hello）"
read -rp "发送完后按回车继续..."

cyan "⏳ 正在获取 Chat ID ..."

CHAT_ID=""
for i in {1..10}; do
  RESP="$(curl -fsSL "${API}/getUpdates" || true)"
  CHAT_ID="$(echo "$RESP" | sed -nE 's/.*"chat":\{[^}]*"id":(-?[0-9]+).*/\1/p' | head -n1)"
  [[ -n "$CHAT_ID" ]] && break
  sleep 1
done

if [[ -z "$CHAT_ID" ]]; then
  red "❌ 获取失败，请确认你已向 Bot 发送过消息。"
  echo "可手动打开 ${API}/getUpdates 查看返回内容。"
  exit 1
fi

green "✅ 检测到 Chat ID: ${CHAT_ID}"

URL="telegram://${BOT_TOKEN}@telegram?channels=${CHAT_ID}"

echo
cyan "📦 生成的 Watchtower 通知配置："
echo "WATCHTOWER_NOTIFICATION_URL=${URL}"
echo
echo "👉 请把上面这一行添加到 docker-compose.yml 的 watchtower -> environment 段。"
echo

read -rp "是否发送一条测试消息？(y/N) " SEND_TEST
if [[ "${SEND_TEST:-N}" =~ ^[Yy]$ ]]; then
  if curl -fsSL -X POST "${API}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      -d "text=[Watchtower Test] Notification configured successfully ✅" >/dev/null; then
    green "✅ 测试消息已发送。"
  else
    yellow "⚠️ 测试消息发送失败，请稍后再试。"
  fi
fi

green "🎉 完成！复制上面的 WATCHTOWER_NOTIFICATION_URL 即可。"