import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../core/logger.dart';
import '../core/result.dart';
import '../data/model_integrity.dart';
import '../domain/models.dart';

/// A snapshot of engine state pushed to the UI.
class CaptureSnapshot {
  final CaptureStatus status;
  final String? partial;
  final String? message;

  const CaptureSnapshot({
    required this.status,
    this.partial,
    this.message,
  });
}

/// Owns the microphone, the Whisper session and their lifecycle.
///
/// This is the only place that touches audio hardware or native inference.
/// It exposes three streams so the UI can stay a pure function of state:
///
///  * [snapshots]  — status transitions (idle → loading → listening → …)
///  * [partials]   — the in-flight, not-yet-final transcript text
///  * [levels]     — normalised 0..1 microphone loudness, ~12 Hz
///
/// Everything is cancellable and [dispose] releases the microphone and the
/// native whisper context; leaking either would keep the mic hot after the
/// user stops.
class CaptureService {
  CaptureService({AudioRecorder? recorder, WhisperController? whisper})
      : _rec = recorder ?? AudioRecorder(),
        _whisper = whisper ?? WhisperController();

  final AudioRecorder _rec;
  final WhisperController _whisper;

  final _snapshots = StreamController<CaptureSnapshot>.broadcast();
  final _partials = StreamController<String>.broadcast();
  final _levels = StreamController<double>.broadcast();

  WhisperLiveSession? _session;
  StreamSubscription<String>? _partialSub;
  StreamSubscription<Amplitude>? _ampSub;
  bool _starting = false;
  bool _disposed = false;

  Stream<CaptureSnapshot> get snapshots => _snapshots.stream;
  Stream<String> get partials => _partials.stream;
  Stream<double> get levels => _levels.stream;

  bool get isListening => _session != null;
  bool get isStarting => _starting;

  void _emit(CaptureStatus status, {String? message}) {
    if (_disposed || _snapshots.isClosed) return;
    _snapshots.add(CaptureSnapshot(status: status, message: message));
  }

  /// True when the microphone permission is already granted.
  Future<bool> hasPermission() async {
    try {
      return await _rec.hasPermission();
    } catch (e, s) {
      Log.e('capture.permission_check_failed', e, s);
      return false;
    }
  }

  /// Makes sure a verified model file exists locally, downloading and
  /// verifying it if necessary.
  ///
  /// The file is integrity-checked on **every** start, not just the first,
  /// so a model corrupted after download is caught before it reaches the
  /// native parser.
  Future<Result<String>> ensureModel() async {
    final spec = ModelCatalog.baseEn;
    try {
      final path = await _whisper.getPath(WhisperModel.baseEn);
      final file = File(path);

      if (!await file.exists()) {
        _emit(CaptureStatus.downloadingModel);
        Log.i('model.download_start', {'name': spec.name});
        await _whisper.downloadModel(WhisperModel.baseEn);
      }

      final verified = await ModelIntegrity.verify(file, spec);
      final Result<String> result = verified.fold(
        (f) => Ok(f.path),
        (msg) {
          // A file that fails verification is deleted so the next attempt
          // re-downloads cleanly instead of failing forever.
          unawaited(_quarantine(file));
          return Err(msg);
        },
      );
      return result;
    } catch (e, s) {
      Log.e('model.ensure_failed', e, s);
      return const Err('Could not prepare the speech model. Check your '
          'internet connection and try again.');
    }
  }

  Future<void> _quarantine(File file) async {
    try {
      if (await file.exists()) await file.delete();
      Log.w('model.quarantined');
    } catch (e, s) {
      Log.e('model.quarantine_failed', e, s);
    }
  }

  /// Starts capture. Safe to call twice — the second call is ignored while a
  /// start is already in flight.
  Future<void> start() async {
    if (_starting || isListening) return;
    _starting = true;

    try {
      _emit(CaptureStatus.preparing);

      if (!await hasPermission()) {
        _emit(CaptureStatus.error, message: 'Microphone permission is required.');
        return;
      }

      final model = await ensureModel();
      if (model.isErr) {
        _emit(CaptureStatus.error, message: model.errorOrNull);
        return;
      }

      _emit(CaptureStatus.loadingModel);

      final stream = await _rec.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      final session = await _whisper.transcribeLive(
        model: WhisperModel.baseEn,
        pcm16Stream: stream,
        lang: 'en',
        // Domain priming measurably improves technical-term accuracy.
        initialPrompt:
            'Technical interview about AI: retrieval augmented generation, '
            'RAG, embeddings, vector database, chunking, LLM, latency, tokens, '
            'API, Python, production, deployment, cost, architecture.',
        suppressNonSpeechTokens: true,
      );

      _session = session;
      _partialSub = session.partials.listen(
        (t) {
          if (_disposed || _partials.isClosed) return;
          _partials.add(t);
        },
        onError: (Object e, StackTrace s) {
          Log.e('capture.partial_error', e, s);
        },
      );

      _startLevelMeter();
      Log.i('capture.started');
      _emit(CaptureStatus.listening);
    } catch (e, s) {
      Log.e('capture.start_failed', e, s);
      await _teardown();
      _emit(CaptureStatus.error, message: 'Could not start listening.');
    } finally {
      _starting = false;
    }
  }

  /// Normalised microphone loudness for the live waveform.
  void _startLevelMeter() {
    _ampSub?.cancel();
    _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 80)).listen(
      (amp) {
        if (_disposed || _levels.isClosed) return;
        // dBFS: roughly -60 (silence) .. 0 (clipping). Map to 0..1.
        final db = amp.current.isFinite ? amp.current : -60.0;
        final normalised = ((db + 60) / 60).clamp(0.0, 1.0);
        _levels.add(normalised);
      },
      onError: (Object e) => Log.w('capture.level_error', {'e': e}),
    );
  }

  /// Stops capture and returns the final transcript text for this segment.
  Future<String> stop() async {
    final session = _session;
    if (session == null) {
      await _teardown();
      _emit(CaptureStatus.stopped);
      return '';
    }

    String finalText = '';
    try {
      await _rec.stop();
      finalText = await session.stop();
    } catch (e, s) {
      Log.e('capture.stop_failed', e, s);
    } finally {
      await _teardown();
      _emit(CaptureStatus.stopped);
    }
    return finalText.trim();
  }

  Future<void> _teardown() async {
    await _ampSub?.cancel();
    _ampSub = null;
    await _partialSub?.cancel();
    _partialSub = null;
    _session = null;
    try {
      // The recorder may still be streaming; stop it without awaiting so a
      // hung platform call cannot stall the teardown path.
      if (await _rec.isRecording()) unawaited(_rec.stop());
    } catch (e, s) {
      Log.e('capture.teardown_failed', e, s);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _teardown();
    await _snapshots.close();
    await _partials.close();
    await _levels.close();
    try {
      await _rec.dispose();
    } catch (e, s) {
      Log.e('capture.dispose_failed', e, s);
    }
  }
}
