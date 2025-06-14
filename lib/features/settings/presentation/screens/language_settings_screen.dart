import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/language_settings_provider.dart';
import '../../../../core/models/language_model.dart';
import '../widgets/language_selector_card.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageSettings = ref.watch(languageSettingsProvider);
    final availableLanguages = SupportedLanguages.getAvailableLanguages();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          '語言設定',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () {
              ref.read(languageSettingsProvider.notifier).swapLanguages();
            },
            tooltip: '交換語言',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 當前語言設定顯示
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '當前語言設定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // 母語顯示
                  _buildLanguageDisplay(
                    label: '我的母語',
                    language: languageSettings.nativeLanguage,
                    color: const Color(0xFF2196F3),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // 箭頭指示
                  Icon(
                    Icons.arrow_downward,
                    color: Colors.grey[600],
                    size: 24.sp,
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // 目標語言顯示
                  _buildLanguageDisplay(
                    label: '翻譯成',
                    language: languageSettings.targetLanguage,
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 語言選擇標題
            Text(
              '選擇語言',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            // 語言選擇按鈕組
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 母語選擇
                    LanguageSelectorCard(
                      title: '設定母語',
                      subtitle: '選擇您的母語',
                      currentLanguage: languageSettings.nativeLanguage,
                      availableLanguages: availableLanguages,
                      onLanguageSelected: (language) {
                        ref.read(languageSettingsProvider.notifier)
                            .setNativeLanguage(language);
                      },
                      color: const Color(0xFF2196F3),
                    ),

                    SizedBox(height: 16.h),

                    // 目標語言選擇
                    LanguageSelectorCard(
                      title: '設定翻譯語言',
                      subtitle: '選擇要翻譯成的語言',
                      currentLanguage: languageSettings.targetLanguage,
                      availableLanguages: availableLanguages,
                      onLanguageSelected: (language) {
                        ref.read(languageSettingsProvider.notifier)
                            .setTargetLanguage(language);
                      },
                      color: const Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDisplay({
    required String label,
    required LanguageModel language,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            language.flag,
            style: TextStyle(fontSize: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
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
                SizedBox(height: 2.h),
                Text(
                  language.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}