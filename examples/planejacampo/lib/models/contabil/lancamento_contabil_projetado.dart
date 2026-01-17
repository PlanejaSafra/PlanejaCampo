import 'package:cloud_firestore/cloud_firestore.dart';

class LancamentoContabilProjetado {
  final String id;
  final String produtorId;
  final DateTime data;
  final String contaContabilId;
  final String tipo;
  final double valor;
  final double saldoProjetado; // Novo atributo adicionado
  final String origemId;
  final String origemTipo;
  final String categoria;
  final String? descricao;
  final bool ativo;
  final String? loteId;
  final DateTime timestampLocal;
  final String deviceId;
  final String statusProcessamento;
  final String? idLancamentoReal;
  final String? idLancamentoAnterior; // Já existente
  final DateTime? dataProcessamento;
  final String? erroProcessamento;

  LancamentoContabilProjetado({
    required this.id,
    required this.produtorId,
    required this.data,
    required this.contaContabilId,
    required this.tipo,
    required this.valor,
    required this.saldoProjetado,
    required this.origemId,
    required this.origemTipo,
    required this.categoria,
    this.descricao,
    required this.ativo,
    this.loteId,
    required this.timestampLocal,
    required this.deviceId,
    required this.statusProcessamento,
    this.idLancamentoReal,
    this.idLancamentoAnterior, // Já existente
    this.dataProcessamento,
    this.erroProcessamento,
  });

  factory LancamentoContabilProjetado.fromMap(Map<String, dynamic> map, String documentId) {
    return LancamentoContabilProjetado(
      id: documentId,
      produtorId: map['produtorId'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      contaContabilId: map['contaContabilId'] ?? '',
      tipo: map['tipo'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      saldoProjetado: (map['saldoProjetado'] ?? 0.0).toDouble(), // Novo atributo adicionado
      origemId: map['origemId'] ?? '',
      origemTipo: map['origemTipo'] ?? '',
      categoria: map['categoria'] ?? '',
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      loteId: map['loteId'],
      timestampLocal: (map['timestampLocal'] as Timestamp).toDate(),
      deviceId: map['deviceId'] ?? '',
      statusProcessamento: map['statusProcessamento'] ?? 'pendente',
      idLancamentoReal: map['idLancamentoReal'],
      idLancamentoAnterior: map['idLancamentoAnterior'],
      dataProcessamento: map['dataProcessamento'] != null
          ? (map['dataProcessamento'] as Timestamp).toDate()
          : null,
      erroProcessamento: map['erroProcessamento'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'data': Timestamp.fromDate(data),
      'contaContabilId': contaContabilId,
      'tipo': tipo,
      'valor': valor,
      'saldoProjetado': saldoProjetado, // Novo atributo adicionado
      'origemId': origemId,
      'origemTipo': origemTipo,
      'categoria': categoria,
      'descricao': descricao,
      'ativo': ativo,
      'loteId': loteId,
      'timestampLocal': Timestamp.fromDate(timestampLocal),
      'deviceId': deviceId,
      'statusProcessamento': statusProcessamento,
      'idLancamentoReal': idLancamentoReal,
      'idLancamentoAnterior': idLancamentoAnterior,
      'dataProcessamento': dataProcessamento != null
          ? Timestamp.fromDate(dataProcessamento!)
          : null,
      'erroProcessamento': erroProcessamento,
    };
  }

  LancamentoContabilProjetado copyWith({
    String? id,
    String? produtorId,
    DateTime? data,
    String? contaContabilId,
    String? tipo,
    double? valor,
    double? saldoProjetado, // Novo atributo adicionado
    String? origemId,
    String? origemTipo,
    String? categoria,
    String? descricao,
    bool? ativo,
    String? loteId,
    DateTime? timestampLocal,
    String? deviceId,
    String? statusProcessamento,
    String? idLancamentoReal,
    String? idLancamentoAnterior,
    DateTime? dataProcessamento,
    String? erroProcessamento,
  }) {
    return LancamentoContabilProjetado(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      data: data ?? this.data,
      contaContabilId: contaContabilId ?? this.contaContabilId,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      saldoProjetado: saldoProjetado ?? this.saldoProjetado, // Novo atributo adicionado
      origemId: origemId ?? this.origemId,
      origemTipo: origemTipo ?? this.origemTipo,
      categoria: categoria ?? this.categoria,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      loteId: loteId ?? this.loteId,
      timestampLocal: timestampLocal ?? this.timestampLocal,
      deviceId: deviceId ?? this.deviceId,
      statusProcessamento: statusProcessamento ?? this.statusProcessamento,
      idLancamentoReal: idLancamentoReal ?? this.idLancamentoReal,
      idLancamentoAnterior: idLancamentoAnterior ?? this.idLancamentoAnterior,
      dataProcessamento: dataProcessamento ?? this.dataProcessamento,
      erroProcessamento: erroProcessamento ?? this.erroProcessamento,
    );
  }
}
