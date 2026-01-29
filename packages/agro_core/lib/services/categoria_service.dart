import 'package:collection/collection.dart';
import 'package:hive/hive.dart';

import '../exceptions/categoria_exceptions.dart';
import '../models/categoria.dart';
import '../models/categoria_core.dart';
import 'farm_service.dart';
import 'sync/generic_sync_service.dart';

/// Serviço gerenciador de categorias financeiras unificadas.
class CategoriaService extends GenericSyncService<Categoria> {
  static const String _boxName = 'categorias';

  // Singleton
  static final CategoriaService _instance = CategoriaService._internal();
  factory CategoriaService() => _instance;
  CategoriaService._internal();

  @override
  String get boxName => _boxName;

  @override
  String get sourceApp => 'agro_core';

  @override
  String get firestoreCollection => 'categorias';

  /// Sync Tier 3 só é habilitado se a farm estiver em modo compartilhado
  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  Categoria fromMap(Map<String, dynamic> map) => Categoria.fromJson(map);

  @override
  Map<String, dynamic> toMap(Categoria item) => item.toJson();

  @override
  String getId(Categoria item) => item.id;

  // --- Queries ---

  /// Todas as categorias da farm ativa (ativas e inativas)
  /// Se farmId não for passado, infere da farm ativa.
  List<Categoria> getCategorias({String? farmId}) {
    final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
    if (targetFarmId == null) return [];
    
    // Sort: 1. Core, 2. Ordem
    return getAll()
        .where((c) => c.farmId == targetFarmId && !c.deleted!)
        .sorted((a, b) {
          if (a.isCore && !b.isCore) return -1;
          if (!a.isCore && b.isCore) return 1;
          return a.ordem.compareTo(b.ordem);
        });
  }

  /// Apenas categorias ativas (para exibir em listas de seleção)
  List<Categoria> getCategoriasAtivas({String? farmId}) {
    return getCategorias(farmId: farmId).where((c) => c.isAtiva).toList();
  }

  List<Categoria> getCategoriasAgro({String? farmId}) {
    return getCategoriasAtivas(farmId: farmId).where((c) => c.isAgro).toList();
  }

  List<Categoria> getCategoriasPersonal({String? farmId}) {
    return getCategoriasAtivas(farmId: farmId).where((c) => c.isPersonal).toList();
  }

  List<Categoria> getCategoriasReceita({String? farmId}) {
    return getCategoriasAtivas(farmId: farmId).where((c) => c.isReceita).toList();
  }

  List<Categoria> getCategoriasDespesa({String? farmId}) {
    return getCategoriasAtivas(farmId: farmId).where((c) => !c.isReceita).toList();
  }

  /// Busca categoria cross-app pelo coreKey (ex: 'combustivel')
  Categoria? getByCoreKey(String coreKey, {String? farmId}) {
    return getCategorias(farmId: farmId).firstWhereOrNull((c) => c.coreKey == coreKey);
  }

  // --- Inicialização Core ---

  /// Garante que todas as categorias core existam para a farm ativa.
  /// Deve ser chamado no startup do app ou ao trocar de farm.
  Future<void> ensureDefaultCategorias({String? farmId}) async {
    final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
    if (targetFarmId == null) return;
    final userId = FarmService.instance.getFarmById(targetFarmId)?.ownerId;
    if (userId == null) return;

    for (final core in CategoriaCore.values) {
      final existing = getByCoreKey(core.key, farmId: targetFarmId);
      
      if (existing == null) {
        // Cria se não existir
        final nova = Categoria.core(
          coreKey: core.key,
          nome: core.defaultNome,
          icone: core.defaultIcone,
          corValue: core.defaultCorValue,
          isReceita: core.isReceita,
          isAgro: core.isAgro,
          isPersonal: core.isPersonal,
          farmId: targetFarmId,
          userId: userId,
        );
        await add(nova);
      }
    }
  }

  // --- CRUD Protegido ---

  @override
  Future<void> update(String id, Categoria categoria) async {
    final existing = getById(id);
    if (existing == null) throw CategoriaNotFoundException(id);

    // Proteção: coreKey imutável
    if (existing.coreKey != categoria.coreKey) {
      throw CategoriaCoreKeyImmutableException();
    }

    // Proteção: Tipo imutável se tiver uso (placeholder, validar depois)
    // if (existing.isReceita != categoria.isReceita && hasUsage) throw Exception...

    await super.update(id, categoria);
  }

  @override
  Future<void> delete(String id) async {
    final categoria = getById(id);
    if (categoria == null) return;

    // Proteção: não deletar Core
    if (categoria.isCore) {
      throw CategoriaCoreDeleteException();
    }

    // TODO: Verificar uso (lançamentos vinculados)
    // Se tiver uso -> Arquivar (update isAtiva=false)
    // Se não tiver uso -> Delete físico
    
    // Por enquanto, sempre sync-friendly delete (soft delete interno do GenericSyncService seta deleted=true)
    // Mas para UX, preferimos "Arquivar" (isAtiva=false).
    // O delete() do GenericSyncService remove do Hive (ou marca tombstone). 
    // Se quisermos apenas "Esconder", devemos usar update(isAtiva=false).
    
    await super.delete(id);
  }

  /// Arquiva uma categoria (soft delete funcional para o usuário)
  Future<void> arquivar(String id) async {
    final cat = getById(id);
    if (cat != null) {
      final updated = cat.copyWith(isAtiva: false);
      await update(id, updated);
    }
  }
}
