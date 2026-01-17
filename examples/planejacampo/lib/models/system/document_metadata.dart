class DocumentMetadata {
  final int version;
  final DateTime lastModified;
  final String lastModifiedBy;
  final String deviceId;
  final String syncStatus;
  final String hash;
  final Map<String, dynamic>? conflictData;

  DocumentMetadata({
    required this.version,
    required this.lastModified,
    required this.lastModifiedBy,
    required this.deviceId,
    required this.syncStatus,
    required this.hash,
    this.conflictData,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'lastModified': lastModified.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'deviceId': deviceId,
      'syncStatus': syncStatus,
      'hash': hash,
      'conflictData': conflictData,
    };
  }

  factory DocumentMetadata.fromMap(Map<String, dynamic> map) {
    return DocumentMetadata(
      version: map['version'] ?? 1,
      lastModified: DateTime.parse(map['lastModified'] as String),
      lastModifiedBy: map['lastModifiedBy'] ?? '',
      deviceId: map['deviceId'] ?? '',
      syncStatus: map['syncStatus'] ?? 'synced',
      hash: map['hash'] ?? '',
      conflictData: map['conflictData'],
    );
  }

  DocumentMetadata copyWith({
    int? version,
    DateTime? lastModified,
    String? lastModifiedBy,
    String? deviceId,
    String? syncStatus,
    String? hash,
    Map<String, dynamic>? conflictData,
  }) {
    return DocumentMetadata(
      version: version ?? this.version,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      deviceId: deviceId ?? this.deviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      hash: hash ?? this.hash,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  // Adicionar à classe DocumentMetadata
  bool hasConflict() {
    return conflictData != null;
  }

  DocumentMetadata resolveConflict(bool keepLocal) {
    if (!hasConflict()) return this;
    
    if (keepLocal) {
      return copyWith(conflictData: null);
    } else {
      // Use os dados do conflito
      final conflictMeta = DocumentMetadata.fromMap(
        conflictData!['_metadata'] ?? {}
      );
      return conflictMeta.copyWith(
        version: version + 1,
        lastModified: DateTime.now(),
        conflictData: null
      );
    }
  }
}