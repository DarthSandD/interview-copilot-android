import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/logger.dart';
import '../data/notes_store.dart';
import '../data/transcript_store.dart';
import '../domain/models.dart';
import '../services/capture_service.dart';

/// Single source of truth for the UI.
///
/// The widget layer never talks to audio, disk or native code directly — it
/// reads this controller and calls intent methods on it. That keeps the UI a
/// pure function of state and makes the whole flow testable without a
/// microphone.
class CopilotController extends ChangeNotifier {
  CopilotController({
    CaptureService? capture,
    TranscriptStore? transcript,
    NotesStore? notes,
  })  : _capture = capture ?? CaptureService(),
        _transcript = transcript ?? TranscriptStore(),
        _notes = notes ?? NotesStore();

  final CaptureService _capture;
  final TranscriptStore _transcript;
  final NotesStore _notes;

  StreamSubscription<CaptureSnapshot>? _snapshotSub;
  StreamSubscription<String>? _partialSub;
  StreamSubscription<double>? _levelSub;

  CaptureStatus _status = CaptureStatus.idle;
  String _partial = '';
  String? _errorMessage;
  double _level = 0;
  bool _initialised = false;
  bool _disposed = false;

  // ---------------------------------------------------------------- getters
  CaptureStatus get status => _status;
  String get partial => _partial;
  String? get errorMessage => _errorMessage;
  double get level => _level;
  bool get isListening => _status == CaptureStatus.listening;
  bool get isBusy => _status.isBusy;
  bool get isInitialised => _initialised;

  List<TranscriptLine> get lines => _transcript.lines;
  int get lineCount => _transcript.length;
  int get wordCount =>
      _transcript.lines.fold<int>(0, (a, l) => a + l.wordCount);
  bool get hasTranscript => !_transcript.isEmpty;

  String get notes => _notes.value;

  // ------------------------------------------------------------ lifecycle
  Future<void> init() async {
    if (_initialised) return;

    await _transcript.load();
    await _notes.load();

    _snapshotSub = _capture.snapshots.listen(_onSnapshot);
    _partialSub = _capture.partials.listen((t) {
      _partial = t;
      _safeNotify();
    });
    _levelSub = _capture.levels.listen((v) {
      _level = v;
      _safeNotify();
    });

    _initialised = true;
    _safeNotify();
  }

  void _onSnapshot(CaptureSnapshot s) {
    _status = s.status;
    if (s.message != null) _errorMessage = s.message;
    if (s.status == CaptureStatus.listening) {
      _errorMessage = null;
    }
    if (!s.status.isBusy && s.status != CaptureStatus.listening) {
      _level = 0;
    }
    _safeNotify();
  }

  // ---------------------------------------------------------------- intents
  /// Start / stop capture. Keeps the screen awake while listening so the
  /// phone does not sleep mid-interview.
  Future<void> toggle() async {
    if (isBusy) return;

    if (isListening) {
      final text = await _capture.stop();
      _commit(text);
      await _setWakelock(false);
      _partial = '';
      _safeNotify();
    } else {
      _errorMessage = null;
      _safeNotify();
      await _capture.start();
      if (isListening) {
        await _setWakelock(true);
      }
    }
  }

  void _commit(String text) {
    if (text.isEmpty) return;
    _transcript.add(
      TranscriptLine(speaker: Speaker.them, text: text, at: DateTime.now()),
    );
    Log.i('transcript.commit', {'lines': _transcript.length});
  }

  void updateNotes(String value) {
    _notes.update(value);
    _safeNotify();
  }

  void clearTranscript() {
    _transcript.clear();
    _safeNotify();
  }

  String exportTranscript() => _transcript.toPlainText();

  Future<void> _setWakelock(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (e, s) {
      // Non-fatal: the interview continues even if the wakelock fails.
      Log.e('wakelock.failed', e, s);
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _snapshotSub?.cancel();
    _partialSub?.cancel();
    _levelSub?.cancel();
    _capture.dispose();
    _notes.dispose();
    unawaited(_setWakelock(false));
    super.dispose();
  }
}
