import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  StreamController<String>? _speechResultController;
  StreamController<bool>? _listeningController;
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  Stream<String> get speechResults => _speechResultController!.stream;
  Stream<bool> get listeningStatus => _listeningController!.stream;
  
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _speechResultController = StreamController<String>.broadcast();
      _listeningController = StreamController<bool>.broadcast();
      
      // Request permissions
      await _requestPermissions();
      
      // Configure audio session
      await _configureAudioSession();
      
      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
      
      if (kDebugMode) {
        print('AudioService initialized: $_isInitialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService initialization error: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    final micPermission = await Permission.microphone.request();
    if (micPermission != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> startListening({
    String localeId = 'en-US',
    bool partialResults = true,
  }) async {
    if (!_isInitialized || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        partialResults: partialResults,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      
      _isListening = true;
      _listeningController?.add(true);
      
      if (kDebugMode) {
        print('Started listening...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _listeningController?.add(false);
      
      if (kDebugMode) {
        print('Stopped listening');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping speech recognition: $e');
      }
    }
  }

  void _onSpeechResult(result) {
    if (result.recognizedWords.isNotEmpty) {
      _speechResultController?.add(result.recognizedWords);
      
      if (kDebugMode) {
        print('Speech result: ${result.recognizedWords}');
      }
    }
  }

  void _onSpeechError(error) {
    if (kDebugMode) {
      print('Speech error: $error');
    }
    _isListening = false;
    _listeningController?.add(false);
  }

  void _onSpeechStatus(status) {
    if (kDebugMode) {
      print('Speech status: $status');
    }
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _listeningController?.add(false);
    }
  }

  List<String> get availableLocales {
    return _speechToText.locales
        .map((locale) => locale.localeId)
        .toList();
  }

  void dispose() {
    _speechResultController?.close();
    _listeningController?.close();
    _speechToText.cancel();
  }
}