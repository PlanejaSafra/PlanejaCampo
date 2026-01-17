import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class SimpleTemplate extends StatelessWidget {
  final String title;
  final Widget body;
  final String moduleName;
  final FloatingActionButton? floatingActionButton;
  final bool showDeleteButton;
  final VoidCallback? onDeletePressed;
  final FormatacaoUtil formatacaoUtil;
  final Widget? bottomNavigationBar;
  final List<Widget>? additionalActions;

  const SimpleTemplate({
    super.key,
    required this.title,
    required this.body,
    required this.moduleName,
    required this.formatacaoUtil,
    this.floatingActionButton,
    this.showDeleteButton = false,
    this.onDeletePressed,
    this.bottomNavigationBar,
    this.additionalActions,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este item?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Excluir'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      if (onDeletePressed != null) {
        onDeletePressed!();
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context);
    final bool canDelete = appStateManager.canDelete(moduleName);

    List<Widget> appBarActions = [];

    if (showDeleteButton && canDelete) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _confirmDelete(context),
        ),
      );
    }

    if (additionalActions != null) {
      appBarActions.addAll(additionalActions!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 4,
        actions: appBarActions.isNotEmpty ? appBarActions : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}