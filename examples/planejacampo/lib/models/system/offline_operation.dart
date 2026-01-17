enum OperationPriority {
  HIGH,    // Operações críticas (ex: transações financeiras)
  MEDIUM,  // Operações importantes (ex: atualizações de status)
  LOW      // Operações não críticas (ex: atualizações de metadados)
}

class OfflineOperation {
  final String collection;
  final String operationType;
  final String? docId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? produtorId;
  final OperationPriority priority;
  final int retryCount;
  final List<String> dependencies;
  final DateTime? deadline;

  OfflineOperation({
    required this.collection,
    required this.operationType,
    this.docId,
    required this.data,
    required this.timestamp,
    this.produtorId,
    this.priority = OperationPriority.MEDIUM,
    this.retryCount = 0,
    this.dependencies = const [],
    this.deadline,
  });

  Map<String, dynamic> toMap() => {
    'collection': collection,
    'operationType': operationType,
    'docId': docId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'produtorId': produtorId,
    'priority': priority.toString(),
    'retryCount': retryCount,
    'dependencies': dependencies,
    'deadline': deadline?.toIso8601String(),
  };

  factory OfflineOperation.fromMap(Map<String, dynamic> map) {
    return OfflineOperation(
      collection: map['collection'],
      operationType: map['operationType'],
      docId: map['docId'],
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
      produtorId: map['produtorId'],
      priority: _getPriorityFromString(map['priority'] ?? 'MEDIUM'),
      retryCount: map['retryCount'] ?? 0,
      dependencies: map['dependencies'] != null 
          ? List<String>.from(map['dependencies'])
          : [],
      deadline: map['deadline'] != null 
          ? DateTime.parse(map['deadline'])
          : null,
    );
  }

  static OperationPriority _getPriorityFromString(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return OperationPriority.HIGH;
      case 'LOW':
        return OperationPriority.LOW;
      default:
        return OperationPriority.MEDIUM;
    }
  }

  OfflineOperation copyWith({
    String? collection,
    String? operationType,
    String? docId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? produtorId,
    OperationPriority? priority,
    int? retryCount,
    List<String>? dependencies,
    DateTime? deadline,
  }) {
    return OfflineOperation(
      collection: collection ?? this.collection,
      operationType: operationType ?? this.operationType,
      docId: docId ?? this.docId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      produtorId: produtorId ?? this.produtorId,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      dependencies: dependencies ?? this.dependencies,
      deadline: deadline ?? this.deadline,
    );
  }

  // Adicionar à classe OfflineOperation
  bool isExpired() {
    return deadline != null && DateTime.now().isAfter(deadline!);
  }

  bool canRetry() {
    return retryCount < 3; // ou outro limite configurável
  }

  // Método para verificar se operação é crítica
  bool isCritical() {
    return priority == OperationPriority.HIGH;
  }

  // Método para verificar dependências
  bool hasDependencies() {
    return dependencies.isNotEmpty;
  }
}