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
            // Main control buttons
            Row(
              children: [
                // Listen to other person
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.person_outline,
                    label: '聽對方說話',
                    sublabel: '(${languageSettings.targetLanguage.name} → ${languageSettings.nativeLanguage.name})',
                    color: const Color(0xFF4CAF50),
                    isActive: currentMode == TranslationMode.listening && 
                             currentRole == ConversationRole.other,
                    onPressed: isInitialized && 
                              currentMode != TranslationMode.speaking
                        ? (currentMode == TranslationMode.listening && 
                           currentRole == ConversationRole.other
                           ? onStopListening
                           : onStartListeningForOther)
                        : null,
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Listen to user
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.person,
                    label: '我要說話',
                    sublabel: '(${languageSettings.nativeLanguage.name} → ${languageSettings.targetLanguage.name})',
                    color: const Color(0xFF2196F3),
                    isActive: currentMode == TranslationMode.listening && 
                             currentRole == ConversationRole.user,
                    onPressed: isInitialized && 
                              currentMode != TranslationMode.speaking
                        ? (currentMode == TranslationMode.listening && 
                           currentRole == ConversationRole.user
                           ? onStopListening
                           : onStartListeningForUser)
                        : null,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Stop speaking button (when TTS is active)
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

            // Emergency stop button
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

            // Status text
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
                : (onPressed != null ? color.withOpacity(0.1) : Colors.grey[800]),
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
                    color: onPressed != null 
                        ? Colors.white70 
                        : Colors.grey,
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
        return '正在聆聽中... 點擊相同按鈕停止';
      case TranslationMode.translating:
        return '正在翻譯中，請稍候...';
      case TranslationMode.speaking:
        return '正在播放翻譯，點擊停止播放可中斷';
      case TranslationMode.idle:
      default:
        return '選擇聆聽模式開始對話翻譯';
    }
  }
}