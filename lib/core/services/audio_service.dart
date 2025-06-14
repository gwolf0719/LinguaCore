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

  bool _isInitialized = false;
  bool _isListening = false;

  Stream<String> get speechResults => _speechResultController!.stream;
  Stream<bool> get listeningStatus => _listeningController!.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _speechResultController = StreamController<String>.broadcast();
      _listeningController = StreamController<bool>.broadcast();

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
    final micPermission = await Permission.microphone.request();
    if (micPermission != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> startListening({
    String localeId = 'en-US',
    bool partialResults = true,
  }) async {
    if (!_isInitialized || _isListening) return;

    try {
      if (kDebugMode) {
        print('Starting speech recognition with locale: $localeId');
      }

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        partialResults: partialResults,
        listenMode: ListenMode.confirmation,
        cancelOnError: false, // 不要因為錯誤就取消
        listenFor: const Duration(seconds: 60), // 延長聽取時間
        pauseFor: const Duration(seconds: 8), // 延長暫停時間
      );

      _isListening = true;
      _listeningController?.add(true);

      if (kDebugMode) {
        print('Started listening...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _listeningController?.add(false);

      if (kDebugMode) {
        print('Stopped listening');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping speech recognition: $e');
      }
    }
  }

  void _onSpeechResult(result) {
    if (result.recognizedWords.isNotEmpty) {
      _speechResultController?.add(result.recognizedWords);

      if (kDebugMode) {
        print('Speech result: ${result.recognizedWords}');
      }
    }
  }

  void _onSpeechError(error) {
    if (kDebugMode) {
      print('Speech error: $error');
    }

    // 如果是超時錯誤，不要停止監聽，繼續嘗試
    if (error.toString().contains('timeout')) {
      print('Speech timeout detected, but continuing to listen...');
      return; // 不要改變監聽狀態
    }

    _isListening = false;
    _listeningController?.add(false);
  }

  void _onSpeechStatus(status) {
    if (kDebugMode) {
      print('Speech status: $status');
    }

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _listeningController?.add(false);
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

  void dispose() {
    _speechResultController?.close();
    _listeningController?.close();
    _speechToText.cancel();
  }
}
