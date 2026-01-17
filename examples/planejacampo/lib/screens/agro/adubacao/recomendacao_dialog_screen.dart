import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_calagem_form_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_gessagem_form_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_nutriente_form_screen.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_calagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_gessagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_nutriente_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';

class RecomendacaoDialogScreen {
  final String? recomendacaoId;
  final RecomendacaoCalagemService calagemService;
  final RecomendacaoGessagemService gessagemService;
  final RecomendacaoNutrienteService nutrienteService;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onUpdate;
  final ResultadoAnaliseSolo? analise;
  final TipoCultura? tipoCultura;

  RecomendacaoDialogScreen({
    this.recomendacaoId,
    required this.calagemService,
    required this.gessagemService,
    required this.nutrienteService,
    required this.canEdit,
    required this.canDelete,
    required this.onUpdate,
    this.analise,
    this.tipoCultura,
  });

  // Método para verificar permissões de edição com o AppStateManager
  bool _checkEditPermission(BuildContext context) {
    if (!canEdit) {
      return false;
    }
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    return appStateManager.canEdit('recomendacoesAdubacao');
  }

  // Método para verificar permissões de exclusão com o AppStateManager
  bool _checkDeletePermission(BuildContext context) {
    if (!canDelete) {
      return false;
    }
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    return appStateManager.canDelete('recomendacoesAdubacao');
  }

  // Método para adicionar recomendação de calagem utilizando dialog
  Future<bool?> addCalagem(BuildContext context) async {
    if (!_checkEditPermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_liming),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (recomendacaoId == null || recomendacaoId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).save_recommendation_first)),
      );
      return false;
    }

    final RecomendacaoCalagem? result = await showDialog<RecomendacaoCalagem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: RecomendacaoCalagemFormScreen(
            recomendacaoId: recomendacaoId!,
            analise: analise,
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        await calagemService.add(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).liming_recommendation_added_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_saving_liming(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para editar recomendação de calagem
  Future<bool?> editCalagem(BuildContext context, RecomendacaoCalagem calagem) async {
    if (!_checkEditPermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_edit_liming),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final RecomendacaoCalagem? result = await showDialog<RecomendacaoCalagem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: RecomendacaoCalagemFormScreen(
            recomendacaoId: calagem.recomendacaoId,
            calagem: calagem,
            analise: analise,
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        await calagemService.update(calagem.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).liming_recommendation_updated_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_updating_liming(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para excluir recomendação de calagem
  Future<bool?> deleteCalagem(BuildContext context, RecomendacaoCalagem calagem) async {
    if (!_checkDeletePermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_delete_liming),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).confirm_deletion),
        content: Text(S.of(context).confirm_deletion_message(S.of(context).liming_recommendation)),
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
      try {
        await calagemService.delete(calagem.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).liming_recommendation_deleted_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_deleting_liming(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para adicionar recomendação de gessagem
  Future<bool?> addGessagem(BuildContext context) async {
    if (!_checkEditPermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_gypsum),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (recomendacaoId == null || recomendacaoId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).save_recommendation_first)),
      );
      return false;
    }

    final RecomendacaoGessagem? result = await showDialog<RecomendacaoGessagem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: RecomendacaoGessagemFormScreen(
            recomendacaoId: recomendacaoId!,
            analise: analise,
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        await gessagemService.add(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).gypsum_recommendation_added_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_saving_gypsum(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para editar recomendação de gessagem
  Future<bool?> editGessagem(BuildContext context, RecomendacaoGessagem gessagem) async {
    if (!_checkEditPermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_edit_gypsum),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final RecomendacaoGessagem? result = await showDialog<RecomendacaoGessagem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: RecomendacaoGessagemFormScreen(
            recomendacaoId: gessagem.recomendacaoId,
            gessagem: gessagem,
            analise: analise,
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        await gessagemService.update(gessagem.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).gypsum_recommendation_updated_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_updating_gypsum(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para excluir recomendação de gessagem
  Future<bool?> deleteGessagem(BuildContext context, RecomendacaoGessagem gessagem) async {
    if (!_checkDeletePermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_delete_gypsum),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).confirm_deletion),
        content: Text(S.of(context).confirm_deletion_message(S.of(context).gypsum_recommendation)),
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
      try {
        await gessagemService.delete(gessagem.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).gypsum_recommendation_deleted_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_deleting_gypsum(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para adicionar recomendação de nutriente
  Future<bool?> addNutriente(BuildContext context) async {
    if (!_checkEditPermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_nutrient),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (recomendacaoId == null || recomendacaoId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).save_recommendation_first)),
      );
      return false;
    }

    final RecomendacaoNutriente? result = await showDialog<RecomendacaoNutriente>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: RecomendacaoNutrienteFormScreen(
            recomendacaoId: recomendacaoId!,
            analise: analise,
            tipoCultura: tipoCultura,
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        await nutrienteService.add(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).nutrient_recommendation_added_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_saving_nutrient(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para editar recomendação de nutriente
  Future<bool?> editNutriente(BuildContext context, RecomendacaoNutriente nutriente) async {
    if (!_checkEditPermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_edit_nutrient),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final RecomendacaoNutriente? result = await showDialog<RecomendacaoNutriente>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: RecomendacaoNutrienteFormScreen(
            recomendacaoId: nutriente.recomendacaoId,
            nutriente: nutriente,
            analise: analise,
            tipoCultura: tipoCultura,
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        await nutrienteService.update(nutriente.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).nutrient_recommendation_updated_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_updating_nutrient(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  // Método para excluir recomendação de nutriente
  Future<bool?> deleteNutriente(BuildContext context, RecomendacaoNutriente nutriente) async {
    if (!_checkDeletePermission(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_delete_nutrient),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).confirm_deletion),
        content: Text(S.of(context).confirm_deletion_message(S.of(context).nutrient_recommendation)),
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
      try {
        await nutrienteService.delete(nutriente.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).nutrient_recommendation_deleted_successfully)),
        );
        onUpdate();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_deleting_nutrient(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }
}