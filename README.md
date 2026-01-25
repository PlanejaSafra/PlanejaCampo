# 🚜 RuraCamp (Monorepo)

Welcome to the central repository for the **RuraCamp** app suite.

This project uses a **Monorepo** architecture to manage multiple micro-apps focused on agriculture. All apps share a common technology and design core (`agro_core`), but function as independent, lightweight, and 100% offline products.

---

## 🏗️ Project Structure

    RuraCamp/
    │
    ├── apps/                          # 📱 Applications (Final Products)
    │   ├── rurarain/                  # Rural Pluviometer (com.ruracamp.rain)
    │   ├── rurarubber/                # Rubber Weighing & Market (com.ruracamp.rubber)
    │   ├── ruracattle/                # Cattle Management (com.ruracamp.cattle)
    │   └── rurafuel/                  # Fuel Consumption Control (com.ruracamp.fuel)
    │
    ├── packages/                      # 📦 Shared Modules
    │   └── agro_core/                 # UI Kit, Themes, Formatters and Utils
    │
    └── examples/                      # 🏛️ References
        └── planejacampo/              # Legacy project (Monolith) for reference

---

## 🚀 How to Run an App

Since this is a monorepo, you must enter the specific app folder you want to work with.
**Don't run commands from the root.**

### Step by Step

1. **Navigate to the desired app:**

```
cd apps/rurarain
# or cd apps/rurarubber, etc.
```

2. **Instale as dependências:**

Isso baixará as libs do app e vinculará automaticamente o `agro_core` local.

```
flutter pub get
```

3. **Gere os códigos do Banco de Dados (Hive):**

Passo obrigatório na primeira execução ou sempre que alterar um `Model`.

```
dart run build_runner build --delete-conflicting-outputs
```

4. **Rode o App:**

```
flutter run
```

---

## 📦 Arquitetura Técnica

### 1) Apps (`/apps`)

Cada app é um projeto Flutter completo e independente.

* **Organization ID:** `com.ruracamp`
* **Banco de Dados:** Hive (NoSQL local)
* **Dependências:** apenas o necessário para aquela função específica

---

### 2) Core (`/packages/agro_core`)

É a biblioteca visual e utilitária compartilhada.
O Core **não sabe** o que é chuva ou gado — ele só fornece as ferramentas para montar as telas.

* **Theme:** identidade visual verde/agro (AppTheme)
* **Widgets:** `AgroCard`, `AgroButton`, `AgroInput`, `EmptyState`, etc
* **Utils:** formatadores de Data/Moeda, helpers e validações
* **Shell padrão:** `AgroScaffold` (AppBar + Drawer/Menu + Body + FAB opcional)
* **Menu padrão:** Home, Configurações, Privacidade/Consentimentos, Sobre, Propriedades
* **Privacidade:** fluxo obrigatório de 2 telas (Identidade + Consentimentos)
* **Propriedades:** gerenciamento de fazendas/propriedades com compartilhamento entre apps
* **l10n (pt-BR/en):** strings padrão no core reutilizadas por todos os apps

#### 🎨 Padrão Visual e Navegação (OBRIGATÓRIO)

Todos os apps em `apps/*` **DEVEM seguir o padrão do core**.

**Regra de ouro:**

* O app **NÃO cria** tema, AppBar, Drawer/Menu, layout base ou navegação padrão.
* O app **apenas implementa** telas do domínio (chuva, diesel, etc) e pluga no shell do core.

**O app pode:**

* criar telas específicas (`screens/`)
* criar models específicos (`models/`)
* adicionar itens extras no menu (**sem alterar o padrão base**)

---

### 📁 Estrutura mínima de cada app (`apps/*`)

Cada app deve ter **somente o que é específico dele**:

* `lib/main.dart`
* `lib/screens/`
* `lib/models/`
* `lib/features/` (opcional)
* `lib/routes.dart` (se precisar, apenas rotas do app)

Tudo que é “padrão de produto” fica no **agro_core**:

* tema
* widgets base
* navegação e menu padrão
* onboarding/privacidade
* telas padrão (configurações/sobre/consentimentos)
* l10n comum

---


### 3) Exemplos (`/examples`)

O diretório `examples` contém um **app monolítico completo** (`planeja_campo`).
Este projeto serve como referência rica, contendo várias classes, arquivos e implementações de regra de negócio que podem ser reutilizados ou consultados como exemplo durante o desenvolvimento dos novos micro-apps.

### 4) Estratégia de Dados (Offline First)

O sistema foi desenhado para funcionar na fazenda, sem sinal de internet.

* **Principal (Hot Storage):** Todo o funcionamento depende exclusivamente do **Hive** local no dispositivo.
* **Backup (Cold Storage):**
    * **MVP:** Exportação manual de arquivo `.json` (o usuário compartilha para WhatsApp/Google Drive).
    * **Futuro:** Upload automático desse arquivo para nuvem (Firebase Storage) quando houver Wi-Fi.
    * *Nota:* Não realizamos sincronização em tempo real (sync) para evitar conflitos e complexidade. O dado mestre é sempre o do celular.
* **Regra:** **NUNCA usar subcoleções**. Mantenha a estrutura de dados sempre "flat" (coleções/boxes na raiz).

---

## 🛠️ Comandos Úteis de Manutenção

### Create a New App (future)

If you need to create a 5th app, use the correct organization pattern:

```
cd apps
flutter create --org com.ruracamp rura_new_app
```

### Link Core to a New App

For the new app to see the `packages` folder:

```
cd apps/rura_new_app
flutter pub add agro_core --path ../../packages/agro_core
```

### Limpar Tudo (se der erro de cache)

Se o Flutter se perder com as referências locais:

```
flutter clean
flutter pub get
```

---

## 📝 Development Status

| App            | Function                    | Status                      |
| -------------- | --------------------------- | --------------------------- |
| **RuraRain**   | Rainfall Recording          | ✅ MVP Ready                |
| **RuraRubber** | Rubber Weighing & Market    | ✅ MVP Ready                |
| **RuraCattle** | Cattle Management           | 🚧 Skeleton                 |
| **RuraFuel**   | Fuel Consumption Control    | 🚧 Skeleton                 |

---

Developed with 💚 for Agriculture.


## 🔐 Privacidade e Consentimento (OBRIGATÓRIO em todo app)

Todos os apps em `apps/*` devem usar o fluxo padrão de privacidade do `packages/agro_core`.

Esse fluxo possui **duas telas**:

1) **Termos de Uso + Política de Privacidade (obrigatória)**
   - Sem aceitar, o usuário não entra no app.

2) **Consentimentos opcionais (não bloqueia o uso)**
   - “Aceitar e continuar” ativa recursos extras
   - “Não aceitar” entra do mesmo jeito (modo básico/offline)

✅ Isso é implementado **uma única vez no core**, e cada app apenas integra no `main.dart`.

---

## 🏞️ Gerenciamento de Propriedades (Multi-Propriedade)

The `agro_core` provides a complete property/farm management system that is **shared across all apps** in the RuraCamp suite.

### Características:

* **Property Model:** Modelo com nome, área total, localização GPS (opcional)
* **PropertyService:** CRUD completo com filtro por userId (Firebase Auth)
* **Cross-App Sharing:** Propriedades criadas em um app ficam disponíveis em todos os outros
* **Auto-Creation:** Propriedade padrão ("Minha Propriedade") criada automaticamente
* **PropertyHelper:** Singleton com cache para lookups otimizados de nomes
* **UI Completa:** Telas de listagem e formulário já prontas no core
* **Native Map Picker:** Seletor de localização offline usando OpenStreetMap (estilo WhatsApp)

### Como usar nos apps:

1. **Initialize PropertyService** no `main.dart`:
```dart
await PropertyService().init();
```

2. **Link records to properties** - cada registro de negócio deve ter um `propertyId`:
```dart
final defaultProperty = await PropertyService().ensureDefaultProperty();
final record = RegistroChuva.novo(
  data: DateTime.now(),
  milimetros: 10.5,
  propertyId: defaultProperty.id, // Link para propriedade
);
```

3. **Display property names** usando o PropertyHelper:
```dart
final propertyName = PropertyHelper().getPropertyName(record.propertyId);
```

4. **Navigation** - o menu Drawer já inclui "Propriedades", basta adicionar o case de navegação:
```dart
case AgroRouteKeys.properties:
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => PropertyListScreen(),
  ));
```

### Migração Automática

Apps existentes com dados antigos (sem propertyId) devem usar o **MigrationService** na primeira execução:

```dart
await MigrationService.migrateToPropertySystem();
```

Isso vincula automaticamente todos os registros antigos à propriedade padrão, sem perda de dados.

---

### ✅ Example (RuraRain)

In `apps/rurarain/lib/main.dart`:

- inicializar Hive (`Hive.initFlutter()`)
- chamar `AgroPrivacyStore.init()`
- usar `AgroOnboardingGate(home: ListaChuvasScreen())`

Isso garante que nenhum app seja publicado sem o fluxo legal mínimo de privacidade.
