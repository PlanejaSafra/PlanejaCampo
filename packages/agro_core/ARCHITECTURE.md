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
### 8. Location & Maps
- **`LocationPickerScreen` (`lib/screens/location_picker_screen.dart`)**: Tela de seleção de localização estilo "WhatsApp/Uber" usando OpenStreetMap (`flutter_map`).
