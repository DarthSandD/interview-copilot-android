/// Who produced a transcript line.
enum Speaker {
  /// The interviewer / other side of the call.
  them,

  /// You.
  you,

  /// App-generated status text.
  system;

  String get label => switch (this) {
        Speaker.them => 'Interviewer',
        Speaker.you => 'You',
        Speaker.system => 'System',
      };

  static Speaker fromName(String name) => switch (name) {
        'you' => Speaker.you,
        'sys' => Speaker.system,
        _ => Speaker.them,
      };
}

/// One committed line of transcript.
///
/// Immutable: the transcript is an append-only list, which keeps the UI
/// rebuild cheap and the data easy to serialise or export later.
class TranscriptLine {
  final Speaker speaker;
  final String text;

  /// When this line was committed (used by the UI for the time stamp).
  final DateTime at;

  const TranscriptLine({
    required this.speaker,
    required this.text,
    required this.at,
  });

  int get wordCount => text
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;

  Map<String, Object?> toJson() => {
        'speaker': speaker.name,
        'text': text,
        'at': at.toIso8601String(),
      };

  static TranscriptLine? tryFromJson(Map<String, Object?> json) {
    final text = json['text'];
    final at = json['at'];
    if (text is! String || at is! String) return null;
    final parsed = DateTime.tryParse(at);
    if (parsed == null) return null;
    return TranscriptLine(
      speaker: Speaker.fromName('${json['speaker']}'),
      text: text,
      at: parsed,
    );
  }
}

/// The lifecycle of the capture engine, as the UI needs to show it.
enum CaptureStatus {
  idle,
  preparing,
  downloadingModel,
  loadingModel,
  listening,
  stopped,
  error;

  bool get isBusy =>
      this == preparing ||
      this == downloadingModel ||
      this == loadingModel;

  String get label => switch (this) {
        CaptureStatus.idle => 'idle',
        CaptureStatus.preparing => 'preparing…',
        CaptureStatus.downloadingModel => 'downloading model…',
        CaptureStatus.loadingModel => 'loading model…',
        CaptureStatus.listening => 'listening',
        CaptureStatus.stopped => 'stopped',
        CaptureStatus.error => 'error',
      };
}
