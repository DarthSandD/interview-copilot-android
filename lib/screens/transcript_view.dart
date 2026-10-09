import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../domain/models.dart';
import '../widgets/empty_state.dart';
import '../widgets/transcript_bubble.dart';

/// The live transcript list, with an in-place partial and a jump-to-latest
/// pill that appears when the user scrolls up.
class TranscriptView extends StatefulWidget {
  final List<TranscriptLine> lines;
  final String partial;
  final CaptureStatus status;
  final String? errorMessage;
  final double level;
  final VoidCallback onStart;
  final VoidCallback onClear;

  const TranscriptView({
    super.key,
    required this.lines,
    required this.partial,
    required this.status,
    required this.onStart,
    required this.onClear,
    this.errorMessage,
    this.level = 0,
  });

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final ScrollController _scroll = ScrollController();
  bool _showJump = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant TranscriptView old) {
    super.didUpdateWidget(old);
    // A new committed line or a growing partial should keep the newest text
    // in view, but only when the user is already at the bottom.
    if (old.lines.length != widget.lines.length ||
        old.partial != widget.partial) {
      if (!_showJump) _scrollToEnd();
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final distanceFromBottom =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    final shouldShow = distanceFromBottom > 120;
    if (shouldShow != _showJump) {
      setState(() => _showJump = shouldShow);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppDurations.slow,
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyAll() async {
    final text = widget.lines
        .map((l) => '${l.speaker.label}: ${l.text}')
        .join('\n\n');
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcript copied'),
        backgroundColor: AppColors.panelAlt,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showEmpty = widget.lines.isEmpty && widget.partial.isEmpty;

    return Stack(
      children: [
        if (showEmpty)
          EmptyState(
            status: widget.status,
            errorMessage: widget.errorMessage,
            level: widget.level,
            onStart: widget.onStart,
          )
        else
          ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 18),
            children: [
              for (var i = 0; i < widget.lines.length; i++)
                TranscriptBubble(
                  speaker: widget.lines[i].speaker,
                  text: widget.lines[i].text,
                  at: widget.lines[i].at,
                  grouped: i > 0 &&
                      widget.lines[i].speaker == widget.lines[i - 1].speaker,
                ),
              if (widget.partial.isNotEmpty)
                TranscriptBubble(
                  speaker: Speaker.them,
                  text: widget.partial,
                  grouped: widget.lines.isNotEmpty &&
                      widget.lines.last.speaker == Speaker.them,
                  live: true,
                ),
            ],
          ),

        // Copy / clear actions once there is something to act on.
        if (!showEmpty)
          Positioned(
            top: 8,
            right: 13,
            child: Row(
              children: [
                _IconAction(
                  icon: Icons.copy_rounded,
                  tooltip: 'Copy transcript',
                  onTap: _copyAll,
                ),
                const SizedBox(width: 6),
                _IconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Clear transcript',
                  onTap: widget.onClear,
                ),
              ],
            ),
          ),

        // Jump-to-latest pill.
        AnimatedPositioned(
          duration: AppDurations.slow,
          curve: Curves.easeOut,
          right: 16,
          bottom: _showJump ? 16 : -60,
          child: _JumpPill(onTap: _scrollToEnd),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.panel.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: AppColors.dim),
          ),
        ),
      ),
    );
  }
}

class _JumpPill extends StatelessWidget {
  final VoidCallback onTap;

  const _JumpPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.panelAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward_rounded, size: 13, color: AppColors.them),
            SizedBox(width: 5),
            Text(
              'Latest',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.them,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
