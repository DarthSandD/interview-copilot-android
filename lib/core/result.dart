/// Outcome of an operation that can fail in an expected way.
///
/// Used instead of throwing across layer boundaries so the UI can render a
/// real message and the failure path is explicit at the call site.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  String? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final message) => message,
      };

  R fold<R>(R Function(T value) onOk, R Function(String message) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final message) => onErr(message),
    };
  }
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}
