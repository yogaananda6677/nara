sealed class AppFailure {
  const AppFailure({required this.code, required this.message, this.cause});

  final String code;
  final String message;
  final Object? cause;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.code, required super.message});
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    required super.code,
    required super.message,
    super.cause,
  });
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    required super.code,
    required super.message,
    super.cause,
  });
}

final class LocalServiceFailure extends AppFailure {
  const LocalServiceFailure({
    required super.code,
    required super.message,
    super.cause,
  });
}

final class ToolFailure extends AppFailure {
  const ToolFailure({required super.code, required super.message, super.cause});
}

final class OcrFailure extends AppFailure {
  const OcrFailure({required super.code, required super.message, super.cause});
}

final class ClassificationFailure extends AppFailure {
  const ClassificationFailure({
    required super.code,
    required super.message,
    super.cause,
  });
}
