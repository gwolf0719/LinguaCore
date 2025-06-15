import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/model_manager_service.dart';

class ModelDownloadDialog extends StatefulWidget {
  final Stream<ModelDownloadProgress> progressStream;
  final VoidCallback? onCompleted;
  final VoidCallback? onError;

  const ModelDownloadDialog({
    super.key,
    required this.progressStream,
    this.onCompleted,
    this.onError,
  });

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  ModelDownloadProgress? _currentProgress;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // 監聽進度更新
    widget.progressStream.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _currentProgress = progress;
          });

          if (progress.isComplete && !_isCompleted) {
            _isCompleted = true;
            if (progress.error != null) {
              widget.onError?.call();
            } else {
              // 延遲一秒後完成，讓用戶看到100%
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  widget.onCompleted?.call();
                }
              });
            }
          }
        }
      },
      onError: (e) {
        if (mounted) {
          widget.onError?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題
                  Text(
                    '初始化翻譯模型',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // 說明文字
                  Text(
                    '正在下載語言模型，首次使用需要一些時間',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24.h),

                  // 進度指示器
                  _buildProgressIndicator(),

                  SizedBox(height: 16.h),

                  // 當前下載語言
                  _buildCurrentLanguageText(),

                  SizedBox(height: 8.h),

                  // 進度文字
                  _buildProgressText(),

                  if (_currentProgress?.error != null) ...[
                    SizedBox(height: 16.h),
                    _buildErrorSection(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _currentProgress?.progress ?? 0.0;

    return Column(
      children: [
        // 圓形進度條
        SizedBox(
          width: 80.w,
          height: 80.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 背景圓圈
              SizedBox(
                width: 80.w,
                height: 80.h,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
              // 進度圓圈
              SizedBox(
                width: 80.w,
                height: 80.h,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted && _currentProgress?.error == null
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
              ),
              // 百分比文字
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // 線性進度條
        Container(
          width: double.infinity,
          height: 8.h,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: _isCompleted && _currentProgress?.error == null
                    ? Colors.green
                    : Colors.blue,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLanguageText() {
    final currentLanguage = _currentProgress?.currentLanguage ?? '';

    if (currentLanguage.isEmpty) {
      if (_isCompleted) {
        return Text(
          _currentProgress?.error != null ? '下載失敗' : '下載完成！',
          style: TextStyle(
            color: _currentProgress?.error != null ? Colors.red : Colors.green,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        );
      }
      return Text(
        '準備中...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Text(
      '正在下載：$currentLanguage',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildProgressText() {
    final current = _currentProgress?.downloadedModels ?? 0;
    final total = _currentProgress?.totalModels ?? 0;

    return Text(
      '$current / $total 模型',
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 12.sp,
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            '模型下載遇到問題，可能是網路連線不穩定',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            '應用程式將繼續運行，但某些功能可能受限',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
