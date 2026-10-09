import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

/// Persistent store for the user's private notes / battle card.
///
/// Notes are the most sensitive thing the app holds, so they are:
///  * written to app-private storage only (never external, never backed up —
///    see `android:allowBackup="false"` in the manifest);
///  * never logged, not even a length-prefixed excerpt;
///  * saved with a debounce so typing does not thrash disk.
class NotesStore {
  static const _key = 'ic_notes_v1';
  static const _maxChars = 200 * 1024;

  String _value = '';
  Timer? _debounce;

  String get value => _value;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _value = prefs.getString(_key) ?? '';
    } catch (e, s) {
      Log.e('notes.load_failed', e, s);
      _value = '';
    }
  }

  void update(String next) {
    if (next.length > _maxChars) {
      next = next.substring(0, _maxChars);
    }
    _value = next;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _value);
    } catch (e, s) {
      // Never surfaced to the user mid-interview; data stays in memory.
      Log.e('notes.save_failed', e, s);
    }
  }

  /// Flush any pending write immediately (used on stop / dispose).
  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    await _save();
  }

  void dispose() {
    _debounce?.cancel();
    _debounce = null;
  }
}
