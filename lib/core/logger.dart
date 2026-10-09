import 'dart:developer' as developer;

/// Privacy-preserving logger.
///
/// Transcript text and notes are sensitive — a leaked log is a leaked
/// interview. This logger therefore NEVER accepts free-form transcript
/// content: callers pass counts, durations and event names only.
///
/// In release builds everything below [LogLevel.warn] is dropped.
enum LogLevel { debug, info, warn, error }

abstract final class Log {
  static const bool _verbose = bool.fromEnvironment('dart.vm.product') == false;

  static void d(String event, [Map<String, Object?>? fields]) {
    if (!_verbose) return;
    _emit(LogLevel.debug, event, fields);
  }

  static void i(String event, [Map<String, Object?>? fields]) =>
      _emit(LogLevel.info, event, fields);

  static void w(String event, [Map<String, Object?>? fields]) =>
      _emit(LogLevel.warn, event, fields);

  static void e(
    String event,
    Object error, [
    StackTrace? stack,
  ]) {
    developer.log(
      event,
      name: 'interview_copilot',
      level: 1000,
      error: _redact(error.toString()),
      stackTrace: stack,
    );
  }

  static void _emit(LogLevel level, String event, Map<String, Object?>? fields) {
    final buffer = StringBuffer(event);
    if (fields != null && fields.isNotEmpty) {
      buffer.write(' ');
      buffer.write(
        fields.entries
            .map((e) => '${e.key}=${_redact('${e.value}')}')
            .join(' '),
      );
    }
    developer.log(
      buffer.toString(),
      name: 'interview_copilot',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      },
    );
  }

  /// Trims anything that looks like a filesystem path or a long free-text
  /// blob, so an accidental transcript cannot ride out through a log line.
  static String _redact(String value) {
    if (value.length > 120) return '${value.substring(0, 40)}…[redacted]';
    return value;
  }
}
