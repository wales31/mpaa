class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.cause,
  });

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException(code: $code, message: $message, cause: $cause)';
}
