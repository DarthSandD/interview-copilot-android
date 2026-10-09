import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The private notes / battle-card pane.
class NotesView extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const NotesView({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant NotesView old) {
    super.didUpdateWidget(old);
    // Only sync when the incoming value differs from what the user has typed,
    // so the caret never jumps while editing.
    if (widget.value != _controller.text && widget.value != old.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                fontFamily: 'monospace',
                color: AppColors.fg,
              ),
              decoration: InputDecoration(
                hintText: 'Your battle card lives here.\n\n'
                    '• Your STAR stories\n'
                    '• The numbers you want to hit\n'
                    '• Questions YOU will ask them\n\n'
                    "Glance — don't read.",
                hintStyle: const TextStyle(
                  color: AppColors.dim2,
                  fontSize: 12.5,
                  height: 1.7,
                ),
                filled: true,
                fillColor: AppColors.panel,
                contentPadding: const EdgeInsets.all(13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.panel),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.panel),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.panel),
                  borderSide:
                      BorderSide(color: AppColors.them.withValues(alpha: .45)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.dim2),
              SizedBox(width: 5),
              Text(
                'Private to this app · never uploaded',
                style: TextStyle(fontSize: 10.5, color: AppColors.dim2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
