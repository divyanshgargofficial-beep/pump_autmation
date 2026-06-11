class ApiResult<T> {
  const ApiResult._({
    this.data,
    this.error,
  });

  final T? data;
  final String? error;

  bool get isSuccess => error == null;

  static ApiResult<T> success<T>(T data) => ApiResult<T>._(data: data);

  static ApiResult<T> failure<T>(String message) =>
      ApiResult<T>._(error: message);
}
