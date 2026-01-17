import 'package:flutter/material.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/screens/map_drawing_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TalhaoDialogScreen {
  final String? propriedadeId;
  final TalhaoService talhaoService;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onUpdate;
  final GlobalKey firstTalhaoMoreOptionsKey;
  final GlobalKey firstTalhaoEditKey;
  final GlobalKey firstTalhaoDeleteKey;
  List<Talhao>? temporaryTalhoes;

  TalhaoDialogScreen({
    this.propriedadeId,
    required this.talhaoService,
    required this.canEdit,
    required this.canDelete,
    required this.onUpdate,
    required this.firstTalhaoMoreOptionsKey,
    required this.firstTalhaoEditKey,
    required this.firstTalhaoDeleteKey,
    this.temporaryTalhoes,
  });

  // Método para adicionar um talhão
  // Dentro da classe TalhaoDialogScreen

  Future<bool?> addTalhao(BuildContext context) async {
    final theme = Theme.of(context);
    if (canEdit) {
      final TextEditingController nomeController = TextEditingController();
      final TextEditingController areaController = FormatacaoUtil.getMaskedTextController(0.0);
      List<LatLng> definedCoordinates = []; // Armazenar coordenadas definidas no mapa

      String? propId = propriedadeId; // Assign to local variable

      final bool? result = await ObjectTemplate.showCustomDialog(
        context: context,
        title: S.of(context).add_plot,
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seção de Identificação
                Row(
                  children: [
                    Icon(Icons.edit, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).identification,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Nome
                TextField(
                  controller: nomeController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).name,
                    suffixIcon: Icon(Icons.edit),
                  ),
                ),
                SizedBox(height: 16),

                // Área
                TextField(
                  controller: areaController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).area_ha,
                    suffixIcon: Icon(Icons.area_chart),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24),

                // Seção de Mapa
                Row(
                  children: [
                    Icon(Icons.map, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).coordinates,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Botão de Mapa
                ElevatedButton.icon(
                  onPressed: () async {
                    final mapResult = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapDrawingScreen(
                          talhaoNome: nomeController.text,
                          initialCoordinates: definedCoordinates
                              .map((latLng) => {'lat': latLng.latitude, 'lon': latLng.longitude})
                              .toList(),
                        ),
                      ),
                    );

                    if (mapResult != null && mapResult is Map<String, dynamic>) {
                      setState(() {
                        nomeController.text = mapResult['nome'];
                        definedCoordinates = (mapResult['coordenadas'] as List<Map<String, double>>)
                            .map((coord) => LatLng(coord['lat']!, coord['lon']!))
                            .toList();
                        areaController.text = mapResult['area'].toString();
                      });
                    }
                  },
                  icon: Icon(Icons.map),
                  label: Text(S.of(context).define_plot_on_map),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            );
          },
        ),
        onCancel: () => Navigator.of(context).pop(false),
        onSave: () async {
          final String nome = nomeController.text;
          final double? area = FormatacaoUtil.instance.parseNumber(areaController.text);

          if (nome.isEmpty || area == null || area <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).please_enter_valid_name_and_area),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final talhao = Talhao(
            id: DateTime.now().toString(),
            produtorId: AppStateManager().activeProdutorId!,
            propriedadeId: propId ?? '', // Use local variable
            nome: nome,
            area: area,
            coordenadas: definedCoordinates
                .map((latLng) => {'lat': latLng.latitude, 'lon': latLng.longitude})
                .toList(),
          );

          if (propId == null || propId.isEmpty) {
            // Operar na lista temporária
            temporaryTalhoes?.add(talhao);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).plot_added_temporarily)),
            );
            onUpdate(); // Atualizar a tela
            Navigator.of(context).pop(true); // Retornar sucesso
          } else {
            // Salvar diretamente no banco de dados
            try {
              await talhaoService.add(talhao);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).plot_added_successfully)),
              );
              onUpdate(); // Atualizar a tela
              Navigator.of(context).pop(true); // Retornar sucesso
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).error_adding_plot(e.toString()))),
              );
              Navigator.of(context).pop(false); // Retornar falha
            }
          }
        },
      );

      return result;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_plots),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }


  // Dentro da classe TalhaoDialogScreen

  Future<bool?> editTalhao(BuildContext context, Talhao talhao) async {
    final theme = Theme.of(context);
    if (canEdit) {
      final TextEditingController nomeController = TextEditingController(text: talhao.nome);
      final TextEditingController areaController = FormatacaoUtil.getMaskedTextController(talhao.area);
      String? propId = propriedadeId;

      List<LatLng> polygonLatLngs = talhao.coordenadas != null
          ? talhao.coordenadas!.map((coord) => LatLng(coord['lat']!, coord['lon']!)).toList()
          : [];
      double area = talhao.area;

      final bool? result = await ObjectTemplate.showCustomDialog(
        context: context,
        title: S.of(context).edit_plot,
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seção de Identificação
                Row(
                  children: [
                    Icon(Icons.edit, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).identification,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Nome
                TextFormField(
                  controller: nomeController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).name,
                    suffixIcon: Icon(Icons.edit),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return S.of(context).enter_name;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Área
                TextFormField(
                  controller: areaController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).area_ha,
                    suffixIcon: Icon(Icons.area_chart),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || FormatacaoUtil.instance.parseNumber(value) <= 0) {
                      return S.of(context).enter_area;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Seção de Mapa
                Row(
                  children: [
                    Icon(Icons.map, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).coordinates,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Informação das Coordenadas Atuais
                if (polygonLatLngs.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).coordinates,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${polygonLatLngs.length} ${S.of(context).coordinates}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Botão do Mapa
                ElevatedButton.icon(
                  onPressed: () async {
                    final mapResult = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapDrawingScreen(
                          talhaoNome: nomeController.text,
                          initialCoordinates: polygonLatLngs
                              .map((latLng) => {'lat': latLng.latitude, 'lon': latLng.longitude})
                              .toList(),
                        ),
                      ),
                    );

                    if (mapResult != null && mapResult is Map<String, dynamic>) {
                      setState(() {
                        nomeController.text = mapResult['nome'];
                        polygonLatLngs = (mapResult['coordenadas'] as List<Map<String, double>>)
                            .map((coord) => LatLng(coord['lat']!, coord['lon']!))
                            .toList();
                        area = mapResult['area'];
                        areaController.text = area.toString();
                      });
                    }
                  },
                  icon: Icon(Icons.map),
                  label: Text(S.of(context).define_plot_on_map),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            );
          },
        ),
        onCancel: () => Navigator.of(context).pop(false),
        onSave: () async {
          final String nome = nomeController.text;
          final double? areaValue = FormatacaoUtil.instance.parseNumber(areaController.text);

          if (nome.isEmpty || areaValue == null || areaValue <= 0 || polygonLatLngs.length < 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).please_enter_valid_name_area_and_polygon),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final updatedTalhao = talhao.copyWith(
            nome: nome,
            area: areaValue,
            coordenadas: polygonLatLngs
                .map((latLng) => {'lat': latLng.latitude, 'lon': latLng.longitude})
                .toList(),
          );

          if (propId == null || propId.isEmpty) {
            // Lista temporária
            int index = temporaryTalhoes?.indexWhere((t) => t.id == talhao.id) ?? -1;
            if (index >= 0) {
              temporaryTalhoes![index] = updatedTalhao;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).plot_updated_temporarily)),
              );
              onUpdate();
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).plot_not_found)),
              );
              Navigator.of(context).pop(false);
            }
          } else {
            // Banco de dados
            try {
              await talhaoService.update(updatedTalhao.id, updatedTalhao);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).plot_updated_successfully)),
              );
              onUpdate();
              Navigator.of(context).pop(true);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).error_updating_plot(e.toString()))),
              );
              Navigator.of(context).pop(false);
            }
          }
        },
      );

      return result;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_edit_plots),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }



  // Método para excluir um talhão
  Future<void> deleteTalhao(BuildContext context, Talhao talhao) async {
    if (canDelete) {
      String? propId = propriedadeId; // Assign to local variable

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(S.of(context).plot)),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(S.of(context).delete),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirm ?? false) {
        if (propId == null || propId.isEmpty) {
          // Operate on the temporary list
          temporaryTalhoes?.removeWhere((t) => t.id == talhao.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).plot_deleted_temporarily)),
          );
          onUpdate(); // Update the screen
        } else {
          // Delete from the database
          try {
            await talhaoService.delete(talhao.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).plot_deleted_successfully)),
            );
            onUpdate(); // Update the screen
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).error_deleting_plot(e.toString()))),
            );
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).no_permission_to_delete_plots} ${S.of(context).agricultural_property}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /*
  // Método para construir a seção de talhões
  Widget buildTalhoesSection(BuildContext context) {
    String? propId = propriedadeId; // Assign to local variable
    final GlobalKey _talhoesKey = GlobalKey();

    if (propId == null || propId.isEmpty) {
      // Exibir talhões da lista temporária
      return buildTemporaryTalhoesSection(context);
    } else {
      // Exibir talhões do banco de dados
      return Container(
        key: _talhoesKey,
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                S.of(context).plots,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<List<Talhao>>(
                future: talhaoService.getByAttributes({'propriedadeId': propId}),
                builder: (context, snapshot) {
                  return buildTalhoesCards(context, snapshot);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  // Método para construir a seção de talhões temporários
  Widget buildTemporaryTalhoesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              S.of(context).plots,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: (temporaryTalhoes != null && temporaryTalhoes!.isNotEmpty)
                ? Column(
              children: temporaryTalhoes!.map((talhao) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ExpansionTile(
                    title: Text(
                      '${S.of(context).name}: ${talhao.nome}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    subtitle: Text('${S.of(context).area}: ${talhao.area} ha'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).coordinates,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: talhao.coordenadas!.map((coord) {
                                return Text(
                                  'Lat: ${coord['lat']}, Lon: ${coord['lon']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (String result) {
                        if (result == 'edit') {
                          editTalhao(context, talhao); // Editar na lista temporária
                        } else if (result == 'delete') {
                          deleteTalhao(context, talhao); // Excluir da lista temporária
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(S.of(context).edit, style: Theme.of(context).popupMenuTheme.textStyle),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(S.of(context).delete, style: Theme.of(context).popupMenuTheme.textStyle),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
                : Card(child: ListTile(title: Text(S.of(context).not_found))),
          ),
        ],
      ),
    );
  }

  // Método para construir os cards de talhões do banco de dados
  Widget buildTalhoesCards(BuildContext context, AsyncSnapshot<List<Talhao>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Card(child: ListTile(title: Text(S.of(context).loading)));
    } else if (snapshot.hasError) {
      return Card(child: ListTile(title: Text(S.of(context).error_loading)));
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Card(child: ListTile(title: Text(S.of(context).not_found)));
    } else {
      final List<Talhao> talhoes = snapshot.data!;
      return Column(
        children: talhoes.asMap().entries.map((entry) {
          final int index = entry.key;
          final Talhao talhao = entry.value;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ExpansionTile(
              key: index == 0 ? firstTalhaoMoreOptionsKey : null, // Atribuir GlobalKey ao primeiro ExpansionTile
              title: Text(
                '${S.of(context).name}: ${talhao.nome}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              subtitle: Text(
                '${S.of(context).area}: ${talhao.area} ha',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).coordinates,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: talhao.coordenadas!.map((coord) {
                          return Text(
                            'Lat: ${coord['lat']}, Lon: ${coord['lon']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (String result) {
                  if (result == 'edit') {
                    editTalhao(context, talhao); // Editar no banco de dados
                  } else if (result == 'delete') {
                    deleteTalhao(context, talhao); // Excluir do banco de dados
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    key: index == 0 ? firstTalhaoEditKey : null, // Atribuir GlobalKey ao botão Edit do primeiro talhão
                    child: Text(
                      S.of(context).edit,
                      style: Theme.of(context).popupMenuTheme.textStyle,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    key: index == 0 ? firstTalhaoDeleteKey : null, // Atribuir GlobalKey ao botão Delete do primeiro talhão
                    child: Text(
                      S.of(context).delete,
                      style: Theme.of(context).popupMenuTheme.textStyle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
  }
  */
}
