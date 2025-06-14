import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  late OnDeviceTranslator _enToCnTranslator;
  late OnDeviceTranslator _cnToEnTranslator;
  
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
      _enToCnTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.chinese,
      );
      
      _cnToEnTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.chinese,
        targetLanguage: TranslateLanguage.english,
      );
      
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

  Future<void> _downloadModelsIfNeeded() async {
    final modelManager = OnDeviceTranslatorModelManager();
    
    try {
      // Check if English model is downloaded
      final isEnglishDownloaded = await modelManager.isModelDownloaded(
        TranslateLanguage.english.bcpCode,
      );
      
      // Check if Chinese model is downloaded
      final isChineseDownloaded = await modelManager.isModelDownloaded(
        TranslateLanguage.chinese.bcpCode,
      );
      
      if (!isEnglishDownloaded) {
        _downloadProgressController?.add(0.0);
        await modelManager.downloadModel(
          TranslateLanguage.english.bcpCode,
        );
        _downloadProgressController?.add(0.5);
        
        if (kDebugMode) {
          print('English translation model downloaded');
        }
      }
      
      if (!isChineseDownloaded) {
        _downloadProgressController?.add(0.5);
        await modelManager.downloadModel(
          TranslateLanguage.chinese.bcpCode,
        );
        _downloadProgressController?.add(1.0);
        
        if (kDebugMode) {
          print('Chinese translation model downloaded');
        }
      }
      
      _modelsDownloaded = true;
      _downloadProgressController?.add(1.0);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading translation models: $e');
      }
      throw e;
    }
  }

  Future<String> translateEnglishToChinese(String text) async {
    if (!_isInitialized || text.trim().isEmpty) {
      return text;
    }
    
    try {
      final result = await _enToCnTranslator.translateText(text);
      
      if (kDebugMode) {
        print('EN->CN: $text -> $result');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error translating EN->CN: $e');
      }
      return text;
    }
  }

  Future<String> translateChineseToEnglish(String text) async {
    if (!_isInitialized || text.trim().isEmpty) {
      return text;
    }
    
    try {
      final result = await _cnToEnTranslator.translateText(text);
      
      if (kDebugMode) {
        print('CN->EN: $text -> $result');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error translating CN->EN: $e');
      }
      return text;
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    final modelManager = OnDeviceTranslatorModelManager();
    try {
      final downloadedModels = await modelManager.getDownloadedModels();
      return downloadedModels.map((model) => model.language).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available languages: $e');
      }
      return [];
    }
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
    _enToCnTranslator.close();
    _cnToEnTranslator.close();
  }
}