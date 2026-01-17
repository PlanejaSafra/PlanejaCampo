import 'package:cloud_firestore/cloud_firestore.dart';

class MovimentacaoEstoqueProjetada {
  final String id;
  final String propriedadeId;
  final String itemId;
  final String produtorId;
  final double quantidade;
  final double valorUnitario;
  final String tipo;
  final String categoria;
  final DateTime data;
  final DateTime timestampLocal;
  final String unidadeMedida;
  final double saldoProjetado;
  final double cmpProjetado;
  final String unidadeMedidaCMP;
  final String origemId;
  final String origemTipo;
  final bool ativo;
  final String deviceId;                    // Identifica o dispositivo que gerou
  final String statusProcessamento;         // 'pendente', 'em_processamento', 'processado', 'erro'
  final String? idMovimentacaoReal;         // ID da movimentação real após processada
  final Map<String, dynamic>? dadosOriginais; // Para casos de estorno/alteração
  final DateTime? dataProcessamento;        // Quando foi processada
  final String? erroProcessamento;          // Detalhes em caso de erro

  MovimentacaoEstoqueProjetada({
    required this.id,
    required this.propriedadeId,
    required this.itemId,
    required this.produtorId,
    required this.quantidade,
    required this.valorUnitario,
    required this.tipo,
    required this.categoria,
    required this.data,
    required this.timestampLocal,
    required this.unidadeMedida,
    required this.saldoProjetado,
    required this.cmpProjetado,
    required this.unidadeMedidaCMP,
    required this.origemId,
    required this.origemTipo,
    required this.ativo,
    required this.deviceId,
    required this.statusProcessamento,
    this.idMovimentacaoReal,
    this.dadosOriginais,
    this.dataProcessamento,
    this.erroProcessamento,
  });

  factory MovimentacaoEstoqueProjetada.fromMap(Map<String, dynamic> map, String id) {
    return MovimentacaoEstoqueProjetada(
      id: id,
      propriedadeId: map['propriedadeId'] ?? '',
      itemId: map['itemId'] ?? '',
      produtorId: map['produtorId'] ?? '',
      quantidade: (map['quantidade'] ?? 0.0).toDouble(),
      valorUnitario: (map['valorUnitario'] ?? 0.0).toDouble(),
      tipo: map['tipo'] ?? '',
      categoria: map['categoria'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      timestampLocal: (map['timestampLocal'] as Timestamp).toDate(),
      unidadeMedida: map['unidadeMedida'] ?? '',
      saldoProjetado: (map['saldoProjetado'] ?? 0.0).toDouble(),
      cmpProjetado: (map['cmpProjetado'] ?? 0.0).toDouble(),
      unidadeMedidaCMP: map['unidadeMedidaCMP'] ?? '',
      origemId: map['origemId'] ?? '',
      origemTipo: map['origemTipo'] ?? '',
      ativo: map['ativo'] ?? false,
      deviceId: map['deviceId'] ?? '',
      statusProcessamento: map['statusProcessamento'] ?? 'pendente',
      idMovimentacaoReal: map['idMovimentacaoReal'],
      dadosOriginais: map['dadosOriginais'],
      dataProcessamento: map['dataProcessamento'] != null
          ? (map['dataProcessamento'] as Timestamp).toDate()
          : null,
      erroProcessamento: map['erroProcessamento'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propriedadeId': propriedadeId,
      'itemId': itemId,
      'produtorId': produtorId,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      'tipo': tipo,
      'categoria': categoria,
      'data': Timestamp.fromDate(data),
      'timestampLocal': Timestamp.fromDate(timestampLocal),
      'unidadeMedida': unidadeMedida,
      'saldoProjetado': saldoProjetado,
      'cmpProjetado': cmpProjetado,
      'unidadeMedidaCMP': unidadeMedidaCMP,
      'origemId': origemId,
      'origemTipo': origemTipo,
      'ativo': ativo,
      'deviceId': deviceId,
      'statusProcessamento': statusProcessamento,
      'idMovimentacaoReal': idMovimentacaoReal,
      'dadosOriginais': dadosOriginais,
      'dataProcessamento': dataProcessamento != null
          ? Timestamp.fromDate(dataProcessamento!)
          : null,
      'erroProcessamento': erroProcessamento,
    };
  }

  MovimentacaoEstoqueProjetada copyWith({
    String? id,
    String? propriedadeId,
    String? itemId,
    String? produtorId,
    double? quantidade,
    double? valorUnitario,
    String? tipo,
    String? categoria,
    DateTime? data,
    DateTime? timestampLocal,
    String? unidadeMedida,
    double? saldoProjetado,
    double? cmpProjetado,
    String? unidadeMedidaCMP,
    String? origemId,
    String? origemTipo,
    bool? ativo,
    String? deviceId,
    String? statusProcessamento,
    String? idMovimentacaoReal,
    Map<String, dynamic>? dadosOriginais,
    DateTime? dataProcessamento,
    String? erroProcessamento,
  }) {
    return MovimentacaoEstoqueProjetada(
      id: id ?? this.id,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      itemId: itemId ?? this.itemId,
      produtorId: produtorId ?? this.produtorId,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      timestampLocal: timestampLocal ?? this.timestampLocal,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      saldoProjetado: saldoProjetado ?? this.saldoProjetado,
      cmpProjetado: cmpProjetado ?? this.cmpProjetado,
      unidadeMedidaCMP: unidadeMedidaCMP ?? this.unidadeMedidaCMP,
      origemId: origemId ?? this.origemId,
      origemTipo: origemTipo ?? this.origemTipo,
      ativo: ativo ?? this.ativo,
      deviceId: deviceId ?? this.deviceId,
      statusProcessamento: statusProcessamento ?? this.statusProcessamento,
      idMovimentacaoReal: idMovimentacaoReal ?? this.idMovimentacaoReal,
      dadosOriginais: dadosOriginais ?? this.dadosOriginais,
      dataProcessamento: dataProcessamento ?? this.dataProcessamento,
      erroProcessamento: erroProcessamento ?? this.erroProcessamento,
    );
  }
}
