import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/extension_themes.dart';
import 'package:planejacampo/themes.dart';

class ObjectTemplate {
  const ObjectTemplate({Key? key});

  static Card getCardWithTile({
    required BuildContext context,
    required Widget title,
    Widget? subtitle,
    Color? tileColor,
  }) {
    ThemeData theme = Theme.of(context);
    return Card(
      color: theme.cardColor, // Utiliza a cor padrão do tema, se disponível
      elevation: theme.cardTheme.elevation,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        tileColor: tileColor ?? theme.listTileTheme.tileColor, // Define a cor do tile
      ),
    );
  }

  static String capitalizeWords(String value) {
    return value.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).join(' ');
  }

  static List<DropdownMenuItem<T>> getDropdownMenuItems<T>(BuildContext context, List<T> items) {
    return items.map<DropdownMenuItem<T>>((T value) {
      return DropdownMenuItem<T>(
        value: value,
        child: Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }).toList();
  }

  static DropdownButtonFormField<String> getDropdownButtonFormField({
    required BuildContext context,
    required String labelText,
    String? value,
    List<String>? items,
    List<DropdownMenuItem<String>>? dropdownItems,
    required void Function(String?) onChanged,
    FormFieldValidator<String>? validator,
    TextStyle? style,
    Color? dropdownColor,
    GlobalKey<FormFieldState>? key,
    Widget? suffixIcon,
    void Function(String?)? onSaved,
    Widget? hint,
    List<Widget> Function(BuildContext)? selectedItemBuilder, // Novo parâmetro
  }) {
    assert(items != null || dropdownItems != null, 'Either items or dropdownItems must be provided');

    List<DropdownMenuItem<String>> finalItems;
    if (dropdownItems != null) {
      finalItems = dropdownItems;
    } else {
      finalItems = getDropdownMenuItems(context, items!);
    }

    return DropdownButtonFormField<String>(
      key: key,
      decoration: getInputDecoration(context, labelText, suffixIcon: suffixIcon),
      value: (value == null || value.isEmpty) ? null : value,
      onChanged: onChanged,
      onSaved: onSaved,
      items: finalItems,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
      dropdownColor: dropdownColor ?? Theme.of(context).cardColor,
      validator: validator,
      hint: hint,
      selectedItemBuilder: selectedItemBuilder, // Adicionado o parâmetro
    );
  }

  static Future<bool?> showCustomDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    VoidCallback? onDelete,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16), // Ajuste de padding para ícone de delete
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: content,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancelar'),
              onPressed: onCancel,
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: onSave,
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
        );
      },
    );
  }

  static List<Widget> getDialogActions({
    required BuildContext context,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    bool showSaveButton = true,
  }) {
    return <Widget>[
      ElevatedButton(
        child: const Text('Cancelar'),
        onPressed: onCancel,
      ),
      if (showSaveButton)
        ElevatedButton(
          child: const Text('Salvar'),
          onPressed: onSave,
        ),
    ];
  }

  static InputDecoration getInputDecoration(
    BuildContext context,
    String labelText, {
    Widget? suffixIcon, // Adiciona o parâmetro opcional suffixIcon
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
      border: const UnderlineInputBorder(),
      suffixIcon: suffixIcon, // Usa o suffixIcon passado ou null
    );
  }

  static TargetFocus getTutorialTarget({
    required String identify,
    required String description,
    GlobalKey? keyTarget,
    TargetPosition? targetPosition,
    ShapeLightFocus shape = ShapeLightFocus.Circle,
    double radius = 8.0,
    ContentAlign align = ContentAlign.bottom,
    double focusPadding = 10.0,
    double textPadding = 20.0,
    double? fatorReducaoQuadro, // Novo parâmetro opcional para reduzir o quadro
  }) {
    // Se fatorReducaoQuadro for fornecido e keyTarget estiver disponível, calcula o tamanho e posição manualmente
    TargetPosition? customTargetPosition = targetPosition;

    if (fatorReducaoQuadro != null && keyTarget != null) {
      final RenderBox renderBox = keyTarget.currentContext?.findRenderObject() as RenderBox;
      final Size size = renderBox.size; // Tamanho do widget
      final Offset offset = renderBox.localToGlobal(Offset.zero); // Posição do widget na tela

      // Cria uma nova TargetPosition com o fator de redução aplicado
      customTargetPosition = TargetPosition(
        Size(
          size.width, // Mantém a largura original
          size.height * fatorReducaoQuadro, // Aplica o fator de redução na altura
        ),
        Offset(
          offset.dx, // Mantém a posição horizontal
          offset.dy, // Mantém a posição vertical
        ),
      );
    }

    return TargetFocus(
      identify: identify,
      keyTarget: customTargetPosition == null ? keyTarget : null,
      targetPosition: customTargetPosition ?? targetPosition, // Usa a posição calculada ou a original
      shape: shape,
      radius: radius,
      paddingFocus: focusPadding, // Aumenta ou diminui o tamanho do foco
      contents: [
        TargetContent(
          align: align,
          child: Padding(
            padding: EdgeInsets.only(top: textPadding),
            child: Text(
              description,
              style: AppThemes.tutorialTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static ShapeLightFocus getShapeFromString(String? shape) {
    switch (shape) {
      case 'Circle':
        return ShapeLightFocus.Circle;
      case 'RRect':
        return ShapeLightFocus.RRect;
      default:
        return ShapeLightFocus.Circle;
    }
  }

  static ContentAlign getAlignFromString(String? align) {
    switch (align) {
      case 'ContentAlign.top':
        return ContentAlign.top;
      case 'ContentAlign.left':
        return ContentAlign.left;
      case 'ContentAlign.right':
        return ContentAlign.right;
      case 'ContentAlign.bottom':
      default:
        return ContentAlign.bottom;
    }
  }

  static Widget buildCustomFloatingActionButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    Key? key,
    String? heroTag,
    String? toolTip,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          child: Text(text),
        ),
        SizedBox(width: 8),
        FloatingActionButton(
          key: key,
          onPressed: onPressed,
          child: Icon(icon),
          mini: true,
          heroTag: heroTag,
          tooltip: toolTip,
        ),
      ],
    );
  }

  static Widget buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    double labelWidthPercent = 0.35, // Percentual de largura para o rótulo
    bool valueBelowLabel = false, // Novo parâmetro opcional
    GlobalKey? key,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Combina o label e o value para verificar se cabem em uma linha
                final combinedText = '$label: $value';

                // Utiliza os estilos de texto definidos no tema
                final labelStyle = Theme.of(context).textTheme.titleMedium;
                final valueStyle = Theme.of(context).textTheme.bodyMedium;

                // Cria um TextSpan que combina o label e o valor com seus estilos
                final textSpan = TextSpan(
                  children: [
                    TextSpan(text: '$label: ', style: labelStyle),
                    TextSpan(text: value, style: valueStyle),
                  ],
                );

                // Mede o tamanho do texto combinado
                final textPainter = TextPainter(
                  text: textSpan,
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                );
                textPainter.layout(maxWidth: constraints.maxWidth);

                // Verifica se o texto excede a largura disponível
                final textExceeds = textPainter.didExceedMaxLines;

                if (valueBelowLabel || textExceeds) {
                  // Exibe o label e o valor em uma coluna
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label:',
                        style: labelStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: valueStyle,
                      ),
                    ],
                  );
                } else {
                  // Exibe o label e o valor em uma linha, permitindo que o valor quebre para a próxima linha
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rótulo com largura fixa proporcional para alinhamento
                      SizedBox(
                        width: MediaQuery.of(context).size.width * labelWidthPercent,
                        child: Text(
                          '$label:',
                          style: labelStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Valor que ocupa o espaço restante e permite quebra de linha
                      Expanded(
                        child: Text(
                          value,
                          style: valueStyle,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCardSection(CardSection section, ThemeData theme) {
    return Container(
      key: section.key,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.title != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (section.icon != null)
                      Icon(
                        section.icon,
                        color: theme.colorScheme.primary,
                      ),
                    if (section.icon != null) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        section.title!,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: section.cards
                    .map((card) => Card(
                          child: card,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma CardSection com um FutureBuilder.
  ///
  /// [key] - Chave global para a seção.
  /// [title] - Título da seção.
  /// [iconePrincipal] - Ícone representativo da seção.
  /// [future] - Future que retorna uma lista de itens.
  /// [itemTitle] - Função que retorna o título de cada item.
  /// [itemSubtitle] - Função que retorna o subtítulo de cada item.
  /// [onEdit] - Função chamada ao selecionar "editar" para um item.
  /// [onDelete] - Função chamada ao selecionar "excluir" para um item.
  /// [itemLeadingIcon] - Ícone opcional para cada ListTile.
  /// [loadingText] - Texto exibido durante o carregamento.
  /// [errorText] - Texto exibido em caso de erro.
  /// [notFoundText] - Texto exibido quando nenhum item é encontrado.
  static CardSection buildCardSectionWithFuture<T>({
    required GlobalKey key,
    required String title,
    required IconData iconePrincipal,
    required Future<List<T>> future,
    required String Function(T item) itemTitle,
    required Widget Function(T item) itemSubtitle,
    void Function(T item)? onEdit,
    void Function(T item)? onDelete,
    IconData? itemLeadingIcon,
    String? loadingText,
    String? errorText,
    String? notFoundText,
    GlobalKey? firstItemMoreOptionsKey,
    Widget Function(T item, int index)? itemTrailing, // Já existente
    BoxDecoration Function(T item)? cardDecoration, // Novo parâmetro
  }) {
    return CardSection(
      key: key,
      title: title,
      icon: iconePrincipal,
      cards: [
        FutureBuilder<List<T>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                leading: const CircularProgressIndicator(),
                title: Text(loadingText ?? S.of(context).loading),
              );
            } else if (snapshot.hasError) {
              return ListTile(
                leading: Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(errorText ?? S.of(context).error_loading),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(notFoundText ?? S.of(context).not_found),
              );
            } else {
              return Column(
                children: snapshot.data!.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final T item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      decoration: cardDecoration != null ? cardDecoration(item) : null,
                      child: ListTile(
                        leading: itemLeadingIcon != null
                            ? Icon(
                                itemLeadingIcon,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        title: Text(
                          itemTitle(item),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        subtitle: itemSubtitle(item),
                        trailing: itemTrailing != null
                            ? itemTrailing(item, index)
                            : PopupMenuButton<String>(
                                key: index == 0 ? firstItemMoreOptionsKey : null,
                                onSelected: (value) {
                                  if (value == 'edit' && onEdit != null) {
                                    onEdit(item);
                                  } else if (value == 'delete' && onDelete != null) {
                                    onDelete(item);
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  if (onEdit != null)
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text(
                                        S.of(context).edit,
                                        style: Theme.of(context).popupMenuTheme.textStyle,
                                      ),
                                    ),
                                  if (onDelete != null)
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text(
                                        S.of(context).delete,
                                        style: Theme.of(context).popupMenuTheme.textStyle,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  static Widget buildCardSectionWithFutureCustom<T>({
    String? subTitle, // Tornar o título opcional
    required IconData icon,
    required Future<List<T>> future,
    required String Function(T item) itemTitle,
    required Widget Function(T item) itemSubtitle,
    required void Function(T item) onTap,
    bool Function(T item)? canEdit,
    bool Function(T item)? canDelete,
    void Function(T item)? onEdit,
    void Function(T item)? onDelete,
    bool isSelectMode = false,
    bool isSetMode = false,
    void Function(T item)? onSetMode,
    IconData? itemLeadingIcon,
    String? loadingText,
    String? errorText,
    String? notFoundText,
    List<Widget> Function(T item)? itemExpandedContentWidgets,
    ScrollController? scrollController, // Adiciona ScrollController
    GlobalKey? listViewKey, // Adiciona GlobalKey
    GlobalKey? firstItemCardKey,
    GlobalKey<PopupMenuButtonState<String>>? firstItemMoreOptionsKey,
    GlobalKey? firstItemViewKey,
    GlobalKey? firstItemEditKey,
    GlobalKey? firstItemDeleteKey,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(loadingText ?? S.of(context).loading),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            leading: Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(errorText ?? S.of(context).error_loading),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ListTile(
            leading: Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(notFoundText ?? S.of(context).not_found),
          );
        } else {
          return ListView.builder(
            key: listViewKey,
            controller: scrollController,
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(), // <-- Nova configuração
            itemCount: snapshot.data!.length + (subTitle != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (subTitle != null && index == 0) {
                return ListTile(
                  leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(
                    subTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              final T item = snapshot.data![index - (subTitle != null ? 1 : 0)];
              return Card(
                key: index == 0 ? firstItemCardKey : null,
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ExpansionTile(
                  leading: itemLeadingIcon != null
                      ? Icon(
                          itemLeadingIcon,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  title: Text(
                    itemTitle(item),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  subtitle: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: itemSubtitle(item),
                  ),
                  children: itemExpandedContentWidgets != null
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: itemExpandedContentWidgets(item),
                            ),
                          ),
                        ]
                      : [],
                  trailing: isSelectMode
                      ? IconButton(
                          key: index == 0 ? firstItemMoreOptionsKey : null,
                          onPressed: () {
                            if (isSetMode || onSetMode != null) {
                              onSetMode!(item);
                            }
                            Navigator.of(context).pop(item);
                          },
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        )
                      : PopupMenuButton<String>(
                          key: index == 0 ? firstItemMoreOptionsKey : null,
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onSelected: (value) {
                            if (value == 'view') {
                              onTap(item);
                            } else if (value == 'edit' && onEdit != null && (canEdit?.call(item) ?? false)) {
                              onEdit(item);
                            } else if (value == 'delete' && onDelete != null && (canDelete?.call(item) ?? false)) {
                              onDelete(item);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'view',
                              child: Text(
                                key: index == 0 ? firstItemViewKey : null,
                                S.of(context).details,
                                style: Theme.of(context).popupMenuTheme.textStyle,
                              ),
                            ),
                            if (onEdit != null && (canEdit?.call(item) ?? false))
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(
                                  key: index == 0 ? firstItemEditKey : null,
                                  S.of(context).edit,
                                  style: Theme.of(context).popupMenuTheme.textStyle,
                                ),
                              ),
                            if (onDelete != null && (canDelete?.call(item) ?? false))
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(
                                  key: index == 0 ? firstItemDeleteKey : null,
                                  S.of(context).delete,
                                  style: Theme.of(context).popupMenuTheme.textStyle,
                                ),
                              ),
                          ],
                        ),
                ),
              );
            },
          );
        }
      },
    );
  }

  static Widget buildFormSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Key? key,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: key, // Adicionando a key aqui
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
