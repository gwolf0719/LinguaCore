import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/language_model.dart';

class LanguageSettings {
  final LanguageModel nativeLanguage;
  final LanguageModel targetLanguage;

  const LanguageSettings({
    required this.nativeLanguage,
    required this.targetLanguage,
  });

  LanguageSettings copyWith({
    LanguageModel? nativeLanguage,
    LanguageModel? targetLanguage,
  }) {
    return LanguageSettings(
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }
}

class LanguageSettingsNotifier extends StateNotifier<LanguageSettings> {
  LanguageSettingsNotifier()
      : super(
          LanguageSettings(
            nativeLanguage: SupportedLanguages.getLanguage('zh-CN'),
            targetLanguage: SupportedLanguages.getLanguage('en-US'),
          ),
        );

  void setNativeLanguage(LanguageModel language) {
    if (language.code == state.targetLanguage.code) {
      // 如果選擇的母語和目標語言相同，則交換它們
      state = state.copyWith(
        nativeLanguage: language,
        targetLanguage: state.nativeLanguage,
      );
    } else {
      state = state.copyWith(nativeLanguage: language);
    }
  }

  void setTargetLanguage(LanguageModel language) {
    if (language.code == state.nativeLanguage.code) {
      // 如果選擇的目標語言和母語相同，則交換它們
      state = state.copyWith(
        targetLanguage: language,
        nativeLanguage: state.targetLanguage,
      );
    } else {
      state = state.copyWith(targetLanguage: language);
    }
  }

  void swapLanguages() {
    state = state.copyWith(
      nativeLanguage: state.targetLanguage,
      targetLanguage: state.nativeLanguage,
    );
  }

  // 獲取語音識別的 locale ID
  String get nativeLocaleId {
    return _convertToLocaleId(state.nativeLanguage.code);
  }

  String get targetLocaleId {
    return _convertToLocaleId(state.targetLanguage.code);
  }

  // 轉換為 ML Kit 支援的語言代碼
  String _convertToLocaleId(String languageCode) {
    switch (languageCode) {
      case 'zh-CN':
        return 'zh-CN';
      case 'zh-TW':
        return 'zh-TW';
      case 'en-US':
        return 'en-US';
      case 'ja-JP':
        return 'ja-JP';
      case 'ko-KR':
        return 'ko-KR';
      case 'es-ES':
        return 'es-ES';
      case 'fr-FR':
        return 'fr-FR';
      case 'de-DE':
        return 'de-DE';
      case 'it-IT':
        return 'it-IT';
      case 'pt-PT':
        return 'pt-PT';
      case 'ru-RU':
        return 'ru-RU';
      case 'ar-SA':
        return 'ar-SA';
      case 'hi-IN':
        return 'hi-IN';
      case 'th-TH':
        return 'th-TH';
      case 'vi-VN':
        return 'vi-VN';
      default:
        return 'en-US';
    }
  }
}

final languageSettingsProvider =
    StateNotifierProvider<LanguageSettingsNotifier, LanguageSettings>(
  (ref) => LanguageSettingsNotifier(),
);