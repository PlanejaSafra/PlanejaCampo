import 'package:cloud_firestore/cloud_firestore.dart';

class ContaContabil {
  final String id;
  final String codigo;        // ex: "1.1.1.01"
  final String nome;          // ex: "Caixa"
  final String tipo;          // "sintetica" ou "analitica"
  final String natureza;      // "devedora" ou "credora"
  final String? contaPaiId;   // vínculo hierárquico
  final bool ativo;
  final String produtorId;    // vínculo com produtor
  final String languageCode;  // novo atributo

  ContaContabil({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.tipo,
    required this.natureza,
    this.contaPaiId,
    required this.ativo,
    required this.produtorId,
    required this.languageCode,
  });

  factory ContaContabil.fromMap(Map<String, dynamic> map, String documentId) {
    return ContaContabil(
      id: documentId,
      codigo: map['codigo'] ?? '',
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? '',
      natureza: map['natureza'] ?? '',
      contaPaiId: map['contaPaiId'],
      ativo: map['ativo'] ?? true,
      produtorId: map['produtorId'] ?? '',
      languageCode: map['languageCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'tipo': tipo,
      'natureza': natureza,
      'contaPaiId': contaPaiId,
      'ativo': ativo,
      'produtorId': produtorId,
      'languageCode': languageCode,
    };
  }

  ContaContabil copyWith({
    String? id,
    String? codigo,
    String? nome,
    String? tipo,
    String? natureza,
    String? contaPaiId,
    bool? ativo,
    String? produtorId,
    String? languageCode,
  }) {
    return ContaContabil(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      natureza: natureza ?? this.natureza,
      contaPaiId: contaPaiId ?? this.contaPaiId,
      ativo: ativo ?? this.ativo,
      produtorId: produtorId ?? this.produtorId,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
