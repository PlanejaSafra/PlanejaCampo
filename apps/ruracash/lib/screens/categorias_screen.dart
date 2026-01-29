import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../helpers/categoria_icon_helper.dart';

/// CASH-22: Category management screen.
/// Allows viewing, creating, editing, and archiving categories.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashCategoriasTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.cashCategoriasDespesas),
            Tab(text: l10n.cashCategoriasReceitas),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoriaList(isReceita: false),
          _CategoriaList(isReceita: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoriaDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddCategoriaDialog(BuildContext context) async {
    final l10n = CashLocalizations.of(context)!;
    final nomeController = TextEditingController();
    bool isReceita = _tabController.index == 1;
    String selectedIcon = 'category';
    int selectedColor = Colors.blue.value;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.cashCategoriaNovaTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(labelText: l10n.cashCategoriaNome),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Type toggle
                Row(
                  children: [
                    Text(l10n.cashCategoriaTipo),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text(l10n.cashCategoriasDespesas),
                      selected: !isReceita,
                      onSelected: (_) => setDialogState(() => isReceita = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(l10n.cashCategoriasReceitas),
                      selected: isReceita,
                      onSelected: (_) => setDialogState(() => isReceita = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Icon picker (simplified — show common icons)
                Text(l10n.cashCategoriaIcone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoriaIconHelper.availableIcons.take(15).map((iconName) {
                    final icon = CategoriaIconHelper.getIcon(iconName);
                    final isSelected = selectedIcon == iconName;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = iconName),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(ctx).colorScheme.primary : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 24, color: isSelected ? Theme.of(ctx).colorScheme.primary : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Color picker (simplified)
                Text(l10n.cashCategoriaCor, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.blue, Colors.green, Colors.red, Colors.orange,
                    Colors.purple, Colors.teal, Colors.pink, Colors.brown,
                    Colors.indigo, Colors.amber,
                  ].map((color) {
                    final isSelected = selectedColor == color.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color.value),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelarButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.salvarButton),
            ),
          ],
        ),
      ),
    );

    if (result == true && nomeController.text.isNotEmpty) {
      final farmId = FarmService.instance.defaultFarmId ?? '';
      final userId = AuthService.currentUser?.uid ?? '';
      final cat = Categoria.custom(
        nome: nomeController.text.trim(),
        icone: selectedIcon,
        corValue: selectedColor,
        isReceita: isReceita,
        isAgro: true,
        isPersonal: true,
        farmId: farmId,
        userId: userId,
      );
      await CategoriaService().add(cat);
      if (mounted) setState(() {});
    }
  }
}

class _CategoriaList extends StatelessWidget {
  final bool isReceita;

  const _CategoriaList({required this.isReceita});

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;

    final categorias = isReceita
        ? CategoriaService().getCategoriasReceita()
        : CategoriaService().getCategoriasDespesa();

    if (categorias.isEmpty) {
      return Center(
        child: Text(l10n.cashCategoriaEmpty, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final icon = CategoriaIconHelper.getIcon(cat.icone);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cat.cor.withValues(alpha: 0.15),
              child: Icon(icon, color: cat.cor, size: 20),
            ),
            title: Text(cat.nome),
            subtitle: Text(
              cat.isCore ? l10n.cashCategoriaCore : l10n.cashCategoriaCustom,
              style: TextStyle(
                fontSize: 12,
                color: cat.isCore ? Colors.green : Colors.blue,
              ),
            ),
            trailing: cat.isCore
                ? null
                : PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'archive') {
                        await CategoriaService().arquivar(cat.id);
                        if (context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(l10n.cashCategoriaArquivar),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
