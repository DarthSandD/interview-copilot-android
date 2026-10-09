import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/models.dart';
import 'level_meter.dart';

/// App header: brand badge, title, live level meter and status pill.
class CopilotHeader extends StatelessWidget {
  final CaptureStatus status;
  final double level;

  const CopilotHeader({
    super.key,
    required this.status,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadii.badge),
            ),
            child: const Icon(Icons.mic_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Interview Copilot',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.fg,
                letterSpacing: .2,
              ),
            ),
          ),
          LevelMeter(
            level: level,
            active: status == CaptureStatus.listening,
          ),
          const SizedBox(width: 10),
          _StatusPill(status: status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CaptureStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final live = status == CaptureStatus.listening;
    final busy = status.isBusy;
    final error = status == CaptureStatus.error;

    final color = live
        ? AppColors.you
        : error
            ? AppColors.hot
            : busy
                ? AppColors.them
                : AppColors.dim;

    return AnimatedContainer(
      duration: AppDurations.normal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: live ? AppColors.you.withValues(alpha: .12) : AppColors.panel,
        border: Border.all(
          color: live ? AppColors.you.withValues(alpha: .35) : AppColors.line,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else
            _PulsingDot(color: color, pulse: live),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool pulse;

  const _PulsingDot({required this.color, required this.pulse});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulse) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: 1.0).animate(_c),
      child: dot,
    );
  }
}
