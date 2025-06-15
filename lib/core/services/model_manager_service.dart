import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManagerService {
  static const String _modelDownloadedKey = 'models_downloaded';
  static const String _firstLaunchKey = 'first_launch';

  late OnDeviceTranslatorModelManager _modelManager;
  final StreamController<ModelDownloadProgress> _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  bool _isInitialized = false;
  bool _isDownloading = false;

  Stream<ModelDownloadProgress> get downloadProgress =>
      _progressController.stream;
  bool get isInitialized => _isInitialized;
  bool get isDownloading => _isDownloading;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _modelManager = OnDeviceTranslatorModelManager();
      _isInitialized = true;

      if (kDebugMode) {
        print('ModelManagerService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ModelManagerService initialization error: $e');
      }
      rethrow;
    }
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstLaunchKey) ?? false);
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  Future<bool> areModelsDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modelDownloadedKey) ?? false;
  }

  Future<void> setModelsDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modelDownloadedKey, true);
  }

  /// 預安裝所有需要的翻譯模型
  Future<void> preInstallModels({
    bool forceDownload = false,
    List<TranslateLanguage>? specificLanguages,
  }) async {
    if (!_isInitialized) {
      throw StateError('ModelManagerService not initialized');
    }

    if (_isDownloading) {
      if (kDebugMode) {
        print('Models are already being downloaded');
      }
      return;
    }

    _isDownloading = true;

    try {
      // 預設要下載的語言（根據用戶需求：英文和日文）
      final languagesToDownload = specificLanguages ??
          [
            TranslateLanguage.english,
            TranslateLanguage.japanese,
            TranslateLanguage.chinese, // 也加入中文以支援完整翻譯
          ];

      // 檢查是否已經下載過模型（除非強制下載）
      if (!forceDownload && await areModelsDownloaded()) {
        // 驗證模型是否真的存在
        bool allModelsExist = true;
        for (final language in languagesToDownload) {
          try {
            final isDownloaded =
                await _modelManager.isModelDownloaded(language.bcpCode);
            if (!isDownloaded) {
              allModelsExist = false;
              break;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error checking model for ${language.bcpCode}: $e');
            }
            allModelsExist = false;
            break;
          }
        }

        if (allModelsExist) {
          _progressController.add(ModelDownloadProgress(
            totalModels: languagesToDownload.length,
            downloadedModels: languagesToDownload.length,
            currentLanguage: '',
            isComplete: true,
          ));
          return;
        }
      }

      if (kDebugMode) {
        print('Starting model pre-installation...');
      }

      int downloadedCount = 0;
      final totalCount = languagesToDownload.length;

      // 初始進度
      _progressController.add(ModelDownloadProgress(
        totalModels: totalCount,
        downloadedModels: 0,
        currentLanguage: '',
        isComplete: false,
      ));

      for (final language in languagesToDownload) {
        try {
          final languageName = _getLanguageName(language);

          _progressController.add(ModelDownloadProgress(
            totalModels: totalCount,
            downloadedModels: downloadedCount,
            currentLanguage: languageName,
            isComplete: false,
          ));

          if (kDebugMode) {
            print('Checking model for $languageName (${language.bcpCode})...');
          }

          // 檢查模型是否已存在
          bool isModelDownloaded = false;
          try {
            isModelDownloaded =
                await _modelManager.isModelDownloaded(language.bcpCode);
          } catch (e) {
            if (kDebugMode) {
              print('Error checking model status: $e, assuming not downloaded');
            }
            isModelDownloaded = false;
          }

          if (!isModelDownloaded || forceDownload) {
            if (kDebugMode) {
              print('Downloading model for $languageName...');
            }

            // 使用超時來避免無限等待
            await Future.any([
              _modelManager.downloadModel(language.bcpCode),
              Future.delayed(const Duration(seconds: 60), () {
                throw TimeoutException(
                    'Model download timeout', const Duration(seconds: 60));
              }),
            ]);

            if (kDebugMode) {
              print('Successfully downloaded model for $languageName');
            }
          } else {
            if (kDebugMode) {
              print('Model for $languageName already exists');
            }
          }

          downloadedCount++;

          _progressController.add(ModelDownloadProgress(
            totalModels: totalCount,
            downloadedModels: downloadedCount,
            currentLanguage: languageName,
            isComplete: false,
          ));
        } catch (e) {
          if (kDebugMode) {
            print('Error downloading model for ${language.bcpCode}: $e');
          }
          // 繼續下載其他模型，不要因為一個失敗就停止
          downloadedCount++;
        }
      }

      // 完成
      await setModelsDownloaded();

      _progressController.add(ModelDownloadProgress(
        totalModels: totalCount,
        downloadedModels: downloadedCount,
        currentLanguage: '',
        isComplete: true,
      ));

      if (kDebugMode) {
        print('Model pre-installation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during model pre-installation: $e');
      }

      _progressController.add(ModelDownloadProgress(
        totalModels: 0,
        downloadedModels: 0,
        currentLanguage: '',
        isComplete: true,
        error: e.toString(),
      ));

      rethrow;
    } finally {
      _isDownloading = false;
    }
  }

  /// 刪除指定語言的模型
  Future<void> deleteModel(TranslateLanguage language) async {
    if (!_isInitialized) {
      throw StateError('ModelManagerService not initialized');
    }

    try {
      await _modelManager.deleteModel(language.bcpCode);
      if (kDebugMode) {
        print('Deleted model for ${_getLanguageName(language)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting model for ${language.bcpCode}: $e');
      }
      rethrow;
    }
  }

  /// 檢查指定語言的模型是否已下載
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    if (!_isInitialized) {
      throw StateError('ModelManagerService not initialized');
    }

    try {
      return await _modelManager.isModelDownloaded(language.bcpCode);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking model status for ${language.bcpCode}: $e');
      }
      return false;
    }
  }

  /// 獲取語言的顯示名稱
  String _getLanguageName(TranslateLanguage language) {
    switch (language) {
      case TranslateLanguage.chinese:
        return '中文';
      case TranslateLanguage.japanese:
        return '日文';
      case TranslateLanguage.english:
        return '英文';
      default:
        return language.bcpCode;
    }
  }

  void dispose() {
    _progressController.close();
  }
}

/// 模型下載進度資訊
class ModelDownloadProgress {
  final int totalModels;
  final int downloadedModels;
  final String currentLanguage;
  final bool isComplete;
  final String? error;

  const ModelDownloadProgress({
    required this.totalModels,
    required this.downloadedModels,
    required this.currentLanguage,
    required this.isComplete,
    this.error,
  });

  double get progress => totalModels > 0 ? downloadedModels / totalModels : 0.0;

  @override
  String toString() {
    return 'ModelDownloadProgress(progress: ${(progress * 100).toStringAsFixed(1)}%, '
        'current: $currentLanguage, complete: $isComplete, error: $error)';
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
