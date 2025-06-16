import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';

enum RealTimeMode { idle, listening, translating, speaking }

class RealTimeTranslationState {
  final RealTimeMode mode;
  final String currentSpeech;
  final String lastTranslation;
  final List<String> speechSegments;
  final List<String> translationSegments;
  final bool isInitialized;
  final double soundLevel;
  final String statusMessage;

  const RealTimeTranslationState({
    this.mode = RealTimeMode.idle,
    this.currentSpeech = '',
    this.lastTranslation = '',
    this.speechSegments = const [],
    this.translationSegments = const [],
    this.isInitialized = false,
    this.soundLevel = 0.0,
    this.statusMessage = '',
  });

  RealTimeTranslationState copyWith({
    RealTimeMode? mode,
    String? currentSpeech,
    String? lastTranslation,
    List<String>? speechSegments,
    List<String>? translationSegments,
    bool? isInitialized,
    double? soundLevel,
    String? statusMessage,
  }) {
    return RealTimeTranslationState(
      mode: mode ?? this.mode,
      currentSpeech: currentSpeech ?? this.currentSpeech,
      lastTranslation: lastTranslation ?? this.lastTranslation,
      speechSegments: speechSegments ?? this.speechSegments,
      translationSegments: translationSegments ?? this.translationSegments,
      isInitialized: isInitialized ?? this.isInitialized,
      soundLevel: soundLevel ?? this.soundLevel,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class RealTimeTranslationNotifier
    extends StateNotifier<RealTimeTranslationState> {
  final AudioService _audioService = sl<AudioService>();
  final TranslationService _translationService = sl<TranslationService>();
  final TTSService _ttsService = sl<TTSService>();
  final Ref _ref;

  Timer? _translationTimer;
  String _lastProcessedText = '';
  bool _isTranslating = false;
  StreamSubscription? _speechSubscription;
  StreamSubscription? _soundLevelSubscription;

  RealTimeTranslationNotifier(this._ref)
      : super(const RealTimeTranslationState()) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      print('🔧 Checking service initialization...');

      // 檢查各個服務的初始化狀態
      print('AudioService initialized: ${_audioService.isInitialized}');
      print(
          'TranslationService initialized: ${_translationService.isInitialized}');
      print('TTSService initialized: ${_ttsService.isInitialized}');

      // 如果未初始化，嘗試重新初始化
      if (!_audioService.isInitialized) {
        print('🔧 Initializing AudioService...');
        await _audioService.initialize();
      }

      if (!_translationService.isInitialized) {
        print('🔧 Initializing TranslationService...');
        await _translationService.initialize();
      }

      if (!_ttsService.isInitialized) {
        print('🔧 Initializing TTSService...');
        await _ttsService.initialize();
      }

      final allInitialized = _audioService.isInitialized &&
          _translationService.isInitialized &&
          _ttsService.isInitialized;

      state = state.copyWith(
        isInitialized: allInitialized,
        statusMessage: allInitialized ? '已準備就緒' : '初始化中...',
      );

      if (allInitialized) {
        _setupListeners();
        print('✅ All real-time translation services initialized');

        // 測試麥克風權限
        await _testMicrophonePermission();
      } else {
        print('❌ Some services failed to initialize');
      }
    } catch (e) {
      print('❌ Error initializing real-time translation: $e');
      state = state.copyWith(
        isInitialized: false,
        statusMessage: '初始化失敗：$e',
      );
    }
  }

  Future<void> _testMicrophonePermission() async {
    try {
      final availableLocales = await _audioService.availableLocales;
      print('🎤 Available speech locales: $availableLocales');

      if (availableLocales.isEmpty) {
        print(
            '❌ No speech recognition locales available - check microphone permission');
        state = state.copyWith(
          statusMessage: '麥克風權限可能被拒絕，請檢查應用設定',
        );
      }
    } catch (e) {
      print('❌ Error testing microphone permission: $e');
      state = state.copyWith(
        statusMessage: '麥克風檢測失敗：$e',
      );
    }
  }

  void _setupListeners() {
    // 監聽語音識別結果（部分結果）
    _speechSubscription = _audioService.speechResults.listen((text) {
      _handlePartialSpeechResult(text);
    });

    // 監聽音量級別
    _soundLevelSubscription = _audioService.soundLevel.listen((level) {
      state = state.copyWith(soundLevel: level);
    });
  }

  Future<void> startRealTimeTranslation() async {
    print('🚀 Starting real-time translation...');
    print('Services initialized: ${state.isInitialized}');
    print('Current mode: ${state.mode}');

    if (!state.isInitialized) {
      print('❌ Services not initialized - attempting to initialize...');
      await _initializeServices();

      if (!state.isInitialized) {
        state = state.copyWith(
          statusMessage: '服務初始化失敗，請檢查權限設定',
        );
        return;
      }
    }

    if (state.mode != RealTimeMode.idle) {
      print('❌ Already in translation mode: ${state.mode}');
      return;
    }

    try {
      final languageSettings = _ref.read(languageSettingsProvider);
      print(
          'Language settings: native=${languageSettings.nativeLanguage}, target=${languageSettings.targetLanguage}');

      state = state.copyWith(
        mode: RealTimeMode.listening,
        currentSpeech: '',
        lastTranslation: '',
        speechSegments: [],
        translationSegments: [],
        statusMessage: '🔧 準備語音識別...',
      );

      // 停止任何現有的TTS
      await _ttsService.stop();

      // 獲取可用語言
      print('🔍 Getting available locales...');
      final availableLocales = await _audioService.availableLocales;
      print('Available locales: $availableLocales');

      if (availableLocales.isEmpty) {
        throw Exception(
            'No speech recognition locales available. Check microphone permission.');
      }

      String targetLocale = languageSettings.targetLocaleId;
      print('Target locale: $targetLocale');

      // 檢查日文支援
      if (!availableLocales.contains(targetLocale)) {
        final japaneseAlternatives = [
          'ja-JP',
          'ja',
          'ja_JP',
          'zh-TW',
          'zh-CN',
          'en-US'
        ];
        String? foundLocale;

        for (final alt in japaneseAlternatives) {
          if (availableLocales.contains(alt)) {
            foundLocale = alt;
            print('Found alternative locale: $foundLocale');
            break;
          }
        }

        if (foundLocale != null) {
          targetLocale = foundLocale;
        } else {
          throw Exception('No supported locale found in: $availableLocales');
        }
      }

      state = state.copyWith(
        statusMessage: '🎤 啟動語音識別 ($targetLocale)...',
      );

      // 開始連續語音識別（實時模式）
      print('🎤 Starting speech recognition with locale: $targetLocale');
      await _audioService.startListening(
        localeId: targetLocale,
        partialResults: true, // 啟用部分結果
        realTimeMode: true, // 啟用實時模式
      );

      state = state.copyWith(
        statusMessage: '🎤 正在聽取語音...',
      );

      // 啟動實時翻譯處理器
      _startRealTimeTranslationProcessor();

      print(
          '✅ Real-time translation started successfully with locale: $targetLocale');
    } catch (e) {
      print('❌ Error starting real-time translation: $e');
      state = state.copyWith(
        mode: RealTimeMode.idle,
        statusMessage: '啟動失敗: $e',
      );
    }
  }

  void _handlePartialSpeechResult(String text) {
    if (state.mode != RealTimeMode.listening || text.isEmpty) return;

    print('📝 Partial speech result: "$text"');

    // 更新當前語音文字
    state = state.copyWith(
      currentSpeech: text,
      statusMessage: '🎤 聽取中：$text',
    );

    // 只有在文字有實際意義時才翻譯（至少2個字符）
    if (text.trim().length >= 2) {
      _queueTranslation(text);
    }
  }

  void _queueTranslation(String text) {
    print(
        '🔄 Queuing translation for: "$text" (last processed: "$_lastProcessedText")');

    // 簡化邏輯：如果是全新的文字，直接翻譯整句
    if (text != _lastProcessedText) {
      print('✨ New content detected, translating full text: "$text"');

      // 極速翻譯，接近零延遲
      _translationTimer?.cancel();
      _translationTimer = Timer(Duration(milliseconds: 50), () {
        _translateFullContent(text);
      });
    } else {
      print('⏩ Same content, skipping translation');
    }
  }

  Future<void> _translateFullContent(String fullText) async {
    if (_isTranslating || state.mode != RealTimeMode.listening) {
      print('⏸️ Translation skipped - already translating or wrong mode');
      return;
    }

    _isTranslating = true;
    print('🔄 Starting full translation of: "$fullText"');

    try {
      state = state.copyWith(
        mode: RealTimeMode.translating,
        statusMessage: '🔄 完整翻譯：$fullText',
      );

      // 翻譯完整文字
      final translation =
          await _translationService.translate(fullText, 'ja', 'zh');
      print('✅ Full translation result: "$translation"');

      if (translation.isNotEmpty) {
        // 每次都是新的翻譯結果
        state = state.copyWith(
          mode: RealTimeMode.speaking,
          lastTranslation: translation,
          translationSegments: [translation],
          statusMessage: '🔊 播放翻譯：$translation',
        );

        // 立即播放翻譯
        _speakTranslation(translation);

        // 更新已處理的文字
        _lastProcessedText = fullText;
        print('📝 Updated processed text to: "$_lastProcessedText"');
      }
    } catch (e) {
      print('❌ Error translating: $e');
    } finally {
      _isTranslating = false;

      // 極速回到聽取模式，達到連續翻譯
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted && state.mode == RealTimeMode.speaking) {
          state = state.copyWith(
            mode: RealTimeMode.listening,
            statusMessage: '🎤 持續聽取中...',
          );
        }
      });
    }
  }

  // 保留舊方法以避免其他地方的調用錯誤
  Future<void> _translateNewContent(String fullText, String newPart) async {
    // 重定向到新的完整翻譯方法
    await _translateFullContent(fullText);
  }

  Timer? _processingTimer;

  void _startRealTimeTranslationProcessor() {
    // 取消任何現有的Timer
    _processingTimer?.cancel();

    // 高頻率檢查，實現超低延遲
    _processingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted || state.mode == RealTimeMode.idle) {
        timer.cancel();
        _processingTimer = null;
        return;
      }

      // 檢查是否有長時間沒有新語音
      if (state.currentSpeech.isNotEmpty &&
          state.mode == RealTimeMode.listening) {
        // 處理語音斷句邏輯
        _processCompleteSentence();
      }
    });
  }

  void _processCompleteSentence() {
    if (state.currentSpeech.isEmpty) return;

    // 檢查是否是完整的句子（簡單邏輯）
    final text = state.currentSpeech.trim();
    if (text.length > 10 &&
        (text.endsWith('。') || text.endsWith('？') || text.endsWith('！'))) {
      // 保存完整的句子
      final newSpeechSegments = [...state.speechSegments, text];

      state = state.copyWith(
        speechSegments: newSpeechSegments,
        currentSpeech: '', // 清空當前語音，準備下一句
      );

      _lastProcessedText = ''; // 重置處理狀態
    }
  }

  Future<void> _speakTranslation(String text) async {
    try {
      // 使用中文語音播放
      await _ttsService.speakChinese(text);
    } catch (e) {
      print('❌ Error speaking translation: $e');
    }
  }

  Future<void> stopRealTimeTranslation() async {
    try {
      _translationTimer?.cancel();
      await _audioService.stopListening();
      await _ttsService.stop();

      state = state.copyWith(
        mode: RealTimeMode.idle,
        statusMessage: '實時翻譯已停止',
      );

      _lastProcessedText = '';
      _isTranslating = false;

      print('🛑 Real-time translation stopped');
    } catch (e) {
      print('❌ Error stopping real-time translation: $e');
    }
  }

  void clearHistory() {
    state = state.copyWith(
      speechSegments: [],
      translationSegments: [],
      currentSpeech: '',
      lastTranslation: '',
    );
  }

  @override
  void dispose() {
    _translationTimer?.cancel();
    _processingTimer?.cancel();
    _speechSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    super.dispose();
  }
}

final realTimeTranslationProvider = StateNotifierProvider<
    RealTimeTranslationNotifier, RealTimeTranslationState>((ref) {
  return RealTimeTranslationNotifier(ref);
});
