import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/enums.dart';

class ResultadoAnaliseSolo {
  // Limites máximos aceitáveis para elementos (mmolc/dm³)
  static const double LIMITE_MAXIMO_SODIO = 10.0;
  static const double LIMITE_MAXIMO_CALCIO = 150.0;
  static const double LIMITE_MAXIMO_MAGNESIO = 50.0;
  static const double LIMITE_MAXIMO_POTASSIO = 10.0;
  static const double LIMITE_MAXIMO_ALUMINIO = 50.0;
  static const double LIMITE_MAXIMO_HAL = 200.0;

  final String id;
  final String produtorId;
  final String propriedadeId;
  final List<String>? talhoes;
  final String laboratorioId;
  final String metodologiaExtracao;
  final String responsavelColetaId;
  final DateTime dataColeta;
  final DateTime dataAnalise;

  // pH e complexo de acidez
  final double pH;          // CaCl2
  final double al;          // mmolc/dm³ (Alumínio trocável)
  final double hAl;         // mmolc/dm³ (Acidez potencial)

  // Macronutrientes
  final double fosforo;     // mg/dm³
  final double potassio;    // mmolc/dm³
  final double calcio;      // mmolc/dm³
  final double magnesio;    // mmolc/dm³
  final double enxofre;     // mg/dm³ (S-SO4)

  // Micronutrientes
  final double boro;        // mg/dm³
  final double cobre;       // mg/dm³
  final double ferro;       // mg/dm³
  final double manganes;    // mg/dm³
  final double zinco;       // mg/dm³

  // Matéria Orgânica
  final double mo;          // g/dm³ (Matéria orgânica)
  final double co;          // g/dm³ (Carbono orgânico)

  // Análise Física (Granulometria)
  final double silte;       // g/kg
  final double argila;      // g/kg
  final double areiaTotal;  // g/kg
  final double areiaGrossa; // g/kg
  final double areiaFina;   // g/kg

  // Outros
  final double sodio;       // mmolc/dm³
  final ProfundidadeAmostra profundidadeAmostra;
  final TexturaSolo? texturaSolo;
  final List<String> observacoes;

  ResultadoAnaliseSolo({
    required this.id,
    required this.produtorId,
    required this.propriedadeId,
    this.talhoes,
    required this.laboratorioId,
    required this.metodologiaExtracao,
    required this.responsavelColetaId,
    required this.dataColeta,
    required this.dataAnalise,
    required this.pH,
    required this.al,
    required this.hAl,
    required this.fosforo,
    required this.potassio,
    required this.calcio,
    required this.magnesio,
    required this.enxofre,
    required this.boro,
    required this.cobre,
    required this.ferro,
    required this.manganes,
    required this.zinco,
    required this.mo,
    required this.co,
    required this.silte,
    required this.argila,
    required this.areiaTotal,
    required this.areiaGrossa,
    required this.areiaFina,
    required this.sodio,
    this.profundidadeAmostra = ProfundidadeAmostra.SUPERFICIAL,
    this.texturaSolo,
    this.observacoes = const [],
  });

  // Método para verificar se um valor está dentro do limite aceitável
  bool _isValorAceitavel(double valor, double limiteMaximo) {
    return valor >= 0 && valor <= limiteMaximo;
  }

  // Getters para valores com validação
  double get sodioValido => _isValorAceitavel(sodio, LIMITE_MAXIMO_SODIO) ? sodio : 0.0;
  double get calcioValido => _isValorAceitavel(calcio, LIMITE_MAXIMO_CALCIO) ? calcio : 0.0;
  double get magnesioValido => _isValorAceitavel(magnesio, LIMITE_MAXIMO_MAGNESIO) ? magnesio : 0.0;
  double get potassioValido => _isValorAceitavel(potassio, LIMITE_MAXIMO_POTASSIO) ? potassio : 0.0;
  double get aluminioValido => _isValorAceitavel(al, LIMITE_MAXIMO_ALUMINIO) ? al : 0.0;
  double get halValido => _isValorAceitavel(hAl, LIMITE_MAXIMO_HAL) ? hAl : 0.0;

  // Cálculos derivados atualizados
  double get somaBase => calcioValido + magnesioValido + potassioValido + sodioValido;
  double get ctc => somaBase + halValido;
  double get saturacaoBase => (ctc > 0) ? (somaBase / ctc) * 100 : 0;  // V%
  double get saturacaoAl => (somaBase + aluminioValido > 0) ? (aluminioValido / (somaBase + aluminioValido)) * 100 : 0;  // m%

  // Representação na CTC (%)
  double get caCtc => (ctc > 0) ? (calcioValido / ctc) * 100 : 0;
  double get mgCtc => (ctc > 0) ? (magnesioValido / ctc) * 100 : 0;
  double get kCtc => (ctc > 0) ? (potassioValido / ctc) * 100 : 0;
  double get hAlCtc => (ctc > 0) ? (halValido / ctc) * 100 : 0;

  // Relações entre bases
  double get relacaoCaMg => (magnesioValido > 0) ? calcioValido / magnesioValido : 0;
  double get relacaoCaK => (potassioValido > 0) ? calcioValido / potassioValido : 0;
  double get relacaoMgK => (potassioValido > 0) ? magnesioValido / potassioValido : 0;

  // Método para obter alertas sobre valores anormais
  List<String> getAlertas() {
    List<String> alertas = [];

    if (sodio > LIMITE_MAXIMO_SODIO) {
      alertas.add('Teor de sódio muito alto (${sodio.toStringAsFixed(1)} mmolc/dm³). '
          'Valor desconsiderado dos cálculos. Verificar contaminação ou histórico de manejo.');
    }

    if (calcio > LIMITE_MAXIMO_CALCIO) {
      alertas.add('Teor de cálcio muito alto (${calcio.toStringAsFixed(1)} mmolc/dm³). '
          'Valor desconsiderado dos cálculos.');
    }

    if (magnesio > LIMITE_MAXIMO_MAGNESIO) {
      alertas.add('Teor de magnésio muito alto (${magnesio.toStringAsFixed(1)} mmolc/dm³). '
          'Valor desconsiderado dos cálculos.');
    }

    if (potassio > LIMITE_MAXIMO_POTASSIO) {
      alertas.add('Teor de potássio muito alto (${potassio.toStringAsFixed(1)} mmolc/dm³). '
          'Valor desconsiderado dos cálculos.');
    }

    if (al > LIMITE_MAXIMO_ALUMINIO) {
      alertas.add('Teor de alumínio muito alto (${al.toStringAsFixed(1)} mmolc/dm³). '
          'Valor desconsiderado dos cálculos.');
    }

    if (hAl > LIMITE_MAXIMO_HAL) {
      alertas.add('Teor de H+Al muito alto (${hAl.toStringAsFixed(1)} mmolc/dm³). '
          'Valor desconsiderado dos cálculos.');
    }

    return alertas;
  }

  factory ResultadoAnaliseSolo.fromMap(Map<String, dynamic> map, String id) {
    return ResultadoAnaliseSolo(
      id: id,
      produtorId: map['produtorId'] ?? '',
      propriedadeId: map['propriedadeId'] ?? '',
      talhoes: map['talhoes'] != null ? List<String>.from(map['talhoes']) : null,
      laboratorioId: map['laboratorioId'] ?? '',
      metodologiaExtracao: map['metodologiaExtracao'] ?? '',
      responsavelColetaId: map['responsavelColetaId'] ?? '',
      dataColeta: (map['dataColeta'] as Timestamp).toDate(),
      dataAnalise: (map['dataAnalise'] as Timestamp).toDate(),
      pH: (map['pH'] as num?)?.toDouble() ?? 0.0,
      al: (map['al'] as num?)?.toDouble() ?? 0.0,
      hAl: (map['hAl'] as num?)?.toDouble() ?? 0.0,
      fosforo: (map['fosforo'] as num?)?.toDouble() ?? 0.0,
      potassio: (map['potassio'] as num?)?.toDouble() ?? 0.0,
      calcio: (map['calcio'] as num?)?.toDouble() ?? 0.0,
      magnesio: (map['magnesio'] as num?)?.toDouble() ?? 0.0,
      enxofre: (map['enxofre'] as num?)?.toDouble() ?? 0.0,
      boro: (map['boro'] as num?)?.toDouble() ?? 0.0,
      cobre: (map['cobre'] as num?)?.toDouble() ?? 0.0,
      ferro: (map['ferro'] as num?)?.toDouble() ?? 0.0,
      manganes: (map['manganes'] as num?)?.toDouble() ?? 0.0,
      zinco: (map['zinco'] as num?)?.toDouble() ?? 0.0,
      mo: (map['mo'] as num?)?.toDouble() ?? 0.0,
      co: (map['co'] as num?)?.toDouble() ?? 0.0,
      silte: (map['silte'] as num?)?.toDouble() ?? 0.0,
      argila: (map['argila'] as num?)?.toDouble() ?? 0.0,
      areiaTotal: (map['areiaTotal'] as num?)?.toDouble() ?? 0.0,
      areiaGrossa: (map['areiaGrossa'] as num?)?.toDouble() ?? 0.0,
      areiaFina: (map['areiaFina'] as num?)?.toDouble() ?? 0.0,
      sodio: (map['sodio'] as num?)?.toDouble() ?? 0.0,
      profundidadeAmostra: map['profundidadeAmostra'] != null
          ? ProfundidadeAmostra.fromString(map['profundidadeAmostra'])
          : ProfundidadeAmostra.SUPERFICIAL,
      texturaSolo: map['texturaSolo'] != null
          ? TexturaSolo.fromString(map['texturaSolo'])
          : null,
      observacoes: List<String>.from(map['observacoes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtorId': produtorId,
      'propriedadeId': propriedadeId,
      'talhoes': talhoes,
      'laboratorioId': laboratorioId,
      'metodologiaExtracao': metodologiaExtracao,
      'responsavelColetaId': responsavelColetaId,
      'dataColeta': Timestamp.fromDate(dataColeta),
      'dataAnalise': Timestamp.fromDate(dataAnalise),
      'pH': pH,
      'al': al,
      'hAl': hAl,
      'fosforo': fosforo,
      'potassio': potassio,
      'calcio': calcio,
      'magnesio': magnesio,
      'enxofre': enxofre,
      'boro': boro,
      'cobre': cobre,
      'ferro': ferro,
      'manganes': manganes,
      'zinco': zinco,
      'mo': mo,
      'co': co,
      'silte': silte,
      'argila': argila,
      'areiaTotal': areiaTotal,
      'areiaGrossa': areiaGrossa,
      'areiaFina': areiaFina,
      'sodio': sodio,
      'profundidadeAmostra': profundidadeAmostra.descricao,
      'texturaSolo': texturaSolo?.name,
      'observacoes': observacoes,
    };
  }

  ResultadoAnaliseSolo copyWith({
    String? id,
    String? produtorId,
    String? propriedadeId,
    List<String>? talhoes,
    String? laboratorioId,
    String? metodologiaExtracao,
    String? responsavelColetaId,
    DateTime? dataColeta,
    DateTime? dataAnalise,
    double? pH,
    double? al,
    double? hAl,
    double? fosforo,
    double? potassio,
    double? calcio,
    double? magnesio,
    double? enxofre,
    double? boro,
    double? cobre,
    double? ferro,
    double? manganes,
    double? zinco,
    double? mo,
    double? co,
    double? silte,
    double? argila,
    double? areiaTotal,
    double? areiaGrossa,
    double? areiaFina,
    double? sodio,
    ProfundidadeAmostra? profundidadeAmostra,
    TexturaSolo? texturaSolo,
    List<String>? observacoes,
  }) {
    return ResultadoAnaliseSolo(
        id: id ?? this.id,
        produtorId: produtorId ?? this.produtorId,
        propriedadeId: propriedadeId ?? this.propriedadeId,
        talhoes: talhoes ?? this.talhoes,
        laboratorioId: laboratorioId ?? this.laboratorioId,
        metodologiaExtracao: metodologiaExtracao ?? this.metodologiaExtracao,
        responsavelColetaId: responsavelColetaId ?? this.responsavelColetaId,
      dataColeta: dataColeta ?? this.dataColeta,
      dataAnalise: dataAnalise ?? this.dataAnalise,
      pH: pH ?? this.pH,
      al: al ?? this.al,
      hAl: hAl ?? this.hAl,
      fosforo: fosforo ?? this.fosforo,
      potassio: potassio ?? this.potassio,
      calcio: calcio ?? this.calcio,
      magnesio: magnesio ?? this.magnesio,
      enxofre: enxofre ?? this.enxofre,
      boro: boro ?? this.boro,
      cobre: cobre ?? this.cobre,
      ferro: ferro ?? this.ferro,
      manganes: manganes ?? this.manganes,
      zinco: zinco ?? this.zinco,
      mo: mo ?? this.mo,
      co: co ?? this.co,
      silte: silte ?? this.silte,
      argila: argila ?? this.argila,
      areiaTotal: areiaTotal ?? this.areiaTotal,
      areiaGrossa: areiaGrossa ?? this.areiaGrossa,
      areiaFina: areiaFina ?? this.areiaFina,
      sodio: sodio ?? this.sodio,
      profundidadeAmostra: profundidadeAmostra ?? this.profundidadeAmostra,
      texturaSolo: texturaSolo ?? this.texturaSolo,
      observacoes: observacoes ?? List.from(this.observacoes),
    );
  }

  // Método para validar a análise granulométrica
  bool validarGranulometria() {
    final somaGranulometria = silte + argila + areiaTotal;
    return somaGranulometria >= 950 && somaGranulometria <= 1050; // Soma deve estar próxima de 1000 g/kg
  }

  // Método para verificar se os valores críticos para fertilidade estão dentro das faixas esperadas
  List<String> validarFertilidade() {
    List<String> alertas = [];

    // Validação pH
    if (pH < 4.0) {
      alertas.add('pH extremamente baixo (${pH.toStringAsFixed(1)}). Verificar acidez do solo.');
    }

    // Validação Saturação por Bases
    if (saturacaoBase < 20) {
      alertas.add('Saturação por bases muito baixa (${saturacaoBase.toStringAsFixed(1)}%). Necessidade de correção do solo.');
    }

    // Validação CTC
    if (ctc < 40) {
      alertas.add('CTC baixa (${ctc.toStringAsFixed(1)} mmolc/dm³). Solo com baixa capacidade de retenção de nutrientes.');
    }

    return alertas;
  }

  // Sobrescrita do método toString para facilitar o debug
  @override
  String toString() {
    return 'ResultadoAnaliseSolo{'
        'id: $id, '
        'pH: $pH, '
        'SB: $somaBase, '
        'CTC: $ctc, '
        'V%: ${saturacaoBase.toStringAsFixed(1)}, '
        'm%: ${saturacaoAl.toStringAsFixed(1)}'
        '}';
  }
}