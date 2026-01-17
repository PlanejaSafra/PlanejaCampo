import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/item_operacao_rural.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/item_operacao_rural_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/processamento_estornos_service.dart';
import 'package:planejacampo/utils/collection_options.dart';
import 'package:planejacampo/services/app_state_manager.dart';

class DialogScreen {
  static Future<void> confirmDelete<T>(
      BuildContext context, {
        required GenericService<T> serviceName,
        required String itemIdValue,
        required String itemName,
        required Function onSuccessDialog,
      }) async {
    // Exibir o diálogo de confirmação inicial
    final bool? confirmInitialDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(itemName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );

    if (confirmInitialDelete != true) return;

    // Mostrar diálogo de carregamento enquanto verifica dependências
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    S.of(context).checking_dependencies ?? "Verificando dependências...",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Verificar todas as dependências (diretas e indiretas)
    final Map<String, List<Map<String, dynamic>>> dependencias =
    await serviceName.verificarDependencias(itemIdValue, serviceName.baseCollection);

    // Adicione estes logs de debug
    print("=== DEPENDÊNCIAS ENCONTRADAS ===");
    print("Total de coleções: ${dependencias.length}");
    for (var entry in dependencias.entries) {
      print("Coleção: ${entry.key} - ${entry.value.length} documentos");
    }
    print("==============================");

    // Fechar o diálogo de carregamento
    Navigator.of(context).pop();

    if (dependencias.isNotEmpty) {
      // Contagem total de itens dependentes
      int totalDependentes = 0;
      for (var entry in dependencias.entries) {
        totalDependentes += entry.value.length;
      }

      final bool? confirmDeleteWithDependencies = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).found_dependencies),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).found_dependencies_message),
                      SizedBox(height: 8.0),
                      Text(
                        "Total de itens dependentes: $totalDependentes",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text("Detalhamento por tipo:"),
                      SizedBox(height: 8.0),
                      for (var entry in dependencias.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '${CollectionOptions.getLocalizedCollectionName(context, entry.key)}: ${entry.value.length} ${S.of(context).documents}',
                          ),
                        ),
                      SizedBox(height: 16.0),
                      Text(
                        "ATENÇÃO: Todos os itens listados acima e quaisquer dependências deles também serão excluídos permanentemente!",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).confirm_deletion),
              ),
            ],
          );
        },
      );

      if (confirmDeleteWithDependencies != true) return;
    }

    final bool? finalConfirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).final_confirmation),
          content: Text(S.of(context).final_confirmation_message(itemName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete_all),
            ),
          ],
        );
      },
    );

    if (finalConfirmation != true) return;

    bool isProdutor = serviceName.baseCollection == 'produtores';
    if (isProdutor) {
      final bool? confirmProdutorDeletion = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              S.of(context).confirm_deletion,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24.0),
            ),
            content: Text(
              S.of(context).produtor_deletion_warning,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24.0),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  S.of(context).delete,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24.0),
                ),
              ),
            ],
          );
        },
      );

      if (confirmProdutorDeletion != true) return;
    }

    try {
      // Mostrar o diálogo de processamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      S.of(context).processing,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Processar estornos necessários antes da exclusão
      if (['compras', 'itensOperacaoRural'].contains(serviceName.baseCollection)) {
        await ProcessamentoEstornosService.processarEstornos(serviceName, itemIdValue);
      }

      // Executar a exclusão
      await serviceName.excluirComDependencias(itemIdValue, serviceName.baseCollection);
      onSuccessDialog();

      // Fechar o diálogo de processamento
      Navigator.of(context).pop();

      // Mostrar SnackBar de sucesso
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).delete_success(itemName)),
        backgroundColor: Colors.green,
      ));

      // Lógica adicional para Produtores
      if (isProdutor) {
        bool isActive = AppStateManager().activeProdutorId == itemIdValue;
        if (isActive) {
          await AppStateManager().setActiveProdutor(null);
          Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
        }
      }
    } catch (e) {
      // Fechar o diálogo de processamento em caso de erro
      Navigator.of(context).pop();

      // Mostrar SnackBar de erro
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).delete_error(itemName, e.toString())),
        backgroundColor: Colors.red,
      ));
    }
  }

}