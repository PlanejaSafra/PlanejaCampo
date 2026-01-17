// conta_pagar.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ContaPagar {
  final String id;
  final String produtorId;
  final String? contaId;        // Conta para pagamento
  final double valor;
  final double valorPago;      // Novo: controle do valor já pago
  final String status;         // Novo: 'aberto', 'parcial', 'pago', 'vencido', 'cancelado'
  final DateTime dataEmissao;  // Novo: data de emissão do documento
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final String? numeroDocumento;  // Novo: número da nota/fatura
  final String meioPagamento;   // 'dinheiro', 'pix', 'cartao', etc
  final int? numeroParcela;    // Novo: número da parcela atual
  final int? totalParcelas;    // Novo: total de parcelas
  final String origemId;       // Novo: ID do documento de origem (compra, operação, etc)
  final String origemTipo;     // Novo: tipo do documento origem (compras, abastecimentos, etc)
  final String categoria;      // Novo: classificação da despesa
  final String? observacoes;   // Novo: observações gerais
  final bool ativo;           // Novo: controle de status ativo/cancelado
  final String? fornecedorId;  // Novo: vínculo com fornecedor

  ContaPagar({
    required this.id,
    required this.produtorId,
    this.contaId,
    required this.valor,
    required this.valorPago,
    required this.status,
    required this.dataEmissao,
    required this.dataVencimento,
    this.dataPagamento,
    this.numeroDocumento,
    required this.meioPagamento,
    this.numeroParcela,
    this.totalParcelas,
    required this.origemId,
    required this.origemTipo,
    required this.categoria,
    this.observacoes,
    required this.ativo,
    this.fornecedorId,
  });

  factory ContaPagar.fromMap(Map<String, dynamic> map, String documentId) {
    return ContaPagar(
      id: documentId,
      produtorId: map['produtorId'] ?? '',
      contaId: map['contaId'],
      valor: (map['valor'] ?? 0.0).toDouble(),
      valorPago: (map['valorPago'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'aberto',
      dataEmissao: (map['dataEmissao'] as Timestamp).toDate(),
      dataVencimento: (map['dataVencimento'] as Timestamp).toDate(),
      dataPagamento: map['dataPagamento'] != null
          ? (map['dataPagamento'] as Timestamp).toDate()
          : null,
      numeroDocumento: map['numeroDocumento'],
      meioPagamento: map['meioPagamento'] ?? '',
      numeroParcela: map['numeroParcela'],
      totalParcelas: map['totalParcelas'],
      origemId: map['origemId'] ?? '',
      origemTipo: map['origemTipo'] ?? '',
      categoria: map['categoria'] ?? '',
      observacoes: map['observacoes'],
      ativo: map['ativo'] ?? true,
      fornecedorId: map['fornecedorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'contaId': contaId,
      'valor': valor,
      'valorPago': valorPago,
      'status': status,
      'dataEmissao': Timestamp.fromDate(dataEmissao),
      'dataVencimento': Timestamp.fromDate(dataVencimento.toUtc()),
      'dataPagamento': dataPagamento != null
          ? Timestamp.fromDate(dataPagamento!)
          : null,
      'numeroDocumento': numeroDocumento,
      'meioPagamento': meioPagamento,
      'numeroParcela': numeroParcela,
      'totalParcelas': totalParcelas,
      'origemId': origemId,
      'origemTipo': origemTipo,
      'categoria': categoria,
      'observacoes': observacoes,
      'ativo': ativo,
      'fornecedorId': fornecedorId,
    };
  }

  ContaPagar copyWith({
    String? id,
    String? produtorId,
    String? contaId,
    double? valor,
    double? valorPago,
    String? status,
    DateTime? dataEmissao,
    DateTime? dataVencimento,
    DateTime? dataPagamento,
    String? numeroDocumento,
    String? meioPagamento,
    int? numeroParcela,
    int? totalParcelas,
    String? origemId,
    String? origemTipo,
    String? categoria,
    String? observacoes,
    bool? ativo,
    String? fornecedorId,
  }) {
    return ContaPagar(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      contaId: contaId ?? this.contaId,
      valor: valor ?? this.valor,
      valorPago: valorPago ?? this.valorPago,
      status: status ?? this.status,
      dataEmissao: dataEmissao ?? this.dataEmissao,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      meioPagamento: meioPagamento ?? this.meioPagamento,
      numeroParcela: numeroParcela ?? this.numeroParcela,
      totalParcelas: totalParcelas ?? this.totalParcelas,
      origemId: origemId ?? this.origemId,
      origemTipo: origemTipo ?? this.origemTipo,
      categoria: categoria ?? this.categoria,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      fornecedorId: fornecedorId ?? this.fornecedorId,
    );
  }
}