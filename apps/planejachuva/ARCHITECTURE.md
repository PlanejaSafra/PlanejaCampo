# Arquitetura do Apps (`apps/planeja_chuva`)

Este documento descreve objetivamente os arquivos e componentes do aplicativo **Planeja Chuva**.

## Arquivos de Configuração (.json)

*Nenhum arquivo de configuração .json encontrado na raiz ou em pastas padrão.*

---

## Arquivos de Código Fonte (.dart)

### `lib/main.dart`

Ponto de entrada do aplicativo.

#### Funções Públicas

*   **`main()`**
    *   **Função**: Inicializa o ambiente Flutter, banco de dados local (Hive) e loja de privacidade (`AgroPrivacyStore`). Inicia a execução do app.
    *   **Dependências**: `WidgetsFlutterBinding`, `Hive`, `AgroPrivacyStore`, `runApp`.

#### Classes

*   **`PlanejaChuvaApp` (StatelessWidget)**
    *   **Função**: Widget raiz do aplicativo. Configura temas (Light/Dark), locaização (pt-BR/en) e a rota inicial.
    *   **Dependências**:
        *   `MaterialApp`
        *   `AppTheme` (do `agro_core`)
        *   `AgroLocalizations` (do `agro_core`)
        *   `AgroOnboardingGate` (do `agro_core` - para fluxo de privacidade)
        *   `ListaChuvasScreen` (tela inicial)

### Fluxo de Inicialização e Privacidade
1.  **AuthGate**: Verifica se o usuário está autenticado.
    *   **Loading State**: Exibe spinner durante verificações e processos de login.
    *   **Restore Flow**: Ao logar (ou reiniciar), se o perfil local não existir, busca no Firestore (`fetchFromFirestore`) para restaurar consentimentos e metadados.
    *   **Implied Consent**: Login com Google implica `consentCloudBackup = true` (Termos de Uso).
    *   Se não logado: Mostra `LoginScreen` (Google/Anônimo).
2.  **AgroOnboardingGate**: Verifica estado de consentimento.
    *   Se `!hasAcceptedTerms`: Mostra `IdentityScreen` (Termos).
    *   Se `!onboardingCompleted`: Mostra `ConsentScreen` (3 Opções: Backup [Pré-ativado], Social, Inteligência).
    *   Se concluído: Mostra `ListaChuvasScreen` (Home).
3.  **Híbrido**:
    *   `SyncService`: Só envia dados se `AgroPrivacyStore.consentAggregateMetrics` for `true`.
    *   `UserCloudService`: Backup ativo implicitamente para usuários logados.

---

### `lib/screens/lista_chuvas_screen.dart`

Tela principal do aplicativo que exibe a lista de registros de chuva (atualmente MVP).

#### Classes

*   **`ListaChuvasScreen` (StatelessWidget)**
    *   **Função**: Exibe a interface principal com AppBar, Drawer lateral e área de conteúdo.
    *   **Métodos Públicos**:
        *   `build(BuildContext context)`: Constrói a UI usando `Scaffold`.
    *   **Métodos Privados**:
        *   `_handleNavigation(BuildContext, String)`: Gerencia a navegação a partir do Drawer (Home, Configurações, Privacidade, Sobre).
    *   **Dependências**:
        *   **Internas**: Nenhuma.
        *   **Externas (`agro_core`)**:
            *   `AgroDrawer`: Menu lateral padrão.
            *   `AgroRouteKeys`: Chaves para identificação de rotas de navegação.
            *   `AgroSettingsScreen`: Tela de configurações.
            *   `AgroAboutScreen`: Tela de sobre.
            *   `AgroPrivacyScreen`: Tela de privacidade.
            *   `AgroLocalizations`: Strings traduzidas.
