class LanguageModel {
  final String code;
  final String name;
  final String localeName;
  final String flag;
  final bool isSupported;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.localeName,
    required this.flag,
    this.isSupported = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModel &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class SupportedLanguages {
  static const List<LanguageModel> languages = [
    LanguageModel(
      code: 'zh-CN',
      name: '中文（簡體）',
      localeName: 'Chinese (Simplified)',
      flag: '🇨🇳',
    ),
    LanguageModel(
      code: 'zh-TW',
      name: '中文（繁體）',
      localeName: 'Chinese (Traditional)',
      flag: '🇹🇼',
    ),
    LanguageModel(
      code: 'en-US',
      name: '英文',
      localeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageModel(
      code: 'ja-JP',
      name: '日文',
      localeName: 'Japanese',
      flag: '🇯🇵',
    ),
    LanguageModel(
      code: 'ko-KR',
      name: '韓文',
      localeName: 'Korean',
      flag: '🇰🇷',
    ),
    LanguageModel(
      code: 'es-ES',
      name: '西班牙文',
      localeName: 'Spanish',
      flag: '🇪🇸',
    ),
    LanguageModel(
      code: 'fr-FR',
      name: '法文',
      localeName: 'French',
      flag: '🇫🇷',
    ),
    LanguageModel(
      code: 'de-DE',
      name: '德文',
      localeName: 'German',
      flag: '🇩🇪',
    ),
    LanguageModel(
      code: 'it-IT',
      name: '義大利文',
      localeName: 'Italian',
      flag: '🇮🇹',
    ),
    LanguageModel(
      code: 'pt-PT',
      name: '葡萄牙文',
      localeName: 'Portuguese',
      flag: '🇵🇹',
    ),
    LanguageModel(
      code: 'ru-RU',
      name: '俄文',
      localeName: 'Russian',
      flag: '🇷🇺',
    ),
    LanguageModel(
      code: 'ar-SA',
      name: '阿拉伯文',
      localeName: 'Arabic',
      flag: '🇸🇦',
    ),
    LanguageModel(
      code: 'hi-IN',
      name: '印地文',
      localeName: 'Hindi',
      flag: '🇮🇳',
    ),
    LanguageModel(
      code: 'th-TH',
      name: '泰文',
      localeName: 'Thai',
      flag: '🇹🇭',
    ),
    LanguageModel(
      code: 'vi-VN',
      name: '越南文',
      localeName: 'Vietnamese',
      flag: '🇻🇳',
    ),
  ];

  static LanguageModel getLanguage(String code) {
    return languages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => languages.first,
    );
  }

  static List<LanguageModel> getAvailableLanguages() {
    return languages.where((lang) => lang.isSupported).toList();
  }
}