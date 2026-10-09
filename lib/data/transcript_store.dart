import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import '../domain/models.dart';

/// Persistent store for the interview transcript.
///
/// Design decisions that matter for correctness and safety:
///  * **Bounded** — only the most recent [maxLines] lines are kept, so a long
///    interview cannot exhaust memory or the prefs file.
///  * **Debounced** — writes coalesce, so a fast transcript does not hammer
///    disk on every partial.
///  * **Non-fatal** — a persistence failure degrades to in-memory only; it
///    never takes the capture session down mid-interview.
class TranscriptStore {
  static const _key = 'ic_transcript_v1';
  static const _maxLines = 2000;
  static const _maxChars = 400 * 1024;

  final List<TranscriptLine> _lines = [];
  bool _dirty = false;
  bool _writing = false;

  List<TranscriptLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get length => _lines.length;

  /// Loads persisted history, dropping anything malformed rather than
  /// throwing — a corrupt prefs blob must not brick the app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _lines
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((m) => TranscriptLine.tryFromJson(m.cast<String, Object?>()))
              .whereType<TranscriptLine>(),
        );
      _trim();
      Log.i('transcript.loaded', {'lines': _lines.length});
    } catch (e, s) {
      Log.e('transcript.load_failed', e, s);
      _lines.clear();
    }
  }

  void add(TranscriptLine line) {
    final text = line.text.trim();
    if (text.isEmpty) return;
    _lines.add(line);
    _trim();
    _dirty = true;
    _scheduleSave();
  }

  void clear() {
    _lines.clear();
    _dirty = true;
    _scheduleSave();
  }

  /// Keeps the newest lines within both the line and character budgets.
  void _trim() {
    if (_lines.length > _maxLines) {
      _lines.removeRange(0, _lines.length - _maxLines);
    }
    var chars = _lines.fold<int>(0, (a, l) => a + l.text.length);
    while (chars > _maxChars && _lines.isNotEmpty) {
      chars -= _lines.first.text.length;
      _lines.removeAt(0);
    }
  }

  void _scheduleSave() {
    if (_writing) return;
    _writing = true;
    // Coalesce bursts: one write per event-loop turn is plenty.
    Future.microtask(_flush);
  }

  Future<void> _flush() async {
    _writing = false;
    if (!_dirty) return;
    _dirty = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_lines.map((l) => l.toJson()).toList()),
      );
    } catch (e, s) {
      // Non-fatal by design: the session continues, data stays in memory.
      Log.e('transcript.save_failed', e, s);
    }
  }

  /// Plain-text export for the user to copy out.
  String toPlainText() => _lines
      .map((l) => '${l.speaker.label}: ${l.text}')
      .join('\n\n');
}
