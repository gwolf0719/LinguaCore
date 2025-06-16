import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/translation_provider.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ControlButtons extends ConsumerWidget {
  final bool isInitialized;
  final TranslationMode currentMode;
  final ConversationRole currentRole;
  final VoidCallback onStartListeningForOther;
  final VoidCallback onStartListeningForUser;
  final VoidCallback onStopListening;
  final VoidCallback onStopSpeaking;
  final VoidCallback onSwitchRole;

  const ControlButtons({
    super.key,
    required this.isInitialized,
    required this.currentMode,
    required this.currentRole,
    required this.onStartListeningForOther,
    required this.onStartListeningForUser,
    required this.onStopListening,
    required this.onStopSpeaking,
    required this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageSettings = ref.watch(languageSettingsProvider);
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 說明文字
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '按住按鈕開始收音，放手後自動翻譯並播放中文',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // 主要控制按鈕 - 按住說話模式
            _buildPushToTalkButton(languageSettings),

            SizedBox(height: 16.h),

            // 停止播放按鈕（當TTS活躍時）
            if (currentMode == TranslationMode.speaking)
              SizedBox(
                width: double.infinity,
                child: _buildControlButton(
                  icon: Icons.stop,
                  label: '停止播放',
                  sublabel: '',
                  color: const Color(0xFFFF5722),
                  isActive: true,
                  onPressed: onStopSpeaking,
                ),
              ),

            // 緊急停止按鈕
            if (currentMode != TranslationMode.idle &&
                currentMode != TranslationMode.speaking)
              SizedBox(
                width: double.infinity,
                child: _buildControlButton(
                  icon: Icons.stop_circle_outlined,
                  label: '緊急停止',
                  sublabel: '',
                  color: const Color(0xFFFF5722),
                  isActive: false,
                  onPressed: onStopListening,
                ),
              ),

            SizedBox(height: 8.h),

            // 狀態文字
            Text(
              _getStatusText(),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPushToTalkButton(LanguageSettings languageSettings) {
    final isRecording = currentMode == TranslationMode.listening;
    final canStart = isInitialized && currentMode == TranslationMode.idle;

    return GestureDetector(
      onTapDown: (_) {
        // 按下時開始收音
        if (canStart) {
          print('按鈕按下 - 開始收音');
          onStartListeningForOther();
        } else {
          print(
              '無法開始收音 - isInitialized: $isInitialized, currentMode: $currentMode');
        }
      },
      onTapUp: (_) {
        // 放開時停止收音
        if (isRecording) {
          print('按鈕放開 - 停止收音');
          onStopListening();
        }
      },
      onTapCancel: () {
        // 取消時也停止收音
        if (isRecording) {
          print('按鈕取消 - 停止收音');
          onStopListening();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 200.w,
        height: 200.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getButtonColor(),
          boxShadow: isRecording
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
          border: Border.all(
            color: isRecording ? Colors.red : Colors.blue,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: Duration(milliseconds: 200),
              scale: isRecording ? 1.2 : 1.0,
              child: Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 60.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isRecording ? '正在收音...' : '按住開始',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '聽${languageSettings.targetLanguage.name}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
            Text(
              '↓ 翻譯成中文',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (currentMode) {
      case TranslationMode.listening:
        return Colors.red.withOpacity(0.8);
      case TranslationMode.translating:
        return Colors.orange.withOpacity(0.8);
      case TranslationMode.speaking:
        return Colors.green.withOpacity(0.8);
      default:
        return Colors.blue.withOpacity(0.6);
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.2)
                : (onPressed != null
                    ? color.withOpacity(0.1)
                    : Colors.grey[800]),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isActive
                  ? color
                  : (onPressed != null ? color.withOpacity(0.3) : Colors.grey),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: onPressed != null
                    ? (isActive ? color : color.withOpacity(0.8))
                    : Colors.grey,
                size: 32.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null ? Colors.white : Colors.grey,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (sublabel.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: onPressed != null ? Colors.white70 : Colors.grey,
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (!isInitialized) {
      return '正在初始化服務...';
    }

    switch (currentMode) {
      case TranslationMode.listening:
        return '🎤 正在收音中，放開按鈕開始翻譯';
      case TranslationMode.translating:
        return '🔄 正在翻譯中...';
      case TranslationMode.speaking:
        return '🔊 正在播放翻譯';
      case TranslationMode.idle:
      default:
        return '按住按鈕開始收音';
    }
  }
}
