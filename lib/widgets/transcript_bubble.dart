import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/models.dart';

/// One transcript bubble.
///
/// [live] renders the in-flight partial in a muted style with a blinking
/// caret so it is visually distinct from committed lines.
class TranscriptBubble extends StatefulWidget {
  final Speaker speaker;
  final String text;

  /// True when this line is grouped with the previous one (same speaker).
  final bool grouped;

  /// True while this is the not-yet-final partial transcript.
  final bool live;

  final DateTime? at;

  const TranscriptBubble({
    super.key,
    required this.speaker,
    required this.text,
    this.grouped = false,
    this.live = false,
    this.at,
  });

  @override
  State<TranscriptBubble> createState() => _TranscriptBubbleState();
}

class _TranscriptBubbleState extends State<TranscriptBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) _caret.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TranscriptBubble old) {
    super.didUpdateWidget(old);
    if (widget.live && !_caret.isAnimating) {
      _caret.repeat(reverse: true);
    } else if (!widget.live && _caret.isAnimating) {
      _caret.stop();
      _caret.value = 0;
    }
  }

  @override
  void dispose() {
    _caret.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.speaker) {
        Speaker.you => AppColors.you,
        Speaker.them => AppColors.them,
        Speaker.system => AppColors.dim2,
      };

  @override
  Widget build(BuildContext context) {
    final isMeta = widget.speaker == Speaker.system;
    final showHeader = !widget.grouped;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.grouped ? 6 : 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader && !isMeta) ...[
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: .14),
                border: Border.all(color: _accent.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.speaker == Speaker.you
                    ? Icons.person_rounded
                    : Icons.support_agent_rounded,
                size: 14,
                color: _accent,
              ),
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              decoration: BoxDecoration(
                color: isMeta
                    ? Colors.white.withValues(alpha: .028)
                    : AppColors.panel,
                borderRadius: BorderRadius.circular(AppRadii.bubble),
                border: Border(
                  left: BorderSide(
                    color: _accent.withValues(alpha: widget.live ? .95 : .7),
                    width: 2.5,
                  ),
                  top: const BorderSide(color: AppColors.line),
                  right: const BorderSide(color: AppColors.line),
                  bottom: const BorderSide(color: AppColors.line),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            widget.speaker.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: _accent,
                            ),
                          ),
                          if (widget.live) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.them.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'live',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.them,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (widget.at != null && !widget.live)
                            Text(
                              _hhmm(widget.at!),
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.dim2,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: widget.live ? AppColors.live : AppColors.fg,
                            fontStyle: isMeta
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                      if (widget.live) ...[
                        const SizedBox(width: 3),
                        FadeTransition(
                          opacity: _caret,
                          child: Container(
                            width: 2,
                            height: 15,
                            margin: const EdgeInsets.only(bottom: 3),
                            color: AppColors.them,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
