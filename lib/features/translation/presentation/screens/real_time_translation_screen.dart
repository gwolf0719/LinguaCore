import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/real_time_translation_provider.dart';
import '../widgets/real_time_status_indicator.dart';
import '../widgets/real_time_control_buttons.dart';
import '../widgets/translation_history_panel.dart';
import '../../../settings/presentation/screens/language_settings_screen.dart';
import '../widgets/real_time_debug_panel.dart';

class RealTimeTranslationScreen extends ConsumerStatefulWidget {
  const RealTimeTranslationScreen({super.key});

  @override
  ConsumerState<RealTimeTranslationScreen> createState() =>
      _RealTimeTranslationScreenState();
}

class _RealTimeTranslationScreenState
    extends ConsumerState<RealTimeTranslationScreen> {
  bool _showDebugPanel = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final realTimeState = ref.watch(realTimeTranslationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: Text(
          'LinguaCore 實時翻譯',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LanguageSettingsScreen(),
                ),
              );
            },
            tooltip: '語言設定',
          ),
          if (realTimeState.speechSegments.isNotEmpty ||
              realTimeState.translationSegments.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all, color: Colors.white),
              onPressed: () {
                ref.read(realTimeTranslationProvider.notifier).clearHistory();
              },
              tooltip: '清除記錄',
            ),
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.orange),
            onPressed: () {
              setState(() {
                _showDebugPanel = !_showDebugPanel;
              });
            },
            tooltip: '調試面板',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 狀態指示器
                RealTimeStatusIndicator(
                  mode: realTimeState.mode,
                  currentSpeech: realTimeState.currentSpeech,
                  lastTranslation: realTimeState.lastTranslation,
                  soundLevel: realTimeState.soundLevel,
                  statusMessage: realTimeState.statusMessage,
                ),

                // 翻譯歷史面板
                Expanded(
                  child: TranslationHistoryPanel(
                    speechSegments: realTimeState.speechSegments,
                    translationSegments: realTimeState.translationSegments,
                    currentSpeech: realTimeState.currentSpeech,
                    lastTranslation: realTimeState.lastTranslation,
                  ),
                ),

                // 控制按鈕
                RealTimeControlButtons(
                  mode: realTimeState.mode,
                  isInitialized: realTimeState.isInitialized,
                  onStartTranslation: () {
                    ref
                        .read(realTimeTranslationProvider.notifier)
                        .startRealTimeTranslation();
                  },
                  onStopTranslation: () {
                    ref
                        .read(realTimeTranslationProvider.notifier)
                        .stopRealTimeTranslation();
                  },
                ),

                SizedBox(height: 20.h),
              ],
            ),

            // 調試面板
            if (_showDebugPanel)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  child: const RealTimeDebugPanel(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
