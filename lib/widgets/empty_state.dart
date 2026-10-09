import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/models.dart';
import 'level_meter.dart';

/// Shown when there is no transcript yet.
///
/// The copy is contextual: while the model is loading it explains the wait,
/// and if the microphone is dead it tells the user what to check.
class EmptyState extends StatefulWidget {
  final CaptureStatus status;
  final String? errorMessage;
  final double level;
  final VoidCallback onStart;

  const EmptyState({
    super.key,
    required this.status,
    required this.onStart,
    this.errorMessage,
    this.level = 0,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final listening = s == CaptureStatus.listening;
    final busy = s.isBusy;
    final failed = s == CaptureStatus.error;

    final icon = switch (s) {
      CaptureStatus.listening => Icons.graphic_eq_rounded,
      CaptureStatus.error => Icons.mic_off_rounded,
      _ => Icons.headphones_rounded,
    };

    final title = switch (s) {
      CaptureStatus.listening => 'Listening',
      CaptureStatus.downloadingModel => 'Getting the speech model',
      CaptureStatus.loadingModel => 'Warming up',
      CaptureStatus.error => "Can't hear you",
      _ => 'Ready to listen',
    };

    final body = failed
        ? (widget.errorMessage ??
            'Check the microphone permission and try again.')
        : switch (s) {
            CaptureStatus.downloadingModel =>
              'Downloading the speech model once (~142 MB).\n'
                  'After this the app works fully offline.',
            CaptureStatus.loadingModel =>
              'Loading the model into memory.\nThis takes a few seconds the first time.',
            CaptureStatus.listening =>
              'Speak normally — words appear here as they are recognised.',
            _ => 'Put the call on speakerphone, then tap Start.\n'
                'Spoken words appear here in seconds.',
          };

    final accent = failed ? AppColors.hot : AppColors.them;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: .94, end: 1.04).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: .3),
                    width: 1.5,
                  ),
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      )
                    : Icon(icon, size: 34, color: accent),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.dim,
                height: 1.6,
              ),
            ),
            if (listening) ...[
              const SizedBox(height: 18),
              LevelMeter(level: widget.level, active: true, bars: 9),
            ],
            if (failed || s == CaptureStatus.idle || s == CaptureStatus.stopped) ...[
              const SizedBox(height: 20),
              _StartButton(onTap: widget.onStart, failed: failed),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool failed;

  const _StartButton({required this.onTap, required this.failed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.actionGradient,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.them.withValues(alpha: .3),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.refresh_rounded : Icons.mic_rounded,
              size: 17,
              color: Colors.white,
            ),
            const SizedBox(width: 7),
            Text(
              failed ? 'Try again' : 'Start listening',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
