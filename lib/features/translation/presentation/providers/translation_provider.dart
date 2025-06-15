import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';

enum TranslationMode { listening, translating, speaking, idle }

enum TranslationSubState { speechRecognized, translating, translated, speaking }

enum ConversationRole { user, other }

class TranslationState {
  final TranslationMode mode;
  final TranslationSubState? subState;
  final ConversationRole currentRole;
  final String currentText;
  final String translatedText;
  final bool isInitialized;
  final double downloadProgress;
  final List<ConversationItem> conversationHistory;
  final String statusMessage;
  final double soundLevel;

  const TranslationState({
    this.mode = TranslationMode.idle,
    this.subState,
    this.currentRole = ConversationRole.other,
    this.currentText = '',
    this.translatedText = '',
    this.isInitialized = false,
    this.downloadProgress = 0.0,
    this.conversationHistory = const [],
    this.statusMessage = '',
    this.soundLevel = 0.0,
  });

  TranslationState copyWith({
    TranslationMode? mode,
    TranslationSubState? subState,
    ConversationRole? currentRole,
    String? currentText,
    String? translatedText,
    bool? isInitialized,
    double? downloadProgress,
    List<ConversationItem>? conversationHistory,
    String? statusMessage,
    double? soundLevel,
  }) {
    return TranslationState(
      mode: mode ?? this.mode,
      subState: subState ?? this.subState,
      currentRole: currentRole ?? this.currentRole,
      currentText: currentText ?? this.currentText,
      translatedText: translatedText ?? this.translatedText,
      isInitialized: isInitialized ?? this.isInitialized,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      statusMessage: statusMessage ?? this.statusMessage,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

class ConversationItem {
  final ConversationRole role;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  const ConversationItem({
    required this.role,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  });
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final AudioService _audioService = sl<AudioService>();
  final TranslationService _translationService = sl<TranslationService>();
  final TTSService _ttsService = sl<TTSService>();
  final Ref _ref;

  TranslationNotifier(this._ref) : super(const TranslationState()) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize all services first
      if (!_audioService.isInitialized) {
        await _audioService.initialize();
      }

      if (!_translationService.isInitialized) {
        // Listen to translation download progress before initializing
        _translationService.downloadProgress.listen((progress) {
          state = state.copyWith(downloadProgress: progress);
          print(
              'Translation download progress: ${(progress * 100).toStringAsFixed(1)}%');

          // 確保UI更新
          if (progress >= 1.0) {
            print('Download completed - UI should update now');
          }
        });

        // Try normal initialization first, then skip download if it hangs
        try {
          await _translationService.initialize().timeout(Duration(seconds: 20));
        } catch (e) {
          print('Normal initialization failed or timed out: $e');
          print('Retrying with skip model download...');
          await _translationService.initialize(skipModelDownload: true);
        }
      }

      if (!_ttsService.isInitialized) {
        await _ttsService.initialize();
      }

      // Listen to speech recognition results
      _audioService.speechResults.listen((text) {
        _handleSpeechResult(text);
      });

      // Listen to sound level changes
      _audioService.soundLevel.listen((level) {
        state = state.copyWith(soundLevel: level);
      });

      // Listen to speech recognition status for auto-retry
      _audioService.listeningStatus.listen((isListening) {
        print('Speech listening status changed: $isListening');
        if (!isListening && state.mode == TranslationMode.listening) {
          // 如果正在聽取模式但語音識別停止了，嘗試重新開始
          print(
              'Speech recognition stopped unexpectedly, attempting restart...');
          _restartListening();
        }
      });

      // Update initialization state
      final allInitialized = _audioService.isInitialized &&
          _translationService.isInitialized &&
          _ttsService.isInitialized;

      state = state.copyWith(
        isInitialized: allInitialized,
        downloadProgress:
            allInitialized ? 1.0 : state.downloadProgress, // 確保初始化完成時進度為100%
      );

      print('All services initialized: $allInitialized');
      print('Final download progress: ${state.downloadProgress}');
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  Future<void> _handleSpeechResult(String recognizedText) async {
    if (recognizedText.isEmpty) {
      print('Received empty speech result');
      return;
    }

    print('=== SPEECH RECOGNITION RESULT ===');
    print('Recognized text: "$recognizedText"');
    final languageSettings = _ref.read(languageSettingsProvider);
    print(
        'Language settings: native=${languageSettings.nativeLanguage.name} (${languageSettings.nativeLanguage.code}), target=${languageSettings.targetLanguage.name} (${languageSettings.targetLanguage.code})');
    print('Current role: ${state.currentRole}');

    // 步驟1: 顯示語音識別結果
    String currentSourceLanguage;
    String sourceLanguageCode;

    if (state.currentRole == ConversationRole.other) {
      // 對方說話 -> 翻譯成中文
      currentSourceLanguage = languageSettings.targetLanguage.name;
      sourceLanguageCode = languageSettings.targetLanguage.code;
    } else {
      // 用戶說話 -> 翻譯成中文
      currentSourceLanguage = languageSettings.nativeLanguage.name;
      sourceLanguageCode = languageSettings.nativeLanguage.code;
    }

    state = state.copyWith(
      currentText: recognizedText,
      mode: TranslationMode.translating,
      subState: TranslationSubState.speechRecognized,
      statusMessage: '✅ 已識別$currentSourceLanguage: "$recognizedText"',
    );

    // 延遲一下讓用戶看到識別結果
    await Future.delayed(Duration(milliseconds: 500));

    // 步驟2: 開始翻譯
    state = state.copyWith(
      subState: TranslationSubState.translating,
      statusMessage: '🔄 正在翻譯中...',
    );

    String translatedText;
    String targetLanguage;
    String targetLanguageCode;

    // 統一翻譯成中文（根據用戶需求）
    targetLanguage = '中文';
    targetLanguageCode = 'zh';

    print('Translating from $currentSourceLanguage to Chinese');

    translatedText =
        await _translateText(recognizedText, sourceLanguageCode, 'zh');

    print('Translation result: "$translatedText"');

    // 步驟3: 顯示翻譯結果
    state = state.copyWith(
      translatedText: translatedText,
      subState: TranslationSubState.translated,
      statusMessage: '✅ $targetLanguage翻譯: "$translatedText"',
    );

    // 延遲一下讓用戶看到翻譯結果
    await Future.delayed(Duration(milliseconds: 800));

    // 步驟4: 開始語音播放
    state = state.copyWith(
      mode: TranslationMode.speaking,
      subState: TranslationSubState.speaking,
      statusMessage: '🔊 正在播放$targetLanguage語音...',
    );

    print('Speaking translation in $targetLanguage...');
    await _speakText(translatedText, targetLanguageCode);

    // 步驟5: 完成並回到待機狀態
    final newItem = ConversationItem(
      role: state.currentRole,
      originalText: recognizedText,
      translatedText: translatedText,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      conversationHistory: [...state.conversationHistory, newItem],
      mode: TranslationMode.idle,
      subState: null,
      statusMessage: '✅ 翻譯完成',
    );

    print('=== TRANSLATION COMPLETE ===');

    // 延遲一下顯示完成狀態，然後清除狀態消息
    await Future.delayed(Duration(milliseconds: 1500));
    if (state.mode == TranslationMode.idle) {
      state = state.copyWith(statusMessage: '');
    }
  }

  Future<void> startListeningForOther() async {
    if (!state.isInitialized) {
      print('Services not initialized yet, cannot start listening');
      return;
    }

    final languageSettings = _ref.read(languageSettingsProvider);
    print('Starting to listen for OTHER person...');
    print(
        'Language settings: native=${languageSettings.nativeLanguage.name} (${languageSettings.nativeLanguage.code}), target=${languageSettings.targetLanguage.name} (${languageSettings.targetLanguage.code})');
    print(
        'Will listen in: ${languageSettings.targetLanguage.name} (${languageSettings.targetLocaleId})');
    print(
        'Will translate to: ${languageSettings.nativeLanguage.name} (${languageSettings.nativeLanguage.code})');

    // Check available locales first
    final availableLocales = await _audioService.availableLocales;
    print('Available speech locales: $availableLocales');

    String targetLocale = languageSettings.targetLocaleId;

    // If Japanese is not available, try alternatives
    if (!availableLocales.contains(targetLocale)) {
      print(
          'Target locale $targetLocale not available, checking alternatives...');

      // Try common Japanese locale variations
      final japaneseAlternatives = ['ja-JP', 'ja', 'ja_JP'];
      String? foundLocale;

      for (final alt in japaneseAlternatives) {
        if (availableLocales.contains(alt)) {
          foundLocale = alt;
          break;
        }
      }

      if (foundLocale != null) {
        targetLocale = foundLocale;
        print('Using alternative Japanese locale: $targetLocale');
      } else {
        print('No Japanese locale found, falling back to Chinese: zh-TW');
        targetLocale = 'zh-TW'; // Fallback to Chinese for testing
      }
    }

    state = state.copyWith(
      currentRole: ConversationRole.other,
      mode: TranslationMode.listening,
      currentText: '',
      translatedText: '',
    );

    // Stop any current TTS
    await _ttsService.stop();

    // Start listening for target language
    await _audioService.startListening(
      localeId: targetLocale,
      partialResults: true,
    );

    print('Started listening for speech with locale: $targetLocale');
  }

  Future<void> startListeningForUser() async {
    if (!state.isInitialized) return;

    final languageSettings = _ref.read(languageSettingsProvider);

    state = state.copyWith(
      currentRole: ConversationRole.user,
      mode: TranslationMode.listening,
      currentText: '',
      translatedText: '',
    );

    // Stop any current TTS
    await _ttsService.stop();

    // Start listening for native language
    await _audioService.startListening(
      localeId: languageSettings.nativeLocaleId,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _audioService.stopListening();
    state = state.copyWith(mode: TranslationMode.idle);
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    state = state.copyWith(mode: TranslationMode.idle);
  }

  void clearHistory() {
    state = state.copyWith(conversationHistory: []);
  }

  void switchRole() {
    final newRole = state.currentRole == ConversationRole.user
        ? ConversationRole.other
        : ConversationRole.user;

    state = state.copyWith(currentRole: newRole);
  }

  // Helper method for translation
  Future<String> _translateText(
      String text, String fromLang, String toLang) async {
    // Use the new universal translate method that supports multiple language pairs
    return await _translationService.translate(text, fromLang, toLang);
  }

  // Helper method for text-to-speech
  Future<void> _speakText(String text, String languageCode) async {
    if (languageCode.startsWith('zh')) {
      await _ttsService.speakChinese(text);
    } else if (languageCode.startsWith('ja')) {
      await _ttsService.speakJapanese(text);
    } else if (languageCode.startsWith('en')) {
      await _ttsService.speakEnglish(text);
    } else {
      // For other languages, try to speak in English as fallback
      await _ttsService.speakEnglish(text);
    }
  }

  // 重新開始監聽的輔助方法
  Future<void> _restartListening() async {
    await Future.delayed(const Duration(seconds: 3)); // 等待3秒再重試

    if (state.mode == TranslationMode.listening) {
      final languageSettings = _ref.read(languageSettingsProvider);
      String targetLocale;

      if (state.currentRole == ConversationRole.other) {
        targetLocale = languageSettings.targetLocaleId;
        print('Restarting listening for OTHER role with locale: $targetLocale');
      } else {
        targetLocale = languageSettings.nativeLocaleId;
        print('Restarting listening for USER role with locale: $targetLocale');
      }

      await _audioService.startListening(
        localeId: targetLocale,
        partialResults: true,
      );
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _translationService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>(
  (ref) => TranslationNotifier(ref),
);
