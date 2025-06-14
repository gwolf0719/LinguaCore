#!/bin/bash

# 模擬器工具路徑（請依實際安裝位置修改）
EMULATOR_PATH=~/Library/Android/sdk/emulator/emulator

# 取得所有 AVD 名稱
AVD_LIST=($($EMULATOR_PATH -list-avds))

# 檢查是否有模擬器
if [ ${#AVD_LIST[@]} -eq 0 ]; then
  echo "❌ 沒有可用的 AVD 模擬器，請先在 Android Studio 建立模擬器。"
  exit 1
fi

# 顯示選單
echo "📱 請選擇要啟動的模擬器："
for i in "${!AVD_LIST[@]}"; do
  echo "$((i+1)). ${AVD_LIST[$i]}"
done

# 輸入選擇
read -p "輸入選項編號（例如 1）: " choice

# 驗證輸入
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#AVD_LIST[@]}" ]; then
  echo "⚠️ 輸入錯誤，請輸入正確編號。"
  exit 1
fi

# 取得選擇的 AVD 名稱
AVD_NAME=${AVD_LIST[$((choice-1))]}

# 啟動模擬器
echo "🚀 正在啟動模擬器：$AVD_NAME"
$EMULATOR_PATH -avd "$AVD_NAME"
