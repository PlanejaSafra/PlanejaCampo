import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/lancamento.dart';
import '../services/lancamento_service.dart';
import '../services/centro_custo_service.dart';
import '../widgets/cash_drawer.dart';

/// Home screen showing expense list and monthly total.
class CashHomeScreen extends StatelessWidget {
  const CashHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final agroL10n = AgroLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: l10n.currencySymbol,
      decimalDigits: 2,
    );

    return Consumer<LancamentoService>(
      builder: (context, service, _) {
        final currentFarm = FarmService.instance.getDefaultFarm();
        final isPersonal = currentFarm?.type == FarmType.personal;

        final lancamentos = service.lancamentosDoMes;
        final total = service.totalDoMes;

        return Scaffold(
          appBar: AppBar(
            title: Text(isPersonal
                ? (currentFarm?.name ?? agroL10n.farmDefaultNamePersonal)
                : l10n.homeTitle),
            actions: [
              PopupMenuButton<FarmType>(
                icon: Icon(isPersonal ? Icons.person : Icons.agriculture),
                tooltip: l10n.contextSwitcherTooltip,
                onSelected: (type) => _switchContext(context, type),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: FarmType.agro,
                    child: Row(
                      children: [
                        const Icon(Icons.agriculture, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(agroL10n.farmTypeAgro),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: FarmType.personal,
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(agroL10n.farmTypePersonal),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          drawer: buildCashDrawer(context: context, l10n: l10n),
          body: Column(
            children: [
              // Monthly Total Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPersonal
                        ? [
                            const Color(0xFF1976D2),
                            const Color(0xFF42A5F5)
                          ] // Blue for Personal
                        : [
                            const Color(0xFF2E7D32),
                            const Color(0xFF43A047)
                          ], // Green for Agro
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.homeTotal,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMM('pt_BR').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Expense List
              Expanded(
                child: lancamentos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.homeEmpty,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.homeAddFirst,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: lancamentos.length,
                        itemBuilder: (context, index) {
                          final lancamento = lancamentos[index];
                          return _LancamentoTile(
                            lancamento: lancamento,
                            currencyFormat: currencyFormat,
                            l10n: l10n,
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/calculator');
            },
            backgroundColor: isPersonal ? Colors.blue : Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _switchContext(BuildContext context, FarmType type) async {
    final current = FarmService.instance.getDefaultFarm()?.type;
    if (current == type) return;

    try {
      final agroL10n = AgroLocalizations.of(context);
      if (type == FarmType.personal) {
        final farm = await FarmService.instance.createPersonalFarm(
          l10n: agroL10n,
        );
        await FarmService.instance.setAsDefault(farm.id);
      } else {
        // Switch to Agro
        final agroFarms = FarmService.instance.getFarmsByType(FarmType.agro);
        if (agroFarms.isNotEmpty) {
          await FarmService.instance.setAsDefault(agroFarms.first.id);
        } else {
          // Fallback: Create generic agro farm if none exists (unlikely)
          final farm = await FarmService.instance.createFarm(
            name: agroL10n?.farmDefaultName ?? 'My Farm',
            isDefault: true,
          );
          await FarmService.instance.setAsDefault(farm.id);
        }
      }

      // Notify UI
      await CentroCustoService.instance.ensureDefaultCentroCusto();
      LancamentoService.instance.forceUpdate();
    } catch (e) {
      if (context.mounted) {
        final l10n = CashLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.contextSwitchError(e.toString()) ?? e.toString())),
        );
      }
    }
  }
}

class _LancamentoTile extends StatelessWidget {
  final Lancamento lancamento;
  final NumberFormat currencyFormat;
  final CashLocalizations l10n;

  const _LancamentoTile({
    required this.lancamento,
    required this.currencyFormat,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM', 'pt_BR');
    final isToday = _isToday(lancamento.data);
    final isYesterday = _isYesterday(lancamento.data);

    String dateLabel;
    if (isToday) {
      dateLabel = l10n.hoje;
    } else if (isYesterday) {
      dateLabel = l10n.ontem;
    } else {
      dateLabel = dateFormat.format(lancamento.data);
    }

    return Dismissible(
      key: Key(lancamento.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.despesaDeleteTitle),
            content: Text(l10n.despesaDeleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.despesaDeleteCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.despesaDeleteConfirm),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        LancamentoService.instance.deleteLancamento(lancamento.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.despesaDeleted)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: lancamento.categoria.color.withValues(alpha: 0.15),
            child: Icon(
              lancamento.categoria.icon,
              color: lancamento.categoria.color,
              size: 20,
            ),
          ),
          title: Text(
            lancamento.categoria.localizedName(l10n),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: lancamento.descricao != null
              ? Text(
                  lancamento.descricao!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(lancamento.valor),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
