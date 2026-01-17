import 'package:cloud_firestore/cloud_firestore.dart';

class LancamentoContabil {
  final String id;
  final String produtorId;
  final DateTime data;
  final String contaContabilId;      // ID da conta contábil
  final String tipo;         // 'debito' ou 'credito'
  final double valor;
  final double saldoAtual;   // Novo atributo
  final String origemId;     // ID do documento origem
  final String origemTipo;   // Tipo do documento origem
  final String? descricao;   // Descrição opcional
  final bool ativo;          // Para estornos
  final String? estornoId;   // Referência ao lançamento estornado
  final String? loteId;      // Agrupa lançamentos do mesmo fato
  final DateTime timestamp;  // Controle de ordem dos lançamentos

  LancamentoContabil({
    required this.id,
    required this.produtorId,
    required this.data,
    required this.contaContabilId,
    required this.tipo,
    required this.valor,
    required this.saldoAtual,
    required this.origemId,
    required this.origemTipo,
    this.descricao,
    required this.ativo,
    this.estornoId,
    this.loteId,
    required this.timestamp,
  });

  factory LancamentoContabil.fromMap(Map<String, dynamic> map, String documentId) {
    return LancamentoContabil(
      id: documentId,
      produtorId: map['produtorId'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      contaContabilId: map['contaContabilId'] ?? '',
      tipo: map['tipo'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      saldoAtual: (map['saldoAtual'] ?? 0.0).toDouble(), // Novo atributo
      origemId: map['origemId'] ?? '',
      origemTipo: map['origemTipo'] ?? '',
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
      estornoId: map['estornoId'],
      loteId: map['loteId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'data': Timestamp.fromDate(data.toUtc()),
      'contaContabilId': contaContabilId,
      'tipo': tipo,
      'valor': valor,
      'saldoAtual': saldoAtual, // Novo atributo
      'origemId': origemId,
      'origemTipo': origemTipo,
      'descricao': descricao,
      'ativo': ativo,
      'estornoId': estornoId,
      'loteId': loteId,
      'timestamp': Timestamp.fromDate(timestamp.toUtc()),
    };
  }

  LancamentoContabil copyWith({
    String? id,
    String? produtorId,
    DateTime? data,
    String? contaContabilId,
    String? tipo,
    double? valor,
    double? saldoAtual, // Novo atributo
    String? origemId,
    String? origemTipo,
    String? descricao,
    bool? ativo,
    String? estornoId,
    String? loteId,
    DateTime? timestamp,
  }) {
    return LancamentoContabil(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      data: data ?? this.data,
      contaContabilId: contaContabilId ?? this.contaContabilId,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      saldoAtual: saldoAtual ?? this.saldoAtual, // Novo atributo
      origemId: origemId ?? this.origemId,
      origemTipo: origemTipo ?? this.origemTipo,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      estornoId: estornoId ?? this.estornoId,
      loteId: loteId ?? this.loteId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
