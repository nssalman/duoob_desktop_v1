import 'dart:async';

import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/view/components/modern_loading_indicator.dart';
import 'package:flutter/material.dart';

class InteractiveLoadingView extends StatefulWidget {
  const InteractiveLoadingView({
    super.key,
    this.title = 'Getting things ready',
    this.tips = const [
      'Fetching the latest updates for you…',
      'Almost there — polishing the view…',
      'Hang tight, this won’t take long…',
      'Loading your workspace…',
    ],
  });

  final String title;
  final List<String> tips;

  @override
  State<InteractiveLoadingView> createState() => _InteractiveLoadingViewState();
}

class _InteractiveLoadingViewState extends State<InteractiveLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _tipController;
  late final Animation<double> _pulse;
  late final Animation<double> _tipFade;
  Timer? _tipTimer;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _tipFade = CurvedAnimation(parent: _tipController, curve: Curves.easeInOut);
    _tipController.value = 1;

    if (widget.tips.length > 1) {
      _tipTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _rotateTip();
      });
    }
  }

  Future<void> _rotateTip() async {
    if (!mounted || widget.tips.isEmpty) return;
    await _tipController.reverse();
    if (!mounted) return;
    setState(() {
      _tipIndex = (_tipIndex + 1) % widget.tips.length;
    });
    await _tipController.forward();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _pulseController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tips.isEmpty
        ? 'Please wait…'
        : widget.tips[_tipIndex % widget.tips.length];

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/images/app_logo_no_back.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.hourglass_top_rounded,
                        size: 40,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: FadeTransition(
                    opacity: _tipFade,
                    child: Text(
                      tip,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.iconGrey,
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const ModernLoadingIndicator(compact: true),
                const SizedBox(height: 18),
                const _TipProgressTrack(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipProgressTrack extends StatefulWidget {
  const _TipProgressTrack();

  @override
  State<_TipProgressTrack> createState() => _TipProgressTrackState();
}

class _TipProgressTrackState extends State<_TipProgressTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 4,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final barWidth = 64.0;
          final travel = 160.0 - barWidth;
          final left = travel * _controller.value;

          return ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.blue.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: barWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue.withValues(alpha: 0.05),
                          AppColors.blue.withValues(alpha: 0.8),
                          AppColors.blue.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
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
