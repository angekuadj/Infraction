class ApiErrorResponse {
  final String? message;
  final String? error;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiErrorResponse({
    this.message,
    this.error,
    this.code,
    this.statusCode,
    this.details,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      message: json['message'] as String?,
      error: json['error'] as String?,
      code: json['code'] as String?,
      statusCode: json['statusCode'] as int?,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (message != null) 'message': message,
        if (error != null) 'error': error,
        if (code != null) 'code': code,
        if (statusCode != null) 'statusCode': statusCode,
        if (details != null) 'details': details,
      };

  String get displayMessage =>
      message ?? error ?? code ?? 'Une erreur est survenue';

  @override
  String toString() => 'ApiErrorResponse($displayMessage)';
}
