import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/translation_provider.dart';
import '../widgets/conversation_display.dart';
import '../widgets/control_buttons.dart';
import '../widgets/status_indicator.dart';
import '../widgets/debug_panel.dart';
import '../../../settings/presentation/screens/language_settings_screen.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';
import 'real_time_translation_screen.dart';

class TranslationScreen extends ConsumerWidget {
  const TranslationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider);
    final languageSettings = ref.watch(languageSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LinguaCore',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${languageSettings.nativeLanguage.flag} ${languageSettings.nativeLanguage.name} ↔ ${languageSettings.targetLanguage.flag} ${languageSettings.targetLanguage.name}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.live_tv, color: Colors.orange),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RealTimeTranslationScreen(),
                ),
              );
            },
            tooltip: '🚀 極速實時翻譯',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LanguageSettingsScreen(),
                ),
              );
            },
            tooltip: '語言設定',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              ref.read(translationProvider.notifier).clearHistory();
            },
            tooltip: '清除記錄',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: const DebugPanel(),
                ),
              );
            },
            tooltip: '調試資訊',
          ),
        ],
      ),
      body: Column(
        children: [
          // Download progress indicator
          if (translationState.downloadProgress < 1.0)
            Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Text(
                    '正在下載翻譯模型... ${(translationState.downloadProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    '初始化狀態: ${translationState.isInitialized ? "完成" : "進行中"}',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  LinearProgressIndicator(
                    value: translationState.downloadProgress,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),

          // Status indicator
          StatusIndicator(
            mode: translationState.mode,
            currentRole: translationState.currentRole,
            currentText: translationState.currentText,
            translatedText: translationState.translatedText,
            statusMessage: translationState.statusMessage,
            soundLevel: translationState.soundLevel,
          ),

          // Conversation display
          Expanded(
            child: ConversationDisplay(
              conversationHistory: translationState.conversationHistory,
            ),
          ),

          // Control buttons
          ControlButtons(
            isInitialized: translationState.isInitialized,
            currentMode: translationState.mode,
            currentRole: translationState.currentRole,
            onStartListeningForOther: () {
              ref.read(translationProvider.notifier).startListeningForOther();
            },
            onStartListeningForUser: () {
              ref.read(translationProvider.notifier).startListeningForUser();
            },
            onStopListening: () {
              ref.read(translationProvider.notifier).stopListening();
            },
            onStopSpeaking: () {
              ref.read(translationProvider.notifier).stopSpeaking();
            },
            onSwitchRole: () {
              ref.read(translationProvider.notifier).switchRole();
            },
          ),
        ],
      ),
    );
  }
}
