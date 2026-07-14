import 'dart:developer';
import 'package:duoob_desktop_app_v1/main.dart';
import 'package:duoob_desktop_app_v1/services/download_services.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/new_vindow_screen.dart';
import 'package:duoob_desktop_app_v1/view/components/interactive_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';

// Enum to manage which overlay to show
enum TaskResult { none, success, failure }

class TaskWebViewWindows extends StatefulWidget {
  final String? url;
  final bool refreshUrlOnSuccess;
  final bool blockUiWhileLoading;
  final String loadingTitle;
  final List<String> loadingTips;
  final VoidCallback? onSubmissionSuccess;

  const TaskWebViewWindows({
    super.key,
    this.url,
    this.refreshUrlOnSuccess = false,
    this.blockUiWhileLoading = true,
    this.loadingTitle = 'Getting things ready',
    this.loadingTips = const [
      'Fetching the latest updates for you…',
      'Almost there — polishing the view…',
      'Hang tight, this won’t take long…',
      'Loading your workspace…',
    ],
    this.onSubmissionSuccess,
  });

  @override
  State<TaskWebViewWindows> createState() => _TaskWebViewWindowsState();
}

class _TaskWebViewWindowsState extends State<TaskWebViewWindows> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasCompletedInitialLoad = false;
  bool _showSuccessAnimation = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String? _activeUrl;

  // Track the current result state
  TaskResult _currentResult = TaskResult.none;

  // URL Constants
  final String successUrl = 'D365Close.aspx?Action=Success';
  final String successUrl1 = 'Resultpage.aspx';
  final String failureUrl = 'D365Close.aspx?Action=Failure';

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.url;
  }

  @override
  void didUpdateWidget(TaskWebViewWindows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url == oldWidget.url) return;

    _currentResult = TaskResult.none;
    final newUrl = widget.url;

    if (newUrl == null) {
      _safeSetState(() => _activeUrl = null);
      return;
    }

    _safeSetState(() {
      _activeUrl = newUrl;
      _isLoading = true;
      _canGoBack = false;
      _canGoForward = false;
    });

    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(newUrl)));
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _updateNavigationState() async {
    final controller = _webViewController;
    if (controller == null) return;
    final canBack = await controller.canGoBack();
    final canForward = await controller.canGoForward();
    _safeSetState(() {
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  Future<void> _goBack() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
      await _updateNavigationState();
    }
  }

  Future<void> _goForward() async {
    if (_webViewController != null &&
        await _webViewController!.canGoForward()) {
      await _webViewController!.goForward();
      await _updateNavigationState();
    }
  }

  Future<void> _reloadPage() async {
    if (_webViewController == null) return;
    _safeSetState(() => _isLoading = true);
    await _webViewController!.reload();
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _canGoBack ? _goBack : null,
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              tooltip: 'Forward',
              onPressed: _canGoForward ? _goForward : null,
              icon: const Icon(Icons.arrow_forward),
            ),
            IconButton(
              tooltip: 'Reload',
              onPressed: _isLoading ? null : _reloadPage,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _activeUrl ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Central logic to handle animations and clearing the view
  void _triggerOverlay(bool isSuccess) async {
    _safeSetState(() {
      _currentResult = isSuccess ? TaskResult.success : TaskResult.failure;
    });

    await Future.delayed(const Duration(milliseconds: 2500));

    if (isSuccess && widget.refreshUrlOnSuccess && widget.url != null) {
      final reloadUrl = widget.url!;
      _safeSetState(() {
        _currentResult = TaskResult.none;
        _activeUrl = reloadUrl;
        _isLoading = true;
        _canGoBack = false;
        _canGoForward = false;
      });
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(reloadUrl)),
      );
      return;
    }

    _safeSetState(() {
      _currentResult = TaskResult.none;
      _activeUrl = null;
    });

    if (isSuccess) {
      widget.onSubmissionSuccess?.call();
    }
  }

  void _handleTaskCompletion() async {
    // 1. Show the success overlay
    _safeSetState(() {
      _showSuccessAnimation = true;
    });

    // 2. Wait for the animation to finish (adjust duration as needed)
    // Most success animations are 2-3 seconds long
    await Future.delayed(const Duration(milliseconds: 2500));

    // 3. Clear state to show _buildEmptyState()
    _safeSetState(() {
      _showSuccessAnimation = false;
      _activeUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeUrl == null) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavigationBar(context),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: InAppWebView(
                  webViewEnvironment: webViewEnvironment,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useOnDownloadStart: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    allowsBackForwardNavigationGestures: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                  ),
                  initialUrlRequest: URLRequest(url: WebUri(_activeUrl!)),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    controller.addJavaScriptHandler(
                      handlerName: "notifyClose",
                      callback: (args) => _triggerOverlay(true),
                    );
                    _updateNavigationState();
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) {
                    _updateNavigationState();
                  },
                  onLoadStart: (controller, url) {
                    _safeSetState(() => _isLoading = true);
                    if (url != null) {
                      _safeSetState(() => _activeUrl = url.toString());
                    }
                  },
                  onLoadStop: (controller, url) async {
                    log(url.toString(), name: 'onLoadStop');
                    _safeSetState(() {
                      _isLoading = false;
                      _hasCompletedInitialLoad = true;
                    });
                    await _updateNavigationState();

                    final currentUrl = url.toString();

                    // URL-based trigger logic
                    if (currentUrl.contains(successUrl) ||
                        currentUrl.contains(successUrl1)) {
                      _triggerOverlay(true);
                    } else if (currentUrl.contains(failureUrl)) {
                      _triggerOverlay(false);
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      _safeSetState(() {
                        _isLoading = false;
                        _hasCompletedInitialLoad = true;
                      });
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.url.toString() == "about:blank") return;
                    log("WebView Error: ${error.description}");
                  },

                  // onCreateWindow: (controller, createWindowRequest) async {
                  //   await Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => NewTaskViewScreen(
                  //         createWindowRequest: createWindowRequest,
                  //       ),
                  //     ),
                  //   );
                  //   // await controller.reload();
                  //   // This is crucial: Returning `true` signals that your app
                  //   // has handled the request and the WebView shouldn't open a new native window.
                  //   return true;
                  // },
                  onDownloadStart: (controller, url) async {
                    // final FileDownloadService _downloader =
                    //     FileDownloadService();
                    String? filePath = await downloadWithWebViewCookies(
                      url: url.toString(),
                      fileName: 'document',
                      cookieUrl: url,
                    );

                    if (filePath != null) {
                      openDownloadedFile(filePath);
                    }
                  },
                ),
              ),

              // Loading: block only for first load (or when requested).
              // After that, keep the page visible with a thin progress bar.
              if (_isLoading &&
                  (widget.blockUiWhileLoading || !_hasCompletedInitialLoad))
                Positioned.fill(
                  child: InteractiveLoadingView(
                    title: widget.loadingTitle,
                    tips: widget.loadingTips,
                  ),
                )
              else if (_isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _SoftLoadingBar(),
                ),

              // Success Overlay
              if (_currentResult == TaskResult.success)
                _buildOverlay(
                  color: Colors.white,
                  asset: 'assets/animations/success.json',
                ),

              // Failure Overlay
              if (_currentResult == TaskResult.failure)
                _buildOverlay(
                  color: Colors.white,
                  asset:
                      'assets/animations/error.json', // Your error animation path
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Reusable overlay builder
  Widget _buildOverlay({required Color color, required String asset}) {
    return Positioned.fill(
      child: Container(
        color: color,
        child: Center(child: Lottie.asset(asset, width: 180, repeat: false)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a task to view details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin indeterminate bar without Material CircularProgressIndicator.
class _SoftLoadingBar extends StatefulWidget {
  const _SoftLoadingBar();

  @override
  State<_SoftLoadingBar> createState() => _SoftLoadingBarState();
}

class _SoftLoadingBarState extends State<_SoftLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final barColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 3,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return CustomPaint(
            painter: _SoftBarPainter(
              progress: t,
              trackColor: trackColor,
              barColor: barColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SoftBarPainter extends CustomPainter {
  _SoftBarPainter({
    required this.progress,
    required this.trackColor,
    required this.barColor,
  });

  final double progress;
  final Color trackColor;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, track);

    final barWidth = size.width * 0.35;
    final start = (size.width + barWidth) * progress - barWidth;
    final rect = Rect.fromLTWH(start, 0, barWidth, size.height);
    final bar = Paint()
      ..shader = LinearGradient(
        colors: [
          barColor.withValues(alpha: 0.15),
          barColor,
          barColor.withValues(alpha: 0.15),
        ],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant _SoftBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.barColor != barColor;
  }
}
