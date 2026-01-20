# Arquitetura do Core (`packages/agro_core`)

Este documento descreve objetivamente os módulos e componentes da biblioteca compartilhada **Agro Core**.

## Módulos Principais

### 1. Theme (`lib/theme/`)

Gerencia a identidade visual da suíte de aplicativos.

*   **`AppTheme` (`app_theme.dart`)**: Classe fábrica que fornece os temas `light()` e `dark()` pré-configurados com a paleta de cores, tipografia e estilos de componentes do PlanejaCampo.
*   **Extensions**: Contém extensões de tema para componentes específicos (ex: gráficos).

### 2. Privacy & Onboarding (`lib/privacy/`)

Implementa o fluxo obrigatório de privacidade e consentimento (LGPD).

*   **`AgroPrivacyStore` (`agro_privacy_store.dart`)**: Gerencia o estado de aceitação dos termos e consentimentos (armazenado no SharedPreferences).
*   **`AgroOnboardingGate` (`onboarding_gate.dart`)**: Widget "porteiro" que deve envolver a Home do app. Ele verifica se o usuário já aceitou os termos; se não, redireciona para o fluxo de onboarding.
*   **`TermsPrivacyScreen` (`terms_privacy_screen.dart`)**: Tela obrigatória de aceite de Termos e Política.
*   **`ConsentScreen` (`consent_screen.dart`)**: Tela de consentimentos opcionais.

### 3. Menu & Navegação (`lib/menu/`)

Padroniza a navegação lateral.

*   **`AgroDrawer` (`agro_drawer.dart`)**: Menu lateral padrão (Drawer) contendo cabeçalho com versão, links para Home, Configurações, Privacidade e Sobre.
*   **`AgroDrawerItem`**: Item individual do menu.

### 4. Widgets Reutilizáveis (`lib/widgets/`)

Componentes visuais genéricos.

*   **`AgroCard` (`custom_card.dart`)**: Card padrão com estilização unificada.
*   **`AgroButton` (`primary_button.dart`)**: Botões primários e secundários padronizados.

### 5. Utils (`lib/utils/`)

Utilitários de formatação e lógica comum.

*   **`DateUtils`**: Formatadores de data e hora.
*   **`LocaleExtension`**: Extensões para facilitar o acesso ao Locale atual.

### 6. Screens Padrão (`lib/screens/`)

Telas comuns a todos os aplicativos.

*   **`AgroSettingsScreen`**: Tela de configurações gerais.
*   **`AgroAboutScreen`**: Tela "Sobre" que exibe versão e créditos.
*   **`AgroPrivacyScreen`**: Tela para rever/alterar as opções de privacidade após o onboarding.

### 7. Localization (`lib/l10n/`)

Gerenciamento de internacionalização (i18n).

*   **`AgroLocalizations`**: Classe gerada automaticamente (via `flutter_gen`) que fornece acesso às strings traduzidas (pt-BR e en).
*   **Arquivos ARB**: `lib/l10n/arb/app_pt.arb` e `app_en.arb` contêm os dicionários de tradução.
### 8. Location & Maps (`lib/screens/location_picker_screen.dart`)

Implementa seleção de localização geográfica.

*   **`LocationPickerScreen`**: Tela de seleção de localização estilo "WhatsApp/Uber" usando OpenStreetMap (`flutter_map`).

### 9. Autenticação (`lib/services/auth_service.dart`, `lib/screens/login_screen.dart`)

Gerencia a identidade do usuário.

*   **`AuthService`**: Wrapper para Firebase Auth. Implementa login Google, Anônimo e **Account Linking** (migração de anônimo para Google).
*   **`LoginScreen`**: Tela de login padrão. Detecta conflitos de conta e aciona o fluxo de migração de dados se necessário.

### 10. Gestão de Propriedades (`lib/services/property_service.dart`)

Núcleo de dados do produtor rural.

*   **`PropertyService`**: CRUD de Propriedades (Fazendas/Sítios) armazenado localmente via Hive. Suporta `transferData(oldUid, newUid)` para migração de contas.
*   **`TalhaoService`**: CRUD de Talhões vinculados a propriedades. Valida unicidade de nomes e soma de áreas.
*   **`AgroSelectPropertyScreen` / `AgroSelectTalhaoScreen`**: Telas de seleção para fluxos de cadastro.

### 11. Cloud Backup (`lib/services/cloud_backup_service.dart`)

Sistema de backup centralizado.

*   **`CloudBackupService`**: Serviço Singleton que orquestra o backup.
*   **`BackupProvider`**: Interface que cada App deve implementar para fornecer seus dados específicos (ex: `ChuvaBackupProvider`).
*   **Fluxo**: Gera um JSON unificado contendo dados do `agro_core` (Propriedades/Talhões) + dados dos Apps e envia para `users/{uid}/backup.json` no Firebase Storage.

### 12. LGPD Compliance (`lib/services/data_deletion_service.dart`, `data_export_service.dart`)

Implementa direitos do titular de dados conforme LGPD.

*   **`DataDeletionService`**: Serviço para exclusão total de dados (Art. 18 VI). Deleta Firestore, Firebase Auth e boxes Hive locais.
*   **`DataExportService`**: Serviço para portabilidade de dados (Art. 18 V). Exporta em JSON (completo) ou CSV (planilhas) e integra com Share Sheet nativo.
*   **UI em `AgroPrivacyScreen`**: Seção "Seus Direitos (LGPD)" com botões para exportar, excluir dados e revogar consentimentos.

### 13. Notificações (`lib/services/notification_service.dart`, `background_service.dart`)

Sistema de alertas locais e tarefas em segundo plano.

*   **`AgroNotificationService`**: Gerencia canais e exibição de notificações locais.
*   **`BackgroundService`**: Implementa tarefas periódicas (`workmanager`) para checar previsão do tempo e disparar alertas mesmo com app fechado.

### 14. Mapa de Calor (`lib/services/heatmap_service.dart`)

Visualização geoespacial de dados de chuva.

*   **`HeatmapService`**: Serviço para buscar dados agregados da comunidade (atualmente via Cloud Functions ou mock).
*   **`RainHeatmapScreen`**: Tela com Google Maps e overlays (`Circle`) para indicar intensidade de chuva.
