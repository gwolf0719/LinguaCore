# LinguaCore - 離線即時語音翻譯 App

一個基於 Flutter 開發的 Android 離線即時語音翻譯應用程序，能夠在無網路環境下實現英文與中文的雙向即時語音翻譯。

## 功能特色

### 🎯 核心功能
- **離線即時翻譯**: 完全離線運作，無需網路連接
- **雙向語音翻譯**: 支援英文→中文和中文→英文雙向翻譯
- **即時語音識別**: 實時語音轉文字功能
- **自然語音合成**: 高品質的語音播放
- **對話記錄**: 完整的對話歷史記錄

### 🔧 技術特點
- **ML Kit 離線模型**: 使用 Google ML Kit 的離線語音識別和翻譯功能
- **智能音頻處理**: 自動音頻會話管理和雜音過濾
- **性能優化**: 資源優化，確保流暢運行
- **直觀界面**: 簡潔易用的用戶界面設計

## 技術架構

### 核心技術棧
```
Flutter Framework 3.0+
├── 語音識別: speech_to_text + ML Kit
├── 離線翻譯: google_mlkit_translation
├── 語音合成: flutter_tts
├── 音頻處理: audio_session, record
├── 狀態管理: flutter_riverpod
└── UI框架: Material Design 3
```

### 項目結構
```
lib/
├── core/
│   ├── services/           # 核心服務
│   │   ├── audio_service.dart
│   │   ├── translation_service.dart
│   │   ├── tts_service.dart
│   │   └── service_locator.dart
├── features/
│   └── translation/
│       ├── presentation/
│       │   ├── screens/    # 畫面
│       │   ├── widgets/    # UI組件
│       │   └── providers/  # 狀態管理
└── main.dart
```

## 安裝與設置

### 前置需求
- Flutter SDK 3.0.0 或以上版本
- Android Studio / VS Code
- Android SDK (API Level 21+)

### 安裝步驟

1. **克隆項目**
```bash
git clone <repository-url>
cd LinguaCore
```

2. **安裝依賴**
```bash
flutter pub get
```

3. **配置 Android**
```bash
# 確保 Android SDK 已正確安裝
flutter doctor

# 連接 Android 設備或啟動模擬器
flutter devices
```

4. **運行應用**
```bash
flutter run
```

### 建置發布版本
```bash
# 建置 APK
flutter build apk --release

# 建置 App Bundle (推薦用於 Google Play)
flutter build appbundle --release
```

## 使用說明

### 基本操作
1. **首次啟動**: 應用會自動下載必要的 ML Kit 離線模型
2. **聽對方說話**: 點擊 "聽對方說話" 按鈕開始聽取英文語音
3. **我要說話**: 點擊 "我要說話" 按鈕開始錄製中文語音
4. **即時翻譯**: 語音會自動轉換為文字並翻譯成目標語言
5. **語音播放**: 翻譯結果會自動以語音形式播放

### 功能說明
- **狀態指示器**: 實時顯示當前操作狀態（聆聽、翻譯、播放）
- **對話記錄**: 查看完整的對話歷史和翻譯記錄
- **緊急停止**: 隨時可以停止當前操作
- **清除記錄**: 一鍵清除對話歷史

## 權限說明

應用需要以下權限：
- **麥克風權限**: 用於語音識別
- **音頻設置權限**: 用於音頻會話管理
- **藍牙權限**: 支援藍牙耳機（可選）

## 性能優化

### 記憶體管理
- 自動釋放不用的音頻資源
- 智能管理 ML Kit 模型載入
- 優化對話記錄存儲

### 電池優化
- 減少背景處理
- 智能音頻會話管理
- 自動停止閒置服務

## 疑難排解

### 常見問題

**Q: 語音識別不準確？**
A: 確保在安靜環境中使用，麥克風距離適中（15-30cm）

**Q: 翻譯模型下載失敗？**
A: 檢查存儲空間是否足夠，重新啟動應用

**Q: 語音播放沒有聲音？**
A: 檢查設備音量設置和音頻輸出設備

**Q: 應用卡頓或崩潰？**
A: 清除應用快取，重新安裝應用

### 調試模式
在調試模式下，應用會輸出詳細的日誌信息：
```bash
flutter logs
```

## 技術支援

### 系統需求
- **Android**: 5.0 (API Level 21) 或以上
- **RAM**: 至少 2GB 可用記憶體
- **存儲**: 至少 500MB 可用空間（用於 ML Kit 模型）

### 支援的語言
- **語音識別**: 英文 (en-US)、中文 (zh-CN)
- **翻譯**: 英文 ↔ 中文
- **語音合成**: 英文、中文

## 開發指南

### 架構模式
- **Clean Architecture**: 分層架構設計
- **Provider Pattern**: 使用 Riverpod 進行狀態管理
- **Service Locator**: 依賴注入管理

### 代碼規範
- 遵循 Flutter/Dart 官方代碼規範
- 使用 flutter_lints 進行代碼檢查
- 註釋覆蓋重要業務邏輯

### 測試
```bash
# 運行單元測試
flutter test

# 運行整合測試
flutter drive --target=test_driver/app.dart
```

## 授權許可

本項目採用 MIT 授權許可，詳細內容請參考 [LICENSE](LICENSE) 文件。

## 貢獻指南

歡迎提交 Issue 和 Pull Request 來幫助改善此項目。

---

**注意**: 本應用為離線運作，首次使用時需要下載語言模型，請確保有穩定的網路連接用於初始設置。