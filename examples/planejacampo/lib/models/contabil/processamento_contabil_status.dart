import 'package:cloud_firestore/cloud_firestore.dart';

class ProcessamentoContabilStatus {
  final String id;
  final String produtorId;
  final String contaContabilId;
  final String deviceId;
  final DateTime inicioProcessamento;
  final DateTime ultimaAtualizacao;
  final bool emProcessamento;
  final String? ultimoErro;

  ProcessamentoContabilStatus({
    required this.id,
    required this.produtorId,
    required this.contaContabilId,
    required this.deviceId,
    required this.inicioProcessamento,
    required this.ultimaAtualizacao,
    required this.emProcessamento,
    this.ultimoErro,
  });

  factory ProcessamentoContabilStatus.fromMap(Map<String, dynamic> map, String id) {
    return ProcessamentoContabilStatus(
      id: id,
      produtorId: map['produtorId'] ?? '',
      contaContabilId: map['contaContabilId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      inicioProcessamento: (map['inicioProcessamento'] as Timestamp).toDate(),
      ultimaAtualizacao: (map['ultimaAtualizacao'] as Timestamp).toDate(),
      emProcessamento: map['emProcessamento'] ?? false,
      ultimoErro: map['ultimoErro'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'contaContabilId': contaContabilId,
      'deviceId': deviceId,
      'inicioProcessamento': Timestamp.fromDate(inicioProcessamento),
      'ultimaAtualizacao': Timestamp.fromDate(ultimaAtualizacao),
      'emProcessamento': emProcessamento,
      'ultimoErro': ultimoErro,
    };
  }

  ProcessamentoContabilStatus copyWith({
    String? id,
    String? produtorId,
    String? contaContabilId,
    String? deviceId,
    DateTime? inicioProcessamento,
    DateTime? ultimaAtualizacao,
    bool? emProcessamento,
    String? ultimoErro,
  }) {
    return ProcessamentoContabilStatus(
      id: id ?? this.id,
      produtorId: produtorId ?? this.produtorId,
      contaContabilId: contaContabilId ?? this.contaContabilId,
      deviceId: deviceId ?? this.deviceId,
      inicioProcessamento: inicioProcessamento ?? this.inicioProcessamento,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      emProcessamento: emProcessamento ?? this.emProcessamento,
      ultimoErro: ultimoErro ?? this.ultimoErro,
    );
  }

  @override
  String toString() {
    return 'ProcessamentoContabilStatus(id: $id, produtorId: $produtorId, contaContabilId: $contaContabilId, deviceId: $deviceId, inicioProcessamento: $inicioProcessamento, ultimaAtualizacao: $ultimaAtualizacao, emProcessamento: $emProcessamento, ultimoErro: $ultimoErro)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProcessamentoContabilStatus &&
        other.id == id &&
        other.produtorId == produtorId &&
        other.contaContabilId == contaContabilId &&
        other.deviceId == deviceId &&
        other.inicioProcessamento == inicioProcessamento &&
        other.ultimaAtualizacao == ultimaAtualizacao &&
        other.emProcessamento == emProcessamento &&
        other.ultimoErro == ultimoErro;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    produtorId.hashCode ^
    contaContabilId.hashCode ^
    deviceId.hashCode ^
    inicioProcessamento.hashCode ^
    ultimaAtualizacao.hashCode ^
    emProcessamento.hashCode ^
    ultimoErro.hashCode;
  }
}
