import 'package:planejacampo/services/app_state_manager.dart';

class DiasUteisOptions {
  // Ajusta a data para o próximo dia útil (se cair em fim de semana ou feriado)
  static DateTime ajustarParaDiaUtil(DateTime data) {
    // Obter o código do país do AppStateManager
    final String countryCode = AppStateManager().appLocale.countryCode ?? 'BR';

    // Primeiro, ajusta para não cair em fim de semana
    while (data.weekday == DateTime.saturday || data.weekday == DateTime.sunday) {
      data = data.add(const Duration(days: 1));
    }

    // Depois, verifica se a data (possivelmente já ajustada) cai em algum feriado
    while (_ehFeriado(data, countryCode)) {
      data = data.add(const Duration(days: 1));
      // Verifica novamente se não caiu em fim de semana
      while (data.weekday == DateTime.saturday || data.weekday == DateTime.sunday) {
        data = data.add(const Duration(days: 1));
      }
    }

    return data;
  }

// Verifica se a data é um feriado com base no país
  static bool _ehFeriado(DateTime data, String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'BR':
        return _ehFeriadoBrasil(data);
      case 'US':
        return _ehFeriadoEUA(data);
      default:
        return false; // Para outros países, não verificamos feriados
    }
  }

// Verifica se a data é um feriado nacional no Brasil
  static bool _ehFeriadoBrasil(DateTime data) {
    // Feriados nacionais fixos do Brasil
    if ((data.month == 1 && data.day == 1) ||   // Ano Novo
        (data.month == 4 && data.day == 21) ||  // Tiradentes
        (data.month == 5 && data.day == 1) ||   // Dia do Trabalho
        (data.month == 9 && data.day == 7) ||   // Independência
        (data.month == 10 && data.day == 12) || // Nossa Senhora Aparecida
        (data.month == 11 && data.day == 2) ||  // Finados
        (data.month == 11 && data.day == 15) || // Proclamação da República
        (data.month == 12 && data.day == 25)) { // Natal
      return true;
    }

    // Feriados móveis baseados na Páscoa
    int ano = data.year;
    DateTime pascoa = _calcularPascoa(ano);

    // Carnaval (terça-feira, 47 dias antes da Páscoa)
    DateTime carnaval = pascoa.subtract(const Duration(days: 47));
    if (data.month == carnaval.month && data.day == carnaval.day) {
      return true;
    }

    // Sexta-feira Santa (dois dias antes da Páscoa)
    DateTime sextaSanta = pascoa.subtract(const Duration(days: 2));
    if (data.month == sextaSanta.month && data.day == sextaSanta.day) {
      return true;
    }

    // Corpus Christi (60 dias após a Páscoa)
    DateTime corpusChristi = pascoa.add(const Duration(days: 60));
    if (data.month == corpusChristi.month && data.day == corpusChristi.day) {
      return true;
    }

    return false;
  }

// Verifica se a data é um feriado nacional nos EUA
  static bool _ehFeriadoEUA(DateTime data) {
    int ano = data.year;

    // Feriados fixos dos EUA
    if ((data.month == 1 && data.day == 1) ||                    // New Year's Day
        (data.month == 7 && data.day == 4) ||                    // Independence Day
        (data.month == 11 && data.day == 11) ||                  // Veterans Day
        (data.month == 12 && data.day == 25)) {                  // Christmas
      return true;
    }

    // Martin Luther King Jr. Day (terceira segunda-feira de janeiro)
    if (data.month == 1) {
      int diaMLK = _nesimoXDiaDaSemana(ano, 1, DateTime.monday, 3);
      if (data.day == diaMLK) return true;
    }

    // Presidents' Day (terceira segunda-feira de fevereiro)
    if (data.month == 2) {
      int diaPresidents = _nesimoXDiaDaSemana(ano, 2, DateTime.monday, 3);
      if (data.day == diaPresidents) return true;
    }

    // Memorial Day (última segunda-feira de maio)
    if (data.month == 5) {
      int diaMemorial = _ultimoXDiaDaSemana(ano, 5, DateTime.monday);
      if (data.day == diaMemorial) return true;
    }

    // Labor Day (primeira segunda-feira de setembro)
    if (data.month == 9) {
      int diaLabor = _nesimoXDiaDaSemana(ano, 9, DateTime.monday, 1);
      if (data.day == diaLabor) return true;
    }

    // Thanksgiving (quarta quinta-feira de novembro)
    if (data.month == 11) {
      int diaThanksgiving = _nesimoXDiaDaSemana(ano, 11, DateTime.thursday, 4);
      if (data.day == diaThanksgiving) return true;
    }

    // Juneteenth (19 de junho)
    if (data.month == 6 && data.day == 19 && ano >= 2021) { // Feriado federal a partir de 2021
      return true;
    }

    return false;
  }

// Algoritmo de Gauss para calcular a data da Páscoa
  static DateTime _calcularPascoa(int ano) {
    int a = ano % 19;
    int b = ano ~/ 100;
    int c = ano % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int mes = (h + l - 7 * m + 114) ~/ 31;
    int dia = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(ano, mes, dia);
  }

// Calcula o n-ésimo dia da semana em um determinado mês/ano
// Por exemplo: terceira segunda-feira de janeiro de 2023
  static int _nesimoXDiaDaSemana(int ano, int mes, int diaDaSemana, int nesimo) {
    // Primeiro dia do mês
    DateTime primeiroDia = DateTime(ano, mes, 1);

    // Dias a adicionar para chegar ao primeiro DIA_DA_SEMANA do mês
    int diasParaAdicionar = (diaDaSemana - primeiroDia.weekday) % 7;
    if (diasParaAdicionar < 0) diasParaAdicionar += 7;

    // Calcular o dia
    int dia = 1 + diasParaAdicionar + (nesimo - 1) * 7;

    return dia;
  }

// Calcula o último dia da semana específico em um determinado mês/ano
// Por exemplo: última segunda-feira de maio de 2023
  static int _ultimoXDiaDaSemana(int ano, int mes, int diaDaSemana) {
    // Primeiro dia do próximo mês
    DateTime primeiroDiaProximoMes = DateTime(ano, mes + 1, 1);

    // Voltar para o último dia do mês atual
    DateTime ultimoDiaMes = primeiroDiaProximoMes.subtract(const Duration(days: 1));

    // Dias a subtrair para chegar ao último DIA_DA_SEMANA do mês
    int diasParaSubtrair = (ultimoDiaMes.weekday - diaDaSemana) % 7;
    if (diasParaSubtrair < 0) diasParaSubtrair += 7;

    // Calcular o dia
    int dia = ultimoDiaMes.day - diasParaSubtrair;

    return dia;
  }
}