# 🚜 PlanejaCampo (Monorepo)

Bem-vindo ao repositório central da suíte de aplicativos **PlanejaCampo**.

Este projeto utiliza uma arquitetura de **Monorepo** para gerenciar múltiplos micro-apps focados no agronegócio. Todos compartilham um núcleo comum de tecnologia e design (`agro_core`), mas funcionam como produtos independentes, leves e 100% offline.

---

## 🏗️ Estrutura do Projeto

    PlanejaCampo/
    │
    ├── apps/                          # 📱 Os Aplicativos (Produtos Finais)
    │   ├── planeja_chuva/             # Pluviômetro Rural
    │   ├── planeja_diesel/            # Controle de Abastecimento e Frota
    │   ├── planeja_borracha/          # Gestão de Sangria e Preço
    │   └── planeja_vaca/              # Calculadora de Engorda e Lucro
    │
    ├── packages/                      # 📦 Módulos Compartilhados
    │   └── agro_core/                 # UI Kit, Temas, Formatadores e Utils
    │
    └── examples/                      # 🏛️ Referências
        └── planeja_campo/             # Projeto legado (Monolito) para consulta

---

## 🚀 Como Rodar um App

Como este é um monorepo, você deve entrar na pasta do aplicativo específico que deseja trabalhar.
**Não rode comandos na raiz.**

### Passo a Passo

1. **Navegue até o app desejado:**

```
cd apps/planeja_chuva
# ou cd apps/planeja_diesel, etc.
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

* **Organization ID:** `br.com.planejacampo`
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

### Criar um Novo App (futuro)

Se precisar criar um 5º app, use o padrão de organização correto:

```
cd apps
flutter create --org br.com.planejacampo planeja_novo_app
```

### Vincular o Core a um Novo App

Para o novo app enxergar a pasta `packages`:

```
cd apps/planeja_novo_app
flutter pub add agro_core --path ../../packages/agro_core
```

### Limpar Tudo (se der erro de cache)

Se o Flutter se perder com as referências locais:

```
flutter clean
flutter pub get
```

---

## 📝 Status do Desenvolvimento

| App                  | Função                   | Status                      |
| -------------------- | ------------------------ | --------------------------- |
| **Planeja Chuva**    | Registro de Pluviometria | 🚧 Em Desenvolvimento (MVP) |
| **Planeja Diesel**   | Abastecimento e Média    | ⏳ Aguardando                |
| **Planeja Borracha** | Coleta e Preço Médio     | ⏳ Aguardando                |
| **Planeja Vaca**     | Calculadora de Engorda   | ⏳ Aguardando                |

---

Desenvolvido com 💚 para o Agronegócio.


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

O `agro_core` fornece um sistema completo de gerenciamento de propriedades/fazendas que é **compartilhado entre todos os apps** da suíte PlanejaSafra.

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

### ✅ Exemplo (Planeja Chuva)

No `apps/planeja_chuva/lib/main.dart`:

- inicializar Hive (`Hive.initFlutter()`)
- chamar `AgroPrivacyStore.init()`
- usar `AgroOnboardingGate(home: ListaChuvasScreen())`

Isso garante que nenhum app seja publicado sem o fluxo legal mínimo de privacidade.
