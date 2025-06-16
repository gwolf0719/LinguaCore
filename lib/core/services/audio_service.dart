import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamController<String>? _speechResultController;
  StreamController<bool>? _listeningController;
  StreamController<double>? _soundLevelController;

  bool _isInitialized = false;
  bool _isListening = false;
  Timer? _soundLevelTimer;

  Stream<String> get speechResults => _speechResultController!.stream;
  Stream<bool> get listeningStatus => _listeningController!.stream;
  Stream<double> get soundLevel => _soundLevelController!.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _speechResultController = StreamController<String>.broadcast();
      _listeningController = StreamController<bool>.broadcast();
      _soundLevelController = StreamController<double>.broadcast();

      // Request permissions
      await _requestPermissions();

      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );

      if (kDebugMode) {
        print('AudioService initialized: $_isInitialized');
        if (_isInitialized) {
          // 檢查可用的語言
          final locales = await availableLocales;
          print('Available speech locales: $locales');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService initialization error: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    print('🔒 Checking microphone permission...');

    // 先檢查當前權限狀態
    final currentStatus = await Permission.microphone.status;
    print('Current microphone permission status: $currentStatus');

    if (currentStatus == PermissionStatus.granted) {
      print('✅ Microphone permission already granted');
      return;
    }

    // 如果未授權，請求權限
    print('🔒 Requesting microphone permission...');
    final micPermission = await Permission.microphone.request();

    print('Microphone permission result: $micPermission');

    if (micPermission != PermissionStatus.granted) {
      if (micPermission == PermissionStatus.permanentlyDenied) {
        throw Exception(
            'Microphone permission permanently denied. Please enable in Settings.');
      } else {
        throw Exception('Microphone permission not granted: $micPermission');
      }
    }

    print('✅ Microphone permission granted');
  }

  Future<void> startListening({
    String localeId = 'en-US',
    bool partialResults = true,
    bool realTimeMode = false,
  }) async {
    if (!_isInitialized || _isListening) return;

    // 保存參數供重新啟動使用
    _lastLocaleId = localeId;
    _lastPartialResults = partialResults;
    _lastRealTimeMode = realTimeMode;
    _shouldKeepListening = realTimeMode; // 實時模式下保持持續監聽

    try {
      if (kDebugMode) {
        print(
            'Starting speech recognition with locale: $localeId, realTime: $realTimeMode, keepListening: $_shouldKeepListening');
        print('Available locales: ${await availableLocales}');
      }

      await _startListeningInternal(
        localeId: localeId,
        partialResults: partialResults,
        realTimeMode: realTimeMode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }
    }
  }

  Future<void> stopListening() async {
    // 停止持續監聽模式
    _shouldKeepListening = false;

    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _listeningController?.add(false);

      // 停止音量級別監控
      _stopSoundLevelMonitoring();

      if (kDebugMode) {
        print('Stopped listening (keepListening: $_shouldKeepListening)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping speech recognition: $e');
      }
    }
  }

  void _onSpeechResult(result) {
    final words = result.recognizedWords;
    final isFinal = result.finalResult;

    if (kDebugMode) {
      print(
          'Speech result received: "$words" (final: $isFinal, confidence: ${result.confidence})');
    }

    if (words.isNotEmpty) {
      _speechResultController?.add(words);
    } else {
      if (kDebugMode) {
        print('Empty speech result received');
      }
    }
  }

  void _onSpeechError(error) {
    if (kDebugMode) {
      print('Speech error: $error');
      print('Error type: ${error.runtimeType}');
      print('Is listening: $_isListening');
      print('Should keep listening: $_shouldKeepListening');
    }

    final errorMsg = error.toString();

    // 在實時模式下，永遠不要因為錯誤而停止監聽
    if (_shouldKeepListening) {
      print('Real-time mode: Ignoring error and continuing to listen...');
      return;
    }

    // 如果是 "no match" 錯誤，這只是表示沒有檢測到語音，不是真正的錯誤
    if (errorMsg.contains('error_no_match')) {
      print('No speech detected, but continuing to listen...');
      // 在實時模式下，即使是 no_match 也要重新啟動
      if (_shouldKeepListening) {
        print('🔄 Restarting after no_match error in real-time mode...');
        _isListening = false;
        _restartListeningIfNeeded();
      }
      return;
    }

    // 如果是超時錯誤，嘗試重新開始監聽
    if (errorMsg.contains('timeout') ||
        errorMsg.contains('error_speech_timeout')) {
      print('Speech timeout detected - continuing to listen...');
      return;
    }

    // 只在非實時模式下才停止監聽
    print('Non-real-time mode: Speech error detected, stopping listening');
    _isListening = false;
    _listeningController?.add(false);
    _stopSoundLevelMonitoring();
  }

  void _onSpeechStatus(status) {
    if (kDebugMode) {
      print(
          'Speech status: $status (shouldKeepListening: $_shouldKeepListening, isListening: $_isListening)');
    }

    // 在實時模式下，完全忽略狀態變化，保持監聽
    if (_shouldKeepListening) {
      if (status == 'done' || status == 'notListening') {
        print('Real-time mode: Speech session ended, scheduling restart...');

        // 設置監聽狀態為false，但不停止音量監控
        _isListening = false;

        // 立即觸發重新啟動
        print('🚀 Triggering immediate restart from status change...');
        _restartListeningIfNeeded();
      } else if (status == 'listening') {
        print('✅ Speech recognition listening state confirmed');
        _isListening = true;
        _listeningController?.add(true);
      }
      return;
    }

    // 非實時模式下的正常處理
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _listeningController?.add(false);
      _stopSoundLevelMonitoring();
    }
  }

  bool _shouldKeepListening = false;
  String? _lastLocaleId;
  bool _lastPartialResults = true;
  bool _lastRealTimeMode = false;

  Timer? _restartTimer;

  void _restartListeningIfNeeded() {
    if (_shouldKeepListening && _lastLocaleId != null) {
      print('🔄 Scheduling auto-restart of speech recognition...');

      // 取消任何現有的重新啟動計時器
      _restartTimer?.cancel();

      // 立即重新啟動
      _restartTimer = Timer(Duration(milliseconds: 100), () async {
        if (_shouldKeepListening) {
          try {
            print('🔄 Auto-restarting speech recognition now...');

            // 確保先停止任何現有的監聽
            try {
              await _speechToText.stop();
            } catch (e) {
              print('Stop error (ignored): $e');
            }

            _isListening = false;

            // 重新啟動
            await _startListeningInternal(
              localeId: _lastLocaleId!,
              partialResults: _lastPartialResults,
              realTimeMode: _lastRealTimeMode,
            );

            print('✅ Speech recognition restarted successfully');
          } catch (e) {
            print('❌ Error restarting speech recognition: $e');
            // 如果失敗，短暫延遲後再次嘗試
            Future.delayed(Duration(milliseconds: 500), () {
              if (_shouldKeepListening) {
                _restartListeningIfNeeded();
              }
            });
          }
        }
      });
    }
  }

  Future<void> _startListeningInternal({
    required String localeId,
    required bool partialResults,
    required bool realTimeMode,
  }) async {
    if (realTimeMode) {
      // 實時模式：無限監聽，不設定時間限制
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        partialResults: partialResults,
        listenMode: ListenMode.search, // 搜索模式，持續監聽
        cancelOnError: false, // 不要因為錯誤就取消
        // 不設定 listenFor 和 pauseFor，讓它持續監聽
      );
    } else {
      // 正常模式：保持原來的設定
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        partialResults: partialResults,
        listenMode: ListenMode.confirmation,
        cancelOnError: false,
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 15),
      );
    }

    _isListening = true;
    _listeningController?.add(true);

    // 開始音量級別監控
    _startSoundLevelMonitoring();

    if (kDebugMode) {
      print(
          'Started listening in ${realTimeMode ? "real-time" : "standard"} mode...');
    }
  }

  Future<List<String>> get availableLocales async {
    if (!_isInitialized) return ['en-US', 'zh-CN', 'ja-JP'];
    try {
      final locales = await _speechToText.locales();
      final localeIds = locales.map((locale) => locale.localeId).toList();

      if (kDebugMode) {
        print('Available speech recognition locales: $localeIds');
        print('Japanese support: ${localeIds.any((id) => id.contains('ja'))}');
      }

      return localeIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available locales: $e');
      }
      return ['en-US', 'zh-CN', 'ja-JP']; // 預設支援的語言
    }
  }

  void _startSoundLevelMonitoring() {
    _soundLevelTimer?.cancel();
    _soundLevelTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isListening) {
        // 如果 speech_to_text 提供音量級別，我們可以使用它
        // 否則我們模擬一個基於隨機值的音量級別
        double soundLevel = 0.0;

        // 檢查是否有實際的音量級別（speech_to_text 6.x+ 版本支援）
        if (_speechToText.hasError == false && _isListening) {
          // 模擬音量級別 - 在實際實現中，這將來自麥克風
          soundLevel = (0.1 +
              (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0 * 0.8);
        }

        _soundLevelController?.add(soundLevel);
      }
    });
  }

  void _stopSoundLevelMonitoring() {
    _soundLevelTimer?.cancel();
    _soundLevelTimer = null;
    _soundLevelController?.add(0.0); // 重置音量為0
  }

  void dispose() {
    _shouldKeepListening = false;
    _restartTimer?.cancel();
    _speechResultController?.close();
    _listeningController?.close();
    _soundLevelController?.close();
    _soundLevelTimer?.cancel();
    _speechToText.cancel();
  }
}
