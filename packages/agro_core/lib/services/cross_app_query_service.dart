import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'farm_service.dart';

/// Service for querying data from other apps via Firestore (Tier 3).
///
/// Cross-app data sharing works through Firestore as the bridge:
/// 1. App A saves data locally (Hive) and syncs to Firestore via
///    GenericSyncService Tier 3
/// 2. App B uses [CrossAppQueryService] to read App A's data from Firestore
///
/// This is the "reader" side. It queries any Firestore collection
/// filtered by [farmId], returning raw Maps (no model dependency between apps).
///
/// Requirements:
/// - Tier 3 must be active ([Farm.isShared] = true)
/// - Both apps must sync to the same Firebase project
/// - Data is filtered by farmId to ensure multi-farm isolation
///
/// See CASH-03, CORE-78 for architecture.
class CrossAppQueryService {
  static final CrossAppQueryService _instance =
      CrossAppQueryService._internal();
  static CrossAppQueryService get instance => _instance;
  factory CrossAppQueryService() => _instance;
  CrossAppQueryService._internal();

  /// Whether cross-app queries are available.
  /// Requires the active farm to be in shared/multi-user mode (Tier 3).
  bool get isAvailable => FarmService.instance.isActiveFarmShared();

  // ═══════════════════════════════════════════════════════════════════════════
  // Generic Query
  // ═══════════════════════════════════════════════════════════════════════════

  /// Query a Firestore collection filtered by farmId.
  ///
  /// [collection]: Firestore root collection name (e.g. 'entregas', 'despesas')
  /// [farmId]: Farm to query (defaults to active farm)
  /// [filters]: Additional field-value equality filters
  ///
  /// Returns raw Maps; the caller extracts the fields it needs.
  /// Returns empty list if Tier 3 is not active.
  Future<List<Map<String, dynamic>>> queryCollection({
    required String collection,
    String? farmId,
    Map<String, dynamic>? filters,
  }) async {
    if (!isAvailable) {
      debugPrint('[CrossAppQueryService] Tier 3 not active — skipping');
      return [];
    }

    final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
    if (targetFarmId == null || targetFarmId.isEmpty) return [];

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(collection)
          .where('farmId', isEqualTo: targetFarmId);

      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[CrossAppQueryService] Error querying $collection: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Convenience: RuraRubber Revenue (Entregas)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get revenue from RuraRubber deliveries (Entregas) for a period.
  ///
  /// Each Entrega contains a list of ItemEntrega with `valorTotal`.
  /// Total revenue = sum of all ItemEntrega.valorTotal.
  ///
  /// Only includes Entregas with status 'Fechado' or 'Pago'
  /// (open deliveries have no confirmed value).
  Future<CrossAppFinancialSummary> getRubberRevenue({
    required DateTime start,
    required DateTime end,
    String? farmId,
  }) async {
    final docs = await queryCollection(
      collection: 'entregas',
      farmId: farmId,
    );

    double total = 0.0;
    final items = <CrossAppFinancialItem>[];

    for (final doc in docs) {
      // Date filter (stored as ISO8601 string)
      final dataStr = doc['data'] as String?;
      if (dataStr == null) continue;
      final data = DateTime.tryParse(dataStr);
      if (data == null) continue;
      if (data.isBefore(start) ||
          data.isAfter(end.add(const Duration(days: 1)))) {
        continue;
      }

      // Only confirmed deliveries
      final status = doc['status'] as String? ?? '';
      if (status != 'Fechado' && status != 'Pago') continue;

      // Sum valorTotal from each ItemEntrega
      final itens = doc['itens'] as List<dynamic>? ?? [];
      double entregaTotal = 0.0;
      for (final item in itens) {
        if (item is Map) {
          entregaTotal += (item['valorTotal'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (entregaTotal > 0) {
        total += entregaTotal;
        items.add(CrossAppFinancialItem(
          sourceApp: 'rurarubber',
          valor: entregaTotal,
          data: data,
          description: doc['compradorId'] as String?,
        ));
      }
    }

    return CrossAppFinancialSummary(
      sourceApp: 'rurarubber',
      total: total,
      items: items,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Convenience: RuraRubber Expenses (Despesas)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get expenses from RuraRubber (Despesas) for a period.
  ///
  /// Each Despesa has a `valor` and `categoria` (enum index).
  Future<CrossAppFinancialSummary> getRubberExpenses({
    required DateTime start,
    required DateTime end,
    String? farmId,
  }) async {
    final docs = await queryCollection(
      collection: 'despesas',
      farmId: farmId,
    );

    double total = 0.0;
    final items = <CrossAppFinancialItem>[];

    for (final doc in docs) {
      // Date filter
      final dataStr = doc['data'] as String?;
      if (dataStr == null) continue;
      final data = DateTime.tryParse(dataStr);
      if (data == null) continue;
      if (data.isBefore(start) ||
          data.isAfter(end.add(const Duration(days: 1)))) {
        continue;
      }

      // Skip soft-deleted
      if (doc['deleted'] == true) continue;

      final valor = (doc['valor'] as num?)?.toDouble() ?? 0.0;
      if (valor <= 0) continue;

      total += valor;
      items.add(CrossAppFinancialItem(
        sourceApp: 'rurarubber',
        valor: valor,
        data: data,
        description: doc['descricao'] as String?,
        categoriaIndex: doc['categoria'] as int?,
      ));
    }

    return CrossAppFinancialSummary(
      sourceApp: 'rurarubber',
      total: total,
      items: items,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Convenience: Generic cross-app lancamentos (for RuraRubber break-even)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get lancamentos (expenses) from RuraCash for a period.
  ///
  /// Useful for RuraRubber's break-even to include general farm expenses
  /// registered in RuraCash.
  Future<CrossAppFinancialSummary> getCashExpenses({
    required DateTime start,
    required DateTime end,
    String? farmId,
  }) async {
    final docs = await queryCollection(
      collection: 'lancamentos',
      farmId: farmId,
    );

    double total = 0.0;
    final items = <CrossAppFinancialItem>[];

    for (final doc in docs) {
      final dataStr = doc['data'] as String?;
      if (dataStr == null) continue;
      final data = DateTime.tryParse(dataStr);
      if (data == null) continue;
      if (data.isBefore(start) ||
          data.isAfter(end.add(const Duration(days: 1)))) {
        continue;
      }

      if (doc['deleted'] == true) continue;

      final valor = (doc['valor'] as num?)?.toDouble() ?? 0.0;
      if (valor <= 0) continue;

      total += valor;
      items.add(CrossAppFinancialItem(
        sourceApp: 'ruracash',
        valor: valor,
        data: data,
        description: doc['descricao'] as String?,
        categoriaId: doc['categoriaId'] as String?,
      ));
    }

    return CrossAppFinancialSummary(
      sourceApp: 'ruracash',
      total: total,
      items: items,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DTOs — App-agnostic financial data from cross-app queries
// ═══════════════════════════════════════════════════════════════════════════

/// Aggregated financial data from another app.
class CrossAppFinancialSummary {
  final String sourceApp;
  final double total;
  final List<CrossAppFinancialItem> items;

  const CrossAppFinancialSummary({
    required this.sourceApp,
    required this.total,
    required this.items,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// A single financial item from another app.
class CrossAppFinancialItem {
  final String sourceApp;
  final double valor;
  final DateTime data;
  final String? description;

  /// For rubber Despesas — maps to CategoriaDespesa enum index.
  final int? categoriaIndex;

  /// For cash Lancamentos — maps to Categoria UUID.
  final String? categoriaId;

  const CrossAppFinancialItem({
    required this.sourceApp,
    required this.valor,
    required this.data,
    this.description,
    this.categoriaIndex,
    this.categoriaId,
  });
}
