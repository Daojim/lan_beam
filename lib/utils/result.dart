/// Result type for better error handling
sealed class Result<T> {
  const Result();

  /// Creates a successful result
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result
  const factory Result.failure(String error, [Exception? exception]) =
      Failure<T>;

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Gets the value if success, null if failure
  T? get value => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  /// Gets the error message if failure, null if success
  String? get error => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };

  /// Maps the success value to a new type
  Result<U> map<U>(U Function(T) mapper) => switch (this) {
    Success(value: final v) => Result.success(mapper(v)),
    Failure(error: final e, exception: final ex) => Result.failure(e, ex),
  };

  /// Chains multiple operations that return Results
  Result<U> flatMap<U>(Result<U> Function(T) mapper) => switch (this) {
    Success(value: final v) => mapper(v),
    Failure(error: final e, exception: final ex) => Result.failure(e, ex),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error, [this.exception]);
  final String error;
  final Exception? exception;
}
