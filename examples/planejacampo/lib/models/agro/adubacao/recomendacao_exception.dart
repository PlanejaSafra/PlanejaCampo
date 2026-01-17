// lib/models/agro/adubacao/exceptions/recomendacao_exception.dart

class RecomendacaoException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  RecomendacaoException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return 'RecomendacaoException($code): $message';
    }
    return 'RecomendacaoException: $message';
  }
}
