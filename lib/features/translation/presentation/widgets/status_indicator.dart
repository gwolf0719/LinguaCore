import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation_provider.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';

class StatusIndicator extends ConsumerWidget {
  final TranslationMode mode;
  final ConversationRole currentRole;
  final String currentText;
  final String translatedText;

  const StatusIndicator({
    super.key,
    required this.mode,
    required this.currentRole,
    required this.currentText,
    required this.translatedText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageSettings = ref.watch(languageSettingsProvider);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Status icon and text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(),
              SizedBox(width: 12.w),
              Text(
                _getStatusText(languageSettings),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Current role indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: currentRole == ConversationRole.user
                  ? const Color(0xFF2196F3)
                  : const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              currentRole == ConversationRole.user 
                  ? '我的語言: ${languageSettings.nativeLanguage.name}'
                  : '對方語言: ${languageSettings.targetLanguage.name}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Current text display
          if (currentText.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildTextDisplay('原文', currentText, Colors.blue),
          ],

          // Translated text display
          if (translatedText.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildTextDisplay('翻譯', translatedText, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (mode) {
      case TranslationMode.listening:
        return Icon(
          Icons.mic,
          color: Colors.red,
          size: 24.sp,
        );
      case TranslationMode.translating:
        return SizedBox(
          width: 24.w,
          height: 24.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case TranslationMode.speaking:
        return Icon(
          Icons.volume_up,
          color: Colors.green,
          size: 24.sp,
        );
      case TranslationMode.idle:
      default:
        return Icon(
          Icons.pause_circle_outline,
          color: Colors.grey,
          size: 24.sp,
        );
    }
  }

  String _getStatusText(LanguageSettings languageSettings) {
    switch (mode) {
      case TranslationMode.listening:
        return currentRole == ConversationRole.user 
            ? '正在聽取${languageSettings.nativeLanguage.name}...' 
            : '正在聽取${languageSettings.targetLanguage.name}...';
      case TranslationMode.translating:
        return '正在翻譯...';
      case TranslationMode.speaking:
        return '正在播放翻譯...';
      case TranslationMode.idle:
      default:
        return '待機中';
    }
  }

  Color _getBorderColor() {
    switch (mode) {
      case TranslationMode.listening:
        return Colors.red;
      case TranslationMode.translating:
        return Colors.orange;
      case TranslationMode.speaking:
        return Colors.green;
      case TranslationMode.idle:
      default:
        return Colors.grey;
    }
  }

  Widget _buildTextDisplay(String label, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}