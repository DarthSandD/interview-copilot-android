import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A live audio-level bar visualiser.
///
/// Driven by the microphone loudness stream, so the user can see at a glance
/// that the app is really hearing the room — the single most useful signal
/// during an interview.
class LevelMeter extends StatefulWidget {
  /// Normalised 0..1 loudness.
  final double level;

  /// Whether the meter should be active.
  final bool active;

  /// Number of bars.
  final int bars;

  const LevelMeter({
    super.key,
    required this.level,
    required this.active,
    this.bars = 5,
  });

  @override
  State<LevelMeter> createState() => _LevelMeterState();
}

class _LevelMeterState extends State<LevelMeter> {
  /// Smoothed history so the bars move organically instead of snapping.
  final List<double> _history = [];

  @override
  void didUpdateWidget(covariant LevelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _history.add(widget.active ? widget.level : 0.0);
    if (_history.length > widget.bars) {
      _history.removeRange(0, _history.length - widget.bars);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = List<double>.generate(widget.bars, (i) {
      if (!widget.active) return 0.06;
      final idx = _history.length - widget.bars + i;
      final v = idx >= 0 && idx < _history.length ? _history[idx] : 0.0;
      // Ease so quiet speech still shows visible movement.
      return (0.08 + math.pow(v, 0.7) * 0.92).clamp(0.06, 1.0);
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < values.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : 2.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              width: 3,
              height: 6 + values[i] * 14,
              decoration: BoxDecoration(
                color: widget.active
                    ? AppColors.you.withValues(alpha: 0.35 + values[i] * 0.65)
                    : AppColors.dim2.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}
