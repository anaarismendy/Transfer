import 'errors/failures.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) =>
      switch (this) {
        Err<T>(:final failure) => onFailure(failure),
        Ok<T>(:final value) => onSuccess(value),
      };
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
