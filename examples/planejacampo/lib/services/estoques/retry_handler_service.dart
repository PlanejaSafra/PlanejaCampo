import 'dart:math';

class RetryHandlerService {
  static const int _maxAttempts = 5;
  static const int _initialDelayMs = 1000;
  static const double _backoffMultiplier = 1.5;

  static Future<T> run<T>({
    required Future<T> Function() operation,
    int maxAttempts = _maxAttempts,
    int initialDelayMs = _initialDelayMs,
    double backoffMultiplier = _backoffMultiplier,
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempts = 0;
    int delay = initialDelayMs;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (e is! Exception ||
            attempts >= maxAttempts ||
            (shouldRetry != null && !shouldRetry(e as Exception))) {
          rethrow;
        }

        // Calcular próximo delay com jitter
        final jitter = (delay * 0.2 * (Random().nextDouble() - 0.5)).toInt();
        final nextDelay = delay + jitter;

        print('Tentativa $attempts falhou. Próxima tentativa em ${nextDelay}ms');
        await Future.delayed(Duration(milliseconds: nextDelay));

        // Aumentar delay para próxima tentativa
        delay = (delay * backoffMultiplier).toInt();
      }
    }
  }
}