import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Bottom bar: session counters on the left, the primary action on the right.
///
/// Both sides are wrapped so a long count or a large font scale can never
/// overflow — this is the row that clipped on a narrow phone in testing.
class CopilotFooter extends StatelessWidget {
  final int lineCount;
  final int wordCount;
  final bool listening;
  final bool busy;
  final VoidCallback onToggle;

  const CopilotFooter({
    super.key,
    required this.lineCount,
    required this.wordCount,
    required this.listening,
    required this.busy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  _Stat(value: '$lineCount', label: 'lines'),
                  const SizedBox(width: 14),
                  _Stat(value: '$wordCount', label: 'words'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: busy ? null : onToggle,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedContainer(
                duration: AppDurations.normal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: listening
                      ? AppColors.stopGradient
                      : AppColors.actionGradient,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: (listening ? AppColors.hot : AppColors.them)
                          .withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    else
                      Icon(
                        listening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 7),
                    Text(
                      busy
                          ? 'Working…'
                          : listening
                              ? 'Stop'
                              : 'Start listening',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.dim),
        ),
      ],
    );
  }
}
