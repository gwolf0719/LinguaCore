import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/model_manager_service.dart';
import '../widgets/model_download_dialog.dart';
import 'translation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isCheckingModels = false;
  bool _showDownloadDialog = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // 延遲後開始檢查模型
    Future.delayed(const Duration(milliseconds: 1500), () {
      _checkAndDownloadModels();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndDownloadModels() async {
    if (!mounted) return;

    setState(() {
      _isCheckingModels = true;
    });

    try {
      final modelManager = sl<ModelManagerService>();

      // 檢查是否需要下載模型
      final areModelsDownloaded = await modelManager.areModelsDownloaded();

      if (!areModelsDownloaded) {
        // 需要下載模型，顯示下載對話框
        if (mounted) {
          setState(() {
            _showDownloadDialog = true;
          });

          _showModelDownloadDialog();
        }
      } else {
        // 檢查模型是否真的存在
        final englishExists =
            await modelManager.isModelDownloaded(TranslateLanguage.english);
        final japaneseExists =
            await modelManager.isModelDownloaded(TranslateLanguage.japanese);

        if (!englishExists || !japaneseExists) {
          // 模型不完整，需要重新下載
          if (mounted) {
            setState(() {
              _showDownloadDialog = true;
            });

            _showModelDownloadDialog();
          }
        } else {
          // 模型已存在，直接進入主畫面
          _navigateToMain();
        }
      }
    } catch (e) {
      debugPrint('Error checking models: $e');
      // 出錯時也進入主畫面，但可能功能受限
      _navigateToMain();
    }
  }

  void _showModelDownloadDialog() {
    final modelManager = sl<ModelManagerService>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModelDownloadDialog(
        progressStream: modelManager.downloadProgress,
        onCompleted: () {
          if (mounted) {
            Navigator.of(context).pop();
            _navigateToMain();
          }
        },
        onError: () {
          if (mounted) {
            Navigator.of(context).pop();
            _navigateToMain();
          }
        },
      ),
    );

    // 開始下載模型
    modelManager.preInstallModels();
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TranslationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF2D2D2D),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo區域
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      children: [
                        // App Icon
                        Container(
                          width: 120.w,
                          height: 120.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.translate,
                            color: Colors.white,
                            size: 60.sp,
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // App Name
                        Text(
                          'LinguaCore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Subtitle
                        Text(
                          '實時語音翻譯',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 80.h),

                // 載入指示器
                if (_isCheckingModels && !_showDownloadDialog)
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40.w,
                          height: 40.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '正在檢查語言模型...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
