import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  StreamController<bool>? _speakingController;
  
  Stream<bool> get speakingStatus => _speakingController!.stream;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _speakingController = StreamController<bool>.broadcast();
      
      // Configure TTS settings
      await _flutterTts.setLanguage("zh-CN"); // Default to Chinese
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set up event handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingController?.add(true);
        if (kDebugMode) {
          print('TTS Started');
        }
      });
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingController?.add(false);
        if (kDebugMode) {
          print('TTS Completed');
        }
      });
      
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _speakingController?.add(false);
        if (kDebugMode) {
          print('TTS Error: $msg');
        }
      });
      
      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _speakingController?.add(false);
        if (kDebugMode) {
          print('TTS Cancelled');
        }
      });
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('TTSService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTSService initialization error: $e');
      }
    }
  }

  Future<void> speakChinese(String text) async {
    if (!_isInitialized || text.trim().isEmpty) return;
    
    try {
      await _flutterTts.setLanguage("zh-CN");
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.speak(text);
      
      if (kDebugMode) {
        print('Speaking Chinese: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error speaking Chinese: $e');
      }
    }
  }

  Future<void> speakEnglish(String text) async {
    if (!_isInitialized || text.trim().isEmpty) return;
    
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.9);
      await _flutterTts.speak(text);
      
      if (kDebugMode) {
        print('Speaking English: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error speaking English: $e');
      }
    }
  }

  Future<void> stop() async {
    if (!_isSpeaking) return;
    
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingController?.add(false);
      
      if (kDebugMode) {
        print('TTS stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping TTS: $e');
      }
    }
  }

  Future<void> pause() async {
    if (!_isSpeaking) return;
    
    try {
      await _flutterTts.pause();
      
      if (kDebugMode) {
        print('TTS paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing TTS: $e');
      }
    }
  }

  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting languages: $e');
      }
      return [];
    }
  }

  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting voices: $e');
      }
      return [];
    }
  }

  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
      
      if (kDebugMode) {
        print('Voice set to: ${voice["name"]}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting voice: $e');
      }
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      
      if (kDebugMode) {
        print('Speech rate set to: $rate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting speech rate: $e');
      }
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
      
      if (kDebugMode) {
        print('Volume set to: $volume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting volume: $e');
      }
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
      
      if (kDebugMode) {
        print('Pitch set to: $pitch');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting pitch: $e');
      }
    }
  }

  void dispose() {
    _speakingController?.close();
    _flutterTts.stop();
  }
}