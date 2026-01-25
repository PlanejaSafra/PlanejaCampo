import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 2)
class UserPreferences extends HiveObject {
  @HiveField(0)
  String? locale; // 'pt_BR', 'en', or null (auto)

  @HiveField(1)
  String themeMode; // 'light', 'dark', 'auto'

  @HiveField(2)
  String? farmName; // Nome opcional da propriedade

  @HiveField(3)
  bool reminderEnabled; // Habilitar lembretes

  @HiveField(4)
  String? reminderTime; // Horário do lembrete (HH:mm)

  UserPreferences({
    this.locale,
    this.themeMode = 'auto',
    this.farmName,
    this.reminderEnabled = false,
    this.reminderTime,
  });

  /// Factory for default preferences
  factory UserPreferences.defaults() {
    return UserPreferences(
      locale: null, // Auto (follows system)
      themeMode: 'auto',
      farmName: null,
      reminderEnabled: false,
      reminderTime: '18:00', // Default reminder at 6 PM
    );
  }

  /// Get the box for preferences (singleton pattern)
  static const String boxName = 'user_preferences';

  /// Load or create preferences
  static Future<UserPreferences> load() async {
    final box = await Hive.openBox<UserPreferences>(boxName);

    // If no preferences exist, create defaults
    if (box.isEmpty) {
      final prefs = UserPreferences.defaults();
      await box.add(prefs);
      return prefs;
    }

    return box.getAt(0)!;
  }

  /// Save preferences
  Future<void> saveToBox() async {
    await save();
  }
}
