import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';

class ModernLoadingIndicator extends StatefulWidget {
  const ModernLoadingIndicator({
    super.key,
    this.color,
    this.dotSize = 7,
    this.spacing = 5,
    this.label,
    this.labelStyle,
    this.compact = false,
  });

  final Color? color;
  final double dotSize;
  final double spacing;
  final String? label;
  final TextStyle? labelStyle;
  final bool compact;

  @override
  State<ModernLoadingIndicator> createState() => _ModernLoadingIndicatorState();
}

class _ModernLoadingIndicatorState extends State<ModernLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.blue;
    final dotSize = widget.compact ? widget.dotSize * 0.75 : widget.dotSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 2 ? widget.spacing : 0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final phase = (_controller.value + (index * 0.18)) % 1.0;
                final bounce = Curves.easeInOut.transform(
                  phase < 0.5 ? phase * 2 : (1 - phase) * 2,
                );

                return Transform.translate(
                  offset: Offset(0, -bounce * (widget.compact ? 3 : 5)),
                  child: Opacity(
                    opacity: 0.35 + (bounce * 0.65),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
        if (widget.label != null) ...[
          SizedBox(width: widget.compact ? 8 : 10),
          Text(
            widget.label!,
            style: widget.labelStyle ??
                TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: widget.compact ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}
