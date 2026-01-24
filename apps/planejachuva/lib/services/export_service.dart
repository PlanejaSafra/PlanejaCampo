import 'dart:io';

import 'package:agro_core/agro_core.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/registro_chuva.dart';
import 'chuva_service.dart';

/// Export formats available for rainfall records.
enum ExportFormat {
  json,
  csv,
  pdf,
}

/// Service for exporting rainfall records in various formats (PDF, CSV, JSON).
class ExportService {
  static const String _appName = 'PlanejaChuva';
  static const String _appVersion = '1.0.0';

  /// Exports all records in the specified format and shares the file.
  static Future<void> exportar({
    required ExportFormat format,
    required String locale,
  }) async {
    final service = ChuvaService();
    final registros = service.listarTodos();

    if (registros.isEmpty) {
      throw Exception('Nenhum registro para exportar');
    }

    // Sort by date (most recent first)
    registros.sort((a, b) => b.data.compareTo(a.data));

    File file;
    String subject;

    switch (format) {
      case ExportFormat.json:
        throw UnimplementedError('Use BackupService for JSON export');
      case ExportFormat.csv:
        file = await _exportCsv(registros, locale);
        subject = locale.startsWith('pt')
            ? 'Registros de Chuva (CSV)'
            : 'Rainfall Records (CSV)';
        break;
      case ExportFormat.pdf:
        file = await _exportPdf(registros, locale);
        subject = locale.startsWith('pt')
            ? 'Registros de Chuva (PDF)'
            : 'Rainfall Records (PDF)';
        break;
    }

    // Share the file
    final text = locale.startsWith('pt')
        ? 'Exportação de ${registros.length} registros de chuva'
        : 'Export of ${registros.length} rainfall records';

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: text,
    );
  }

  /// Generates a CSV file with all rainfall records.
  static Future<File> _exportCsv(
    List<RegistroChuva> registros,
    String locale,
  ) async {
    final List<List<dynamic>> rows = [];

    // Header row
    if (locale.startsWith('pt')) {
      rows.add([
        'Data',
        'Milímetros (mm)',
        'Propriedade',
        'Talhão', // Added Talhão column
        'Observação',
        'Criado em'
      ]);
    } else {
      rows.add([
        'Date',
        'Millimeters (mm)',
        'Property',
        'Field Plot', // Added Field Plot column
        'Observation',
        'Created at'
      ]);
    }

    // Data rows
    final dateFormat = DateFormat.yMd(locale);
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm', locale);
    final propertyHelper = PropertyHelper();
    final talhaoService = TalhaoService();

    for (final r in registros) {
      final propertyName = propertyHelper.getPropertyName(r.propertyId);
      final talhaoName = r.talhaoId != null
          ? (talhaoService.getById(r.talhaoId!)?.nome ?? '')
          : '';

      rows.add([
        dateFormat.format(r.data),
        r.milimetros.toStringAsFixed(1),
        propertyName,
        talhaoName,
        r.observacao ?? '',
        dateTimeFormat.format(r.criadoEm),
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Write to temp file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/planeja_chuva_$timestamp.csv');
    await file.writeAsString(csvString);

    return file;
  }

  /// Generates a PDF file with all rainfall records.
  static Future<File> _exportPdf(
    List<RegistroChuva> registros,
    String locale,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat.yMd(locale);

    // Calculate statistics
    final total = registros.fold(0.0, (sum, r) => sum + r.milimetros);
    final media = total / registros.length;
    final maior =
        registros.map((r) => r.milimetros).reduce((a, b) => a > b ? a : b);

    // Group by month
    final byMonth = <String, List<RegistroChuva>>{};
    for (final r in registros) {
      final key = DateFormat.yMMMM(locale).format(r.data);
      byMonth.putIfAbsent(key, () => []).add(r);
    }

    // Add cover page with summary
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _appName,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              locale.startsWith('pt')
                  ? 'Relatório de Registros de Chuva'
                  : 'Rainfall Records Report',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${locale.startsWith('pt') ? 'Gerado em' : 'Generated on'}: ${DateFormat('dd/MM/yyyy HH:mm', locale).format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            // Statistics
            pw.Text(
              locale.startsWith('pt')
                  ? 'Resumo Estatístico'
                  : 'Statistical Summary',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildStatRow(
              locale.startsWith('pt')
                  ? 'Total de registros:'
                  : 'Total records:',
              '${registros.length}',
            ),
            _buildStatRow(
              locale.startsWith('pt')
                  ? 'Total acumulado:'
                  : 'Total accumulated:',
              '${total.toStringAsFixed(1)} mm',
            ),
            _buildStatRow(
              locale.startsWith('pt')
                  ? 'Média por chuva:'
                  : 'Average per rainfall:',
              '${media.toStringAsFixed(1)} mm',
            ),
            _buildStatRow(
              locale.startsWith('pt') ? 'Maior registro:' : 'Highest record:',
              '${maior.toStringAsFixed(1)} mm',
            ),
            pw.SizedBox(height: 20),
            // Monthly breakdown
            pw.Text(
              locale.startsWith('pt') ? 'Totais Mensais' : 'Monthly Totals',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            ...byMonth.entries.map((entry) {
              final monthTotal =
                  entry.value.fold(0.0, (sum, r) => sum + r.milimetros);
              return _buildStatRow(
                '${entry.key}:',
                '${monthTotal.toStringAsFixed(1)} mm (${entry.value.length} ${locale.startsWith('pt') ? 'chuvas' : 'rainfalls'})',
              );
            }).toList(),
          ],
        ),
      ),
    );

    // Add detailed records pages
    final chunks = _chunkList(registros, 30); // 30 records per page
    for (var i = 0; i < chunks.length; i++) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                locale.startsWith('pt')
                    ? 'Registros Detalhados (página ${i + 1}/${chunks.length})'
                    : 'Detailed Records (page ${i + 1}/${chunks.length})',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Date
                  1: const pw.FlexColumnWidth(1.5), // mm
                  2: const pw.FlexColumnWidth(2.5), // Property
                  3: const pw.FlexColumnWidth(2), // Talhão
                  4: const pw.FlexColumnWidth(3), // Observation
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildTableCell(
                        locale.startsWith('pt') ? 'Data' : 'Date',
                        bold: true,
                      ),
                      _buildTableCell(
                        locale.startsWith('pt') ? 'mm' : 'mm',
                        bold: true,
                      ),
                      _buildTableCell(
                        locale.startsWith('pt') ? 'Propriedade' : 'Property',
                        bold: true,
                      ),
                      _buildTableCell(
                        locale.startsWith('pt') ? 'Talhão' : 'Field Plot',
                        bold: true,
                      ),
                      _buildTableCell(
                        locale.startsWith('pt') ? 'Observação' : 'Observation',
                        bold: true,
                      ),
                    ],
                  ),
                  // Data rows
                  ...chunks[i].map((r) {
                    final propertyName =
                        PropertyHelper().getPropertyName(r.propertyId);
                    final talhaoName = r.talhaoId != null
                        ? (TalhaoService().getById(r.talhaoId!)?.nome ?? '')
                        : '';

                    return pw.TableRow(
                      children: [
                        _buildTableCell(dateFormat.format(r.data)),
                        _buildTableCell(r.milimetros.toStringAsFixed(1)),
                        _buildTableCell(propertyName),
                        _buildTableCell(talhaoName),
                        _buildTableCell(r.observacao ?? ''),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.Spacer(),
              pw.Text(
                '$_appName v$_appVersion',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Write to temp file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/planeja_chuva_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Builds a statistic row for PDF.
  static pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  /// Builds a table cell for PDF.
  static pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Splits a list into chunks of specified size.
  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
            i, i + chunkSize > list.length ? list.length : i + chunkSize),
      );
    }
    return chunks;
  }
}
