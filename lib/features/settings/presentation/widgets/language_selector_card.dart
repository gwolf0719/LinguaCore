import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/language_model.dart';

class LanguageSelectorCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final LanguageModel currentLanguage;
  final List<LanguageModel> availableLanguages;
  final Function(LanguageModel) onLanguageSelected;
  final Color color;

  const LanguageSelectorCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentLanguage,
    required this.availableLanguages,
    required this.onLanguageSelected,
    required this.color,
  });

  @override
  State<LanguageSelectorCard> createState() => _LanguageSelectorCardState();
}

class _LanguageSelectorCardState extends State<LanguageSelectorCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 標題和當前選擇
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // 語言圖標
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        widget.currentLanguage.flag,
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // 語言信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.currentLanguage.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 展開箭頭
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.color,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 語言選項列表
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[700]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200.h, // 限制高度，使其可滾動
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: widget.availableLanguages.length,
                      itemBuilder: (context, index) {
                        final language = widget.availableLanguages[index];
                        final isSelected = language.code == widget.currentLanguage.code;
                        
                        return InkWell(
                          onTap: () {
                            widget.onLanguageSelected(language);
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? widget.color.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  language.flag,
                                  style: TextStyle(fontSize: 20.sp),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        language.name,
                                        style: TextStyle(
                                          color: isSelected 
                                              ? widget.color
                                              : Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: isSelected 
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        language.localeName,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: widget.color,
                                    size: 20.sp,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}