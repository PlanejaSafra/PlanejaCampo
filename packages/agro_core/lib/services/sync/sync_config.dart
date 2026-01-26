/// Configuração global do serviço de sincronização
class SyncConfig {
  static final SyncConfig instance = SyncConfig._();

  SyncConfig._();

  // Timeouts
  Duration timeoutOnlineWrite = const Duration(seconds: 30);
  Duration timeoutOnlineRead = const Duration(seconds: 20);
  Duration timeoutOfflineWrite = const Duration(seconds: 5);
  Duration timeoutOfflineRead = const Duration(seconds: 3);

  // Retries e Debounce
  int maxRetries = 5;
  Duration syncDebounce = const Duration(minutes: 5);
  Duration backgroundSyncInterval = const Duration(minutes: 15);

  // Limits
  int batchSize = 500; // Limite do Firestore

  // Strategies
  ConflictStrategy conflictStrategy = ConflictStrategy.serverWins;
  bool autoSyncOnConnect = true;

  void configure({
    Duration? timeoutOnlineWrite,
    Duration? timeoutOnlineRead,
    Duration? timeoutOfflineWrite,
    Duration? timeoutOfflineRead,
    int? maxRetries,
    Duration? syncDebounce,
    int? batchSize,
    ConflictStrategy? conflictStrategy,
    bool? autoSyncOnConnect,
  }) {
    if (timeoutOnlineWrite != null)
      this.timeoutOnlineWrite = timeoutOnlineWrite;
    if (timeoutOnlineRead != null) this.timeoutOnlineRead = timeoutOnlineRead;
    if (timeoutOfflineWrite != null)
      this.timeoutOfflineWrite = timeoutOfflineWrite;
    if (timeoutOfflineRead != null)
      this.timeoutOfflineRead = timeoutOfflineRead;
    if (maxRetries != null) this.maxRetries = maxRetries;
    if (syncDebounce != null) this.syncDebounce = syncDebounce;
    if (batchSize != null) this.batchSize = batchSize;
    if (conflictStrategy != null) this.conflictStrategy = conflictStrategy;
    if (autoSyncOnConnect != null) this.autoSyncOnConnect = autoSyncOnConnect;
  }

  void reset() {
    timeoutOnlineWrite = const Duration(seconds: 30);
    timeoutOnlineRead = const Duration(seconds: 20);
    timeoutOfflineWrite = const Duration(seconds: 5);
    timeoutOfflineRead = const Duration(seconds: 3);
    maxRetries = 5;
    syncDebounce = const Duration(minutes: 5);
    batchSize = 500;
    conflictStrategy = ConflictStrategy.serverWins;
    autoSyncOnConnect = true;
  }
}

/// Estratégia de resolução de conflitos entre dados locais e remotos
enum ConflictStrategy {
  serverWins, // Dados do servidor prevalecem (default)
  localWins, // Dados locais prevalecem
  merge, // Merge campo a campo (data mais recente vence)
}
