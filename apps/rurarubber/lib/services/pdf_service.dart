import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/entrega.dart';
import '../models/parceiro.dart';

class PdfService {
  static Future<void> generateAndShareReceipt(
      Entrega entrega, List<Parceiro> parceiros, double precoPorKg) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Recibo de Pesagem - RuraRubber'),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Data: ${dateFormat.format(entrega.data)}'),
              pw.Text('ID: ${entrega.id.substring(0, 8)}'),
              pw.Text('Preço Base: ${currencyFormat.format(precoPorKg)} / kg'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'Parceiro',
                  'Peso Total (kg)',
                  '% Parte',
                  'Valor Repasse'
                ],
                data: entrega.itens.map((item) {
                  final parceiro = parceiros.firstWhere(
                      (p) => p.id == item.parceiroId,
                      orElse: () => Parceiro(
                          id: '?', nome: 'Desconhecido', percentualPadrao: 0));

                  final valorTotal = item.pesoTotal * precoPorKg;
                  final valorRepasse =
                      valorTotal * (parceiro.percentualPadrao / 100);

                  return [
                    parceiro.nome,
                    item.pesoTotal.toStringAsFixed(1),
                    '${parceiro.percentualPadrao.toStringAsFixed(0)}%',
                    currencyFormat.format(valorRepasse),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Peso: ${entrega.pesoTotalGeral.toStringAsFixed(1)} kg',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Venda: ${currencyFormat.format(entrega.pesoTotalGeral * precoPorKg)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text('Gerado automaticamente pelo RuraRubber'),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'romaneio_${entrega.id.substring(0, 6)}.pdf');
  }
}
