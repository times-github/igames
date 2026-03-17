import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:igames/app/routes/app_pages.dart';
import '../controllers/game_start_controller.dart';

class GameStartView extends GetView<GameStartController> {
  const GameStartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: Obx(() {
        Widget content;
        if (controller.isLoading.value && controller.gameUrl.isEmpty) {
          content = _buildLoadingView();
        } else if (controller.errorMessage.isNotEmpty) {
          content = _buildErrorView();
        } else if (controller.gameUrl.isNotEmpty) {
          content = _buildGameView();
        } else {
          content = _buildEmptyView();
        }

        return Stack(
          children: [
            Positioned.fill(child: content),
            if (controller.gameUrl.isNotEmpty)
              _FloatingMenuButton(onTap: _openMenu),
          ],
        );
      }),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.games,
                size: 60,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'loadingGame'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.error_outline, size: 40, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.reloadGame,
            child: Text('reloadGame'.tr),
          ),
        ],
      ),
    );
  }

  /// 构建游戏视图
  Widget _buildGameView() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(controller.gameUrl.value)),
          onWebViewCreated: (InAppWebViewController webViewController) {
            controller.webViewController = webViewController;
          },
          onLoadStart: controller.onLoadStart,
          onLoadStop: controller.onLoadStop,
          onProgressChanged: controller.onProgressChanged, // 加载进度
          onReceivedError: (webViewController, request, error) {
            controller.errorMessage.value = '加载失败: ${error.description}';
            controller.isLoading.value = false;
          },
          shouldOverrideUrlLoading: (c, action) async {
            //
            return NavigationActionPolicy.ALLOW;
          },
        ),
        Obx(() {
          if (controller.loadingProgress.value > 0 && // 加载进度
              controller.loadingProgress.value < 1) {
            // 加载进度小于1
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: controller.loadingProgress.value,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Text(
        'noGame'.tr,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  void _openMenu() {
    Get.dialog(
      PointerInterceptor(
        child: Stack(
          children: [
            // 点击背景关闭
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
            // 弹窗内容
            Center(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'pleaseSelect'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _MenuAction(
                                icon: Icons.refresh,
                                label: 'refresh'.tr,
                                onTap: () {
                                  Get.back();
                                  controller.reloadGame();
                                },
                              ),
                              _MenuAction(
                                icon: Icons.account_balance_wallet,
                                label: 'deposit'.tr,
                                onTap: () {
                                  Get.back();
                                  Get.offAllNamed(
                                    AppPages.INITIAL,
                                    arguments: {'initialTab': 2},
                                  );
                                },
                              ),
                              _MenuAction(
                                icon: Icons.credit_card,
                                label: 'withdraw'.tr,
                                onTap: () {
                                  Get.back();
                                  Get.offAllNamed(
                                    AppPages.INITIAL,
                                    arguments: {'initialTab': 2},
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                                controller.goBack();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'exitGame'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 关闭按钮
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                        child: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.transparent,
    );
  }
}

class _FloatingMenuButton extends StatefulWidget {
  const _FloatingMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FloatingMenuButton> createState() => _FloatingMenuButtonState();
}

class _FloatingMenuButtonState extends State<_FloatingMenuButton> {
  double _x = 16;
  double _y = 16;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: _x,
      top: _y,
      child: PointerInterceptor(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onPanUpdate: (details) {
            setState(() {
              _x = (_x + details.delta.dx).clamp(0, screenSize.width - 48);
              _y = (_y + details.delta.dy).clamp(0, screenSize.height - 48);
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(90, 0, 0, 0),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.home, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
