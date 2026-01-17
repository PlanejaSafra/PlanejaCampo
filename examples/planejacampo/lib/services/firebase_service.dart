import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configurações otimizadas para operação offline
    final settings = const Settings(
      persistenceEnabled: true,  // Habilita persistência offline
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,  // Cache ilimitado
      sslEnabled: true,  // Mantém SSL
    );

    // Configura o Firestore com as settings otimizadas
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore.settings = settings;

    _firestore = firestore;
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firestore não foi inicializado. Chame initializeFirebase() primeiro.');
    }
    return _firestore!;
  }

  // Método para limpar cache se necessário
  static Future<void> clearPersistence() async {
    if (_firestore != null) {
      await _firestore!.clearPersistence();
    }
  }

  // Método para terminar instância do Firestore
  static Future<void> terminate() async {
    if (_firestore != null) {
      await _firestore!.terminate();
      _firestore = null;
    }
  }
}