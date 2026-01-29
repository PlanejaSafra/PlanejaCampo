import 'package:agro_core/agro_core.dart';
import '../models/conta.dart';

/// CASH-23: Service for managing bank/financial accounts.
class ContaService extends GenericSyncService<Conta> {
  static final ContaService _instance = ContaService._internal();
  static ContaService get instance => _instance;
  ContaService._internal();
  factory ContaService() => _instance;

  @override
  String get boxName => 'contas';

  @override
  String get sourceApp => 'ruracash';

  @override
  String get firestoreCollection => 'contas';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  Conta fromMap(Map<String, dynamic> map) => Conta.fromJson(map);

  @override
  Map<String, dynamic> toMap(Conta item) => item.toJson();

  @override
  String getId(Conta item) => item.id;

  // ─────────────────────────────────────────────────────────────────────
  // Queries
  // ─────────────────────────────────────────────────────────────────────

  /// All active accounts for the current farm.
  List<Conta> get contas {
    final farmId = FarmService.instance.defaultFarmId;
    if (farmId == null) return [];
    return getByFarmId(farmId).where((c) => c.isAtiva && !(c.deleted ?? false)).toList();
  }

  /// Active asset accounts (carteira, corrente, poupança, investimento).
  List<Conta> get contasAtivo => contas.where((c) => c.isAtivo).toList();

  /// Active liability accounts (cartão crédito, empréstimo).
  List<Conta> get contasPassivo => contas.where((c) => c.isPassivo).toList();

  /// Get account by ID.
  Conta? getConta(String id) => getById(id);

  /// Total balance of all asset accounts.
  double get totalAtivos => contasAtivo.fold(0.0, (sum, c) => sum + c.saldoAtual);

  /// Total balance of all liability accounts.
  double get totalPassivos => contasPassivo.fold(0.0, (sum, c) => sum + c.saldoAtual);

  /// Net worth = assets - liabilities.
  double get patrimonioLiquido => totalAtivos - totalPassivos;

  /// Accounts by type.
  List<Conta> getByTipo(TipoConta tipo) => contas.where((c) => c.tipo == tipo).toList();

  // ─────────────────────────────────────────────────────────────────────
  // Balance Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Credit: add value to account balance.
  Future<void> creditar(String contaId, double valor) async {
    final conta = getById(contaId);
    if (conta == null) return;
    final updated = conta.copyWith(saldoAtual: conta.saldoAtual + valor);
    await update(contaId, updated);
  }

  /// Debit: subtract value from account balance.
  Future<void> debitar(String contaId, double valor) async {
    final conta = getById(contaId);
    if (conta == null) return;
    final updated = conta.copyWith(saldoAtual: conta.saldoAtual - valor);
    await update(contaId, updated);
  }

  /// Transfer between accounts.
  Future<void> transferir(String origemId, String destinoId, double valor) async {
    await debitar(origemId, valor);
    await creditar(destinoId, valor);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Default account
  // ─────────────────────────────────────────────────────────────────────

  /// Ensure a default "Carteira" account exists for the current farm.
  Future<void> ensureDefaultConta() async {
    if (contas.isEmpty) {
      final conta = Conta.create(
        nome: 'Carteira',
        tipo: TipoConta.carteira,
      );
      await add(conta);
    }
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return contas.map((c) => c.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final conta = Conta.fromJson(json as Map<String, dynamic>);
      if (getById(conta.id) == null) {
        await add(conta);
      }
    }
  }
}
