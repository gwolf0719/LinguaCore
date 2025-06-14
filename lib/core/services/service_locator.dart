import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'translation_service.dart';
import 'audio_service.dart';
import 'tts_service.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // Logger
    sl.registerLazySingleton<Logger>(() => Logger());
    
    // Services
    sl.registerLazySingleton<TranslationService>(() => TranslationService());
    sl.registerLazySingleton<AudioService>(() => AudioService());
    sl.registerLazySingleton<TTSService>(() => TTSService());
    
    // Initialize services
    await sl<TranslationService>().initialize();
    await sl<AudioService>().initialize();
    await sl<TTSService>().initialize();
  }
}