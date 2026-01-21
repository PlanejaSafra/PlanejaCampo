class FinanceiroHelper {
  /// Calculates the partner's share based on total sale value and split percentage
  /// [totalVenda] = total value of the sale (R$)
  /// [porcentagemParceiro] = partner's share (e.g. 50.0 for 50%)
  static double calcularParteParceiro(
      double totalVenda, double porcentagemParceiro) {
    return totalVenda * (porcentagemParceiro / 100);
  }

  /// Calculates the total value of a specific weight based on price
  /// [peso] = weight in kg
  /// [precoPorKg] = price per kg (R$)
  static double calcularValorTotal(double peso, double precoPorKg) {
    return peso * precoPorKg;
  }
}
