import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';

enum TranslationMode { listening, translating, speaking, idle }

enum ConversationRole { user, other }

class TranslationState {
  final TranslationMode mode;
  final ConversationRole currentRole;
  final String currentText;
  final String translatedText;
  final bool isInitialized;
  final double downloadProgress;
  final List<ConversationItem> conversationHistory;

  const TranslationState({
    this.mode = TranslationMode.idle,
    this.currentRole = ConversationRole.other,
    this.currentText = '',
    this.translatedText = '',
    this.isInitialized = false,
    this.downloadProgress = 0.0,
    this.conversationHistory = const [],
  });

  TranslationState copyWith({
    TranslationMode? mode,
    ConversationRole? currentRole,
    String? currentText,
    String? translatedText,
    bool? isInitialized,
    double? downloadProgress,
    List<ConversationItem>? conversationHistory,
  }) {
    return TranslationState(
      mode: mode ?? this.mode,
      currentRole: currentRole ?? this.currentRole,
      currentText: currentText ?? this.currentText,
      translatedText: translatedText ?? this.translatedText,
      isInitialized: isInitialized ?? this.isInitialized,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      conversationHistory: conversationHistory ?? this.conversationHistory,
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

    state = state.copyWith(
      currentText: recognizedText,
      mode: TranslationMode.translating,
    );

    String translatedText;

    // Translate based on current role and language settings
    if (state.currentRole == ConversationRole.other) {
      // Other person speaking -> translate to user's native language
      print(
          'Translating from ${languageSettings.targetLanguage.name} to ${languageSettings.nativeLanguage.name}');
      print(
          'Translation: "${recognizedText}" (${languageSettings.targetLanguage.code}) -> ${languageSettings.nativeLanguage.code}');

      translatedText = await _translateText(
          recognizedText,
          languageSettings.targetLanguage.code,
          languageSettings.nativeLanguage.code);

      print('Translation result: "$translatedText"');

      // Speak in user's native language
      state = state.copyWith(
        translatedText: translatedText,
        mode: TranslationMode.speaking,
      );

      print(
          'Speaking translation in ${languageSettings.nativeLanguage.name}...');
      await _speakText(translatedText, languageSettings.nativeLanguage.code);
    } else {
      // User speaking -> translate to target language
      print(
          'Translating from ${languageSettings.nativeLanguage.name} to ${languageSettings.targetLanguage.name}');
      print(
          'Translation: "${recognizedText}" (${languageSettings.nativeLanguage.code}) -> ${languageSettings.targetLanguage.code}');

      translatedText = await _translateText(
          recognizedText,
          languageSettings.nativeLanguage.code,
          languageSettings.targetLanguage.code);

      print('Translation result: "$translatedText"');

      // Speak in target language
      state = state.copyWith(
        translatedText: translatedText,
        mode: TranslationMode.speaking,
      );

      print(
          'Speaking translation in ${languageSettings.targetLanguage.name}...');
      await _speakText(translatedText, languageSettings.targetLanguage.code);
    }

    // Add to conversation history
    final newItem = ConversationItem(
      role: state.currentRole,
      originalText: recognizedText,
      translatedText: translatedText,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      conversationHistory: [...state.conversationHistory, newItem],
      mode: TranslationMode.idle,
    );

    print('=== TRANSLATION COMPLETE ===');
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

    state = state.copyWith(
      currentRole: ConversationRole.other,
      mode: TranslationMode.listening,
      currentText: '',
      translatedText: '',
    );

    // Stop any current TTS
    await _ttsService.stop();

    // Start listening for target language (should be Japanese)
    await _audioService.startListening(
      localeId: languageSettings.targetLocaleId,
      partialResults: true,
    );

    print(
        'Started listening for ${languageSettings.targetLanguage.name} speech...');
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
