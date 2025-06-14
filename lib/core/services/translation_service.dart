import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final Map<String, OnDeviceTranslator> _translators = {};

  bool _isInitialized = false;
  bool _modelsDownloaded = false;

  StreamController<double>? _downloadProgressController;

  Stream<double> get downloadProgress => _downloadProgressController!.stream;
  bool get isInitialized => _isInitialized;
  bool get modelsDownloaded => _modelsDownloaded;

  Future<void> initialize() async {
    try {
      _downloadProgressController = StreamController<double>.broadcast();

      // Initialize translators
      _initializeTranslators();

      // Download models if not available
      await _downloadModelsIfNeeded();

      _isInitialized = true;

      if (kDebugMode) {
        print('TranslationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TranslationService initialization error: $e');
      }
    }
  }

  void _initializeTranslators() {
    // Chinese to Japanese
    _translators['zh-ja'] = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.chinese,
      targetLanguage: TranslateLanguage.japanese,
    );

    // Japanese to Chinese
    _translators['ja-zh'] = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.japanese,
      targetLanguage: TranslateLanguage.chinese,
    );

    // Chinese to English
    _translators['zh-en'] = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.chinese,
      targetLanguage: TranslateLanguage.english,
    );

    // English to Chinese
    _translators['en-zh'] = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.chinese,
    );

    // Japanese to English
    _translators['ja-en'] = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.japanese,
      targetLanguage: TranslateLanguage.english,
    );

    // English to Japanese
    _translators['en-ja'] = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.japanese,
    );
  }

  Future<void> _downloadModelsIfNeeded() async {
    final modelManager = OnDeviceTranslatorModelManager();

    try {
      // Check if required models are downloaded
      final isEnglishDownloaded = await modelManager.isModelDownloaded(
        TranslateLanguage.english.bcpCode,
      );
      final isChineseDownloaded = await modelManager.isModelDownloaded(
        TranslateLanguage.chinese.bcpCode,
      );
      final isJapaneseDownloaded = await modelManager.isModelDownloaded(
        TranslateLanguage.japanese.bcpCode,
      );

      if (kDebugMode) {
        print('Model download status:');
        print('Chinese: $isChineseDownloaded');
        print('Japanese: $isJapaneseDownloaded');
        print('English: $isEnglishDownloaded');
      }

      // 如果所有模型都已下載，直接設置進度為100%
      if (isChineseDownloaded && isJapaneseDownloaded && isEnglishDownloaded) {
        _modelsDownloaded = true;
        _downloadProgressController?.add(1.0);
        if (kDebugMode) {
          print('All models already downloaded');
        }
        return;
      }

      double progress = 0.0;
      int totalModels = 3;
      int downloadedCount = 0;

      // 計算已下載的模型數量
      if (isChineseDownloaded) downloadedCount++;
      if (isJapaneseDownloaded) downloadedCount++;
      if (isEnglishDownloaded) downloadedCount++;

      if (!isChineseDownloaded) {
        progress = downloadedCount / totalModels;
        _downloadProgressController?.add(progress);

        if (kDebugMode) {
          print(
              'Downloading Chinese model... Progress: ${(progress * 100).toStringAsFixed(1)}%');
        }

        await modelManager.downloadModel(
          TranslateLanguage.chinese.bcpCode,
        );
        downloadedCount++;
        progress = downloadedCount / totalModels;
        _downloadProgressController?.add(progress);

        if (kDebugMode) {
          print('Chinese translation model downloaded');
        }
      }

      if (!isJapaneseDownloaded) {
        progress = downloadedCount / totalModels;
        _downloadProgressController?.add(progress);

        if (kDebugMode) {
          print(
              'Downloading Japanese model... Progress: ${(progress * 100).toStringAsFixed(1)}%');
        }

        await modelManager.downloadModel(
          TranslateLanguage.japanese.bcpCode,
        );
        downloadedCount++;
        progress = downloadedCount / totalModels;
        _downloadProgressController?.add(progress);

        if (kDebugMode) {
          print('Japanese translation model downloaded');
        }
      }

      if (!isEnglishDownloaded) {
        progress = downloadedCount / totalModels;
        _downloadProgressController?.add(progress);

        if (kDebugMode) {
          print(
              'Downloading English model... Progress: ${(progress * 100).toStringAsFixed(1)}%');
        }

        await modelManager.downloadModel(
          TranslateLanguage.english.bcpCode,
        );
        downloadedCount++;
        progress = downloadedCount / totalModels;
        _downloadProgressController?.add(progress);

        if (kDebugMode) {
          print('English translation model downloaded');
        }
      }

      _modelsDownloaded = true;
      _downloadProgressController?.add(1.0);

      if (kDebugMode) {
        print('All models download completed!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading translation models: $e');
      }
      throw e;
    }
  }

  Future<String> translate(
      String text, String sourceLanguageCode, String targetLanguageCode) async {
    if (!_isInitialized || text.trim().isEmpty) {
      return text;
    }

    // Convert language codes to simplified format
    final sourceCode = _getLanguagePrefix(sourceLanguageCode);
    final targetCode = _getLanguagePrefix(targetLanguageCode);

    if (sourceCode == targetCode) {
      return text; // Same language, no translation needed
    }

    final translatorKey = '$sourceCode-$targetCode';
    final translator = _translators[translatorKey];

    if (translator == null) {
      if (kDebugMode) {
        print('No translator found for $sourceCode -> $targetCode');
      }
      return text;
    }

    try {
      final result = await translator.translateText(text);

      if (kDebugMode) {
        print('$sourceCode->$targetCode: $text -> $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error translating $sourceCode->$targetCode: $e');
      }
      return text;
    }
  }

  String _getLanguagePrefix(String languageCode) {
    if (languageCode.startsWith('zh'))
      return 'zh'; // Chinese (both simplified and traditional)
    if (languageCode.startsWith('ja')) return 'ja'; // Japanese
    if (languageCode.startsWith('en')) return 'en'; // English
    return languageCode.split('-')[0]; // Default to prefix
  }

  // Legacy methods for backward compatibility
  Future<String> translateEnglishToChinese(String text) async {
    return translate(text, 'en-US', 'zh-TW');
  }

  Future<String> translateChineseToEnglish(String text) async {
    return translate(text, 'zh-TW', 'en-US');
  }

  Future<String> translateChineseToJapanese(String text) async {
    return translate(text, 'zh-TW', 'ja-JP');
  }

  Future<String> translateJapaneseToChinese(String text) async {
    return translate(text, 'ja-JP', 'zh-TW');
  }

  Future<List<String>> getAvailableLanguages() async {
    // Return supported languages list since getDownloadedModels() is not available in this version
    return [
      TranslateLanguage.chinese.bcpCode,
      TranslateLanguage.japanese.bcpCode,
      TranslateLanguage.english.bcpCode,
    ];
  }

  Future<void> deleteModel(String languageCode) async {
    final modelManager = OnDeviceTranslatorModelManager();
    try {
      await modelManager.deleteModel(languageCode);

      if (kDebugMode) {
        print('Deleted model for language: $languageCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting model: $e');
      }
    }
  }

  void dispose() {
    _downloadProgressController?.close();
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
