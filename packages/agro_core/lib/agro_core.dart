// Agro Core - Biblioteca de componentes reutilizáveis para aplicações agro.

// Theme
export 'theme/app_theme.dart';
export 'theme/extensions/chart_theme.dart';
export 'theme/extensions/theme_extensions.dart';

// Utils
export 'utils/date_utils.dart';
export 'utils/locale_extension.dart';

// Widgets
export 'widgets/custom_card.dart';
export 'widgets/primary_button.dart';
export 'widgets/talhao_selector.dart';
export 'widgets/weather_card.dart';

// Services (Sync Infrastructure - CORE-78/95)
export 'services/sync/sync_models.dart';
export 'services/sync/local_cache_manager.dart';
export 'services/sync/offline_queue_manager.dart';
export 'services/sync/data_integrity_manager.dart';
export 'services/sync/generic_sync_service.dart';
export 'services/sync/sync_config.dart';
export 'services/sync/tier2_pipeline.dart';

// Services (Existing)
export 'services/weather_service.dart';
export 'services/notification_service.dart';
export 'services/background_service.dart';
export 'services/heatmap_service.dart';
export 'models/weather_forecast.dart';
export 'services/home_widget_service.dart';
export 'services/agro_ad_service.dart';
export 'widgets/agro_banner_widget.dart';

// L10n
export 'l10n/generated/app_localizations.dart';

// Privacy
export 'privacy/agro_privacy_keys.dart';
export 'privacy/agro_privacy_store.dart';
export 'privacy/consent_screen.dart';
export 'privacy/identity_screen.dart';
export 'privacy/onboarding_gate.dart';

// Models (Cloud Sync & Identity)
export 'models/consent_data.dart';
export 'models/device_info.dart';
export 'models/user_cloud_data.dart';

// Models (Property Management)
export 'models/property.dart';
export 'models/talhao.dart';

// Models (Farm - Multi-User Preparation)
export 'models/farm.dart';
export 'models/farm_owned_mixin.dart';
export 'models/farm_type.dart';

// Models (Unified Categories - CORE-96)
export 'models/categoria.dart';
export 'models/categoria_core.dart';
export 'services/categoria_service.dart';
export 'exceptions/categoria_exceptions.dart';

// Models (Dependency-Aware Backup - CORE-77)
export 'models/backup_meta.dart';
export 'models/dependency_check_result.dart';
export 'models/dependency_manifest.dart';
export 'models/restore_analysis.dart';
export 'models/lgpd_deletion_result.dart';

// Services (Auth & Cloud Sync)
export 'auth/agro_auth_gate.dart';
export 'services/auth_service.dart';
export 'services/user_cloud_service.dart';

// Services (Property Management)
export 'services/property_service.dart';
export 'services/property_helper.dart';
export 'services/talhao_service.dart';

// Services (Farm - Multi-User Preparation)
export 'services/farm_service.dart';

// Models (Safra - Agricultural Year - CORE-76)
export 'models/safra.dart';

// Services (Safra - CORE-76)
export 'services/safra_service.dart';

// Widgets (Safra - CORE-76)
export 'widgets/safra_chip.dart';
export 'widgets/safra_bottom_sheet.dart';

// Services (Backup & Dependency - CORE-77)
export 'services/cloud_backup_service.dart';
export 'services/dependency_service.dart';
export 'services/property_backup_provider.dart';
export 'widgets/backup_restore_dialog.dart';
export 'widgets/restore_confirmation_dialog.dart';
export 'widgets/property_name_prompt_dialog.dart';

// Services (LGPD Compliance)
export 'services/data_deletion_service.dart';
export 'services/data_export_service.dart';
export 'services/data_migration_service.dart';

// Menu
export 'menu/agro_drawer.dart';
export 'menu/agro_drawer_item.dart';

// Screens
export 'screens/agro_about_screen.dart';
export 'screens/agro_privacy_screen.dart';
export 'screens/agro_settings_screen.dart';
export 'screens/weather_map_screen.dart';
export 'services/radar_service.dart';
export 'screens/login_screen.dart';
export 'screens/terms_of_use_screen.dart';
export 'screens/privacy_policy_screen.dart';

// Screens (Property Management)
export 'screens/property_list_screen.dart';
export 'screens/property_form_screen.dart';
export 'screens/talhao_list_screen.dart';
export 'screens/talhao_form_screen.dart';
