import 'package:intl/intl.dart';

/// Formata uma data no padrão brasileiro (dd/MM/yyyy).
String formatDateBr(DateTime dt) {
  return DateFormat('dd/MM/yyyy').format(dt);
}
