// lib/services/agro/adubacao/calculators/interpolador_doses.dart

class InterpoladorDoses {
  /// Interpola a dose de um nutriente NPK baseado na produtividade esperada.
  /// Utiliza interpolação linear entre os pontos de recomendação.
  double interpolarDoseNPK(
      double produtividade,
      Map<double, Map<String, double>> recomendacoes
      ) {
    // Ordena as chaves de produtividade em ordem crescente
    final sortedProdutividades = recomendacoes.keys.toList()..sort();

    // Caso a produtividade esteja abaixo do menor valor, retorna a dose correspondente
    if (produtividade <= sortedProdutividades.first) {
      return recomendacoes[sortedProdutividades.first]!['dose']!;
    }

    // Caso a produtividade esteja acima do maior valor, retorna a dose correspondente
    if (produtividade >= sortedProdutividades.last) {
      return recomendacoes[sortedProdutividades.last]!['dose']!;
    }

    // Percorre os intervalos para encontrar onde a produtividade se encaixa
    for (int i = 0; i < sortedProdutividades.length - 1; i++) {
      double lower = sortedProdutividades[i];
      double upper = sortedProdutividades[i + 1];
      if (produtividade >= lower && produtividade <= upper) {
        double doseLower = recomendacoes[lower]!['dose']!;
        double doseUpper = recomendacoes[upper]!['dose']!;
        // Calcula a interpolação linear
        double doseInterpolada = doseLower +
            ((produtividade - lower) / (upper - lower)) * (doseUpper - doseLower);
        return doseInterpolada;
      }
    }

    // Se não encontrou intervalo, retorna a última dose disponível
    return recomendacoes[sortedProdutividades.last]!['dose']!;
  }

  /// Interpola a dose de um micronutriente baseado no teor do solo.
  /// Retorna a dose correspondente à faixa em que o teor se encontra.
  double interpolarDoseMicro(
      double teor,
      Map<String, double> faixas
      ) {
    // Exemplo de faixas: {'<0.6': 5.0, '0.6-1.2': 2.0, '>1.2': 0.0}
    if (teor < 0.6) {
      return faixas['<0.6']!;
    } else if (teor >= 0.6 && teor <= 1.2) {
      return faixas['0.6-1.2']!;
    } else {
      return faixas['>1.2']!;
    }
  }
}
