#!/bin/bash

# 模擬器工具路徑（請依實際安裝位置修改）
EMULATOR_PATH=~/Library/Android/sdk/emulator/emulator

# 檢查是否有模擬器正在運行
check_running_emulators() {
  local running_emulators=$(pgrep -f "emulator.*-avd")
  if [ ! -z "$running_emulators" ]; then
    echo "⚠️ 檢測到有模擬器正在運行"
    echo "PID: $running_emulators"
    echo "您想要："
    echo "1. 關閉現有模擬器並啟動新的"
    echo "2. 以唯讀模式啟動新模擬器（實驗性功能）"
    echo "3. 取消操作"
    read -p "請選擇 (1-3): " action
    
    case $action in
      1)
        echo "🔄 正在關閉現有模擬器..."
        kill $running_emulators
        sleep 3
        return 0
        ;;
      2)
        echo "📖 將以唯讀模式啟動模擬器"
        return 1
        ;;
      3)
        echo "❌ 操作已取消"
        exit 0
        ;;
      *)
        echo "❌ 無效選擇，操作已取消"
        exit 1
        ;;
    esac
  fi
  return 0
}

# 取得所有 AVD 名稱
AVD_LIST=($($EMULATOR_PATH -list-avds))

# 檢查是否有模擬器
if [ ${#AVD_LIST[@]} -eq 0 ]; then
  echo "❌ 沒有可用的 AVD 模擬器，請先在 Android Studio 建立模擬器。"
  exit 1
fi

# 檢查正在運行的模擬器
check_running_emulators
READONLY_MODE=$?

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
if [ $READONLY_MODE -eq 1 ]; then
  echo "🚀 正在以唯讀模式啟動模擬器：$AVD_NAME"
  $EMULATOR_PATH -avd "$AVD_NAME" -read-only
else
  echo "🚀 正在啟動模擬器：$AVD_NAME"
  $EMULATOR_PATH -avd "$AVD_NAME"
fi
