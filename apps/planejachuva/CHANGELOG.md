# CHANGELOG - planeja_chuva

---

## Análise Crítica da Proposta

### Pontos Fortes da Proposta Original

1. **Foco no MVP**: Separação clara entre funcionalidades essenciais e futuras
2. **Offline-First**: Alinhado com a realidade do campo (sem internet)
3. **Estrutura de Fases**: Organização lógica e incremental
4. **Integração com Core**: Reutilização de componentes (tema, menu, privacidade)

### Críticas e Melhorias Propostas

#### 1. Complexidade Desnecessária
- **UUID**: Para um app local, UUID é overkill. Usar `DateTime.now().millisecondsSinceEpoch` como ID é mais simples e suficiente.
- **ValueListenableBuilder**: Adiciona complexidade. Para MVP, `setState` após operações CRUD é mais simples e entendível.
- **Repository Pattern**: Para um app simples, acesso direto ao Hive Box é suficiente. Repository pode vir depois se necessário.

#### 2. Priorização do Usuário Final
- **Homem do Campo**: Interface deve ter botões GRANDES, textos LEGÍVEIS, fluxos CURTOS.
- **Registro Rápido**: O registro de chuva deve ser possível em NO MÁXIMO 3 toques (FAB → valor → salvar).
- **Data Padrão**: SEMPRE defaultar para HOJE. 90% dos registros são "acabou de chover".

#### 3. Funcionalidades Repensadas
- **Gráficos (fl_chart)**: ADIAR. Complexidade de dependência e manutenção. MVP deve mostrar números simples.
- **Backup JSON**: Simplificar. Exportar como texto simples que pode ser copiado/colado no WhatsApp.
- **Filtros Avançados**: ADIAR. Para MVP, scroll infinito com separadores de mês é suficiente.

#### 4. Decisões Técnicas Simplificadas
- **State Management**: Nenhum package extra. `StatefulWidget` + `setState` para MVP.
- **Navegação**: `Navigator.push/pop` simples. Sem GoRouter.
- **Formulários**: Validação inline simples, sem packages de forms.

### Princípios de Design para o Homem do Campo

1. **Menos é Mais**: Cada tela deve ter UM propósito claro
2. **Feedback Visual**: Cores fortes, ícones grandes, confirmações visuais
3. **Tolerância a Erros**: Confirmação antes de deletar, desfazer quando possível
4. **Modo Noturno**: Produtor acorda cedo, pode registrar às 5h da manhã

---

## 📊 ANÁLISE REVISADA DE PROPOSTAS FUTURAS

### Arquitetura Híbrida: Offline-First + Sync Opcional

**Princípio Revisado**:
- **Core = 100% Offline**: Registrar, editar, visualizar chuvas funciona SEM internet
- **Features Extras = Online Opcional**: Tentam usar internet quando disponível, degradam elegantemente quando offline
- **Timeout Agressivo**: Operações de rede com timeout de 2-3s (não trava o app)

---

### Propostas Recebidas vs. Princípios do App

#### ✅ APROVADAS COM ARQUITETURA HÍBRIDA

**Proposta: Estatísticas Regionais (Firestore + Sync Opcional)**
- **Status**: ✅ Aceita com arquitetura revisada
- **Abordagem**:
  - **Firestore Offline Mode**: Cache local automático
  - **Sync quando Online**: Envia dados anonimizados em background (Wi-Fi only por padrão)
  - **Timeout Agressivo**: 2-3 segundos para escrita, continua offline se falhar
  - **Consentimento**: Só envia se usuário aceitar explicitamente (opt-in)
- **Vantagens**:
  - Firestore SDK gerencia complexidade (cache, retry, conflict resolution)
  - Sem backend custom (usa regras de segurança do Firestore)
  - Cold start resolvido com dados do INMET/NASA Power como fallback
- **Implementação**: Phase 15.0 (após MVP consolidado)

**Proposta: Previsão do Tempo (Open-Meteo + Cache Agressivo)**
- **Status**: ✅ Aceita com cache e degradação elegante
- **Abordagem**:
  - **Cache Local**: Salva última previsão no Hive (válida por 6h)
  - **Timeout Curto**: 3 segundos para buscar nova previsão
  - **Fallback Gracioso**: Se offline ou timeout, mostra cache + aviso "Última atualização: X horas atrás"
  - **Sem Bloqueio**: Widget aparece/desaparece sem afetar resto do app
- **Vantagens**:
  - Agrega muito valor (produtor decide quando irrigar/colher)
  - API gratuita e sem chave de API
  - Não degrada experiência core
- **Implementação**: Phase 14.0 (antes de estatísticas regionais)

**Proposta: Cadastro de Propriedade e Localização**
- **Status**: ✅ Aceita como pré-requisito
- **Modificações**:
  - **Obrigatório para features online**: Previsão e estatísticas precisam de lat/lon
  - **Opcional para uso offline**: Pode pular e usar apenas modo local
  - **GPS Simples**: Botão "Capturar Localização Atual" ou busca por cidade
  - **Sem validação complexa**: Salva no Hive, não envia para servidor
- **Implementação**: Phase 14.0.1 (sub-fase de Previsão do Tempo)

---

#### ⚠️ MANTIDAS NO ROADMAP ORIGINAL (Sem Mudanças)

**Phases 8.0 a 13.0**: Permanecem como planejado (100% offline, sem dependências externas)

---

## 🚀 ROADMAP REALISTA (Próximas Fases)

### Critérios de Seleção
1. ✅ Funciona 100% offline
2. ✅ Agrega valor imediato ao produtor
3. ✅ Baixa complexidade técnica
4. ✅ Sem dependências externas críticas

---

## Phase 15.0: Estatísticas Regionais (Firestore + Crowdsourcing)

### Status: [TODO]
**Prioridade**: 🟡 DIFERENCIAL
**Objetivo**: Comparar chuva da propriedade com média da região usando Firestore.

### Arquitetura de Sync Híbrido

**Firestore Collections**:
```
rainfall_data/
  └── {geoHash5}/ (área ~5km x 5km)
      └── records/
          └── {userId_timestamp}: {mm, date, lat, lon}
```

**Regras de Segurança Firestore**:
- Escrita: Apenas dados anonimizados (sem identificação pessoal)
- Leitura: Apenas dados agregados (médias, não registros individuais)
- Rate limit: Max 10 escritas/dia por usuário

### Fluxo de Sync

1. **Opt-In**: Usuário ativa "Compartilhar dados anônimos" nas Configurações
2. **Background Sync**: Job roda apenas em Wi-Fi, tenta enviar registros pendentes
3. **Timeout**: 2-3s por escrita, continua offline se falhar
4. **Agregação**: Cloud Function calcula médias por GeoHash
5. **Exibição**: Tela comparativa "Minha Chuva vs Região"

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 15.0.1 | Add cloud_firestore dependency | ⏳ TODO |
| 15.0.2 | Create SyncService with Firestore offline mode | ⏳ TODO |
| 15.0.3 | Add opt-in consent in Settings | ⏳ TODO |
| 15.0.4 | Create background sync job (Wi-Fi only) | ⏳ TODO |
| 15.0.5 | Create RegionalStatsScreen | ⏳ TODO |
| 15.0.6 | Deploy Cloud Function for aggregation | ⏳ TODO |
| 15.0.7 | Configure Firestore security rules | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/sync_service.dart` | CREATE | Firestore sync with offline mode |
| `lib/models/regional_data.dart` | CREATE | Model for aggregated data |
| `lib/screens/regional_stats_screen.dart` | CREATE | Comparison screen |
| `pubspec.yaml` | MODIFY | Add cloud_firestore |
| `firebase/functions/aggregate.js` | CREATE | Cloud Function for stats |

### Considerações de Privacidade

- **Dados Enviados**: Apenas {lat, lon, mm, date} - SEM nome, fazenda, device ID
- **GeoHash**: Reduz precisão para ~5km (não identifica propriedade exata)
- **Opt-Out**: Usuário pode desativar e deletar dados enviados
- **Transparência**: Mostrar quantos usuários contribuíram ("Baseado em X propriedades")

---

## Phase 14.0: Previsão do Tempo (Open-Meteo + Cache)

### Status: [TODO]
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Exibir previsão meteorológica para localização cadastrada.

### Arquitetura de Cache Agressivo

**Open-Meteo API**:
- Endpoint: `https://api.open-meteo.com/v1/forecast`
- Parâmetros: `latitude`, `longitude`, `daily=precipitation_sum,temperature_2m_max`
- Gratuito, sem chave de API, 10,000 requests/dia

**Estratégia de Cache**:
1. **Cache Local (Hive)**: Salva última previsão com timestamp
2. **Validade**: 6 horas (previsão muda pouco em curto prazo)
3. **Timeout**: 3 segundos para fetch
4. **Fallback**: Mostra cache antigo + aviso "Atualizado há X horas"

### Fluxo de UX

1. **Home Screen**: Widget compacto "Previsão: 🌧️ 15mm hoje"
2. **Tap**: Abre modal com próximos 5 dias
3. **Pull-to-Refresh**: Tenta buscar nova previsão
4. **Offline**: Mostra cache + badge "Offline"

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 14.0.1 | Create PropriedadeSettings model with lat/lon | ⏳ TODO |
| 14.0.2 | Create PropriedadeConfigScreen (GPS + city search) | ⏳ TODO |
| 14.0.3 | Create WeatherService with Open-Meteo integration | ⏳ TODO |
| 14.0.4 | Create WeatherForecast model + cache in Hive | ⏳ TODO |
| 14.0.5 | Create WeatherCard widget for home | ⏳ TODO |
| 14.0.6 | Create WeatherDetailScreen (5 days) | ⏳ TODO |
| 14.0.7 | Add geolocator and http dependencies | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/propriedade_settings.dart` | CREATE | Hive model for location |
| `lib/models/propriedade_settings.g.dart` | GENERATE | Hive adapter |
| `lib/models/weather_forecast.dart` | CREATE | Forecast data model |
| `lib/models/weather_forecast.g.dart` | GENERATE | Hive adapter (for cache) |
| `lib/services/weather_service.dart` | CREATE | Open-Meteo HTTP client |
| `lib/screens/propriedade_config_screen.dart` | CREATE | Location setup |
| `lib/widgets/weather_card.dart` | CREATE | Home screen widget |
| `lib/screens/weather_detail_screen.dart` | CREATE | 5-day forecast |
| `pubspec.yaml` | MODIFY | Add geolocator, http |

### Model: PropriedadeSettings

| Campo | Tipo | Descrição |
|-------|------|-----------|
| farmName | String? | Nome da fazenda (opcional) |
| latitude | double? | Coordenada GPS |
| longitude | double? | Coordenada GPS |
| cityName | String? | Nome da cidade (fallback) |
| setupCompleted | bool | Se configurou localização |

### Model: WeatherForecast

| Campo | Tipo | Descrição |
|-------|------|-----------|
| date | DateTime | Data da previsão |
| precipitationMm | double | Chuva prevista (mm) |
| temperatureMax | double | Temperatura máxima (°C) |
| cachedAt | DateTime | Quando foi salvo no cache |

---

## Phase 13.0: Visualizações Simples de Tendências

### Status: [TODO]
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Mostrar padrões visuais simples SEM usar fl_chart (complexo demais).

### Justificativa
Produtor precisa ver "está chovendo mais ou menos que o normal?" de forma visual, mas gráficos complexos são overkill para MVP.

### Abordagem Simplificada
- **Barras ASCII/Unicode**: Gráfico de barras usando caracteres `█ ▓ ▒ ░`
- **Indicadores de Cor**: Cards coloridos (verde = acima da média, vermelho = abaixo)
- **Tabelas Mensais**: Grid 12 meses com totais lado a lado (ano atual vs anterior)

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 13.0.1 | Create VisualizacaoBarrasWidget (ASCII bars) | ⏳ TODO |
| 13.0.2 | Create ComparacaoAnualCard (year vs year table) | ⏳ TODO |
| 13.0.3 | Add visual cues (color-coded months) | ⏳ TODO |
| 13.0.4 | Add to EstatisticasScreen as tabs | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/visualizacao_barras.dart` | CREATE | ASCII/Unicode bar charts |
| `lib/widgets/comparacao_anual_card.dart` | CREATE | Year comparison table |
| `lib/screens/estatisticas_screen.dart` | MODIFY | Add tabs for visualizations |

---

## Phase 12.0: Exportação Avançada (PDF/CSV)

### Status: [TODO]
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Gerar relatórios profissionais para impressão ou análise externa.

### Contexto
Produtor pode precisar levar dados para banco (financiamento), seguradora (sinistro), ou agrônomo (consultoria).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 12.0.1 | Add pdf package dependency | ⏳ TODO |
| 12.0.2 | Create ExportService with PDF generation | ⏳ TODO |
| 12.0.3 | Create CSV export (Excel-compatible) | ⏳ TODO |
| 12.0.4 | Add export options to BackupScreen | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/export_service.dart` | CREATE | PDF/CSV generation logic |
| `lib/screens/backup_screen.dart` | MODIFY | Add export format options |
| `pubspec.yaml` | MODIFY | Add pdf package |

---

## Phase 11.0: Notificações Locais (Lembretes)

### Status: [TODO]
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Lembrar usuário de registrar chuva (ex: "Você registrou a chuva de hoje?").

### Justificativa
Produtor pode esquecer de registrar no dia. Lembrete às 18h aumenta adesão.

### Abordagem Offline-First
- **flutter_local_notifications**: Sem backend, sem push notification (FCM)
- **Agendamento Local**: Repetição diária, mesmo com app fechado
- **Inteligente**: Não notificar se já registrou hoje

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 11.0.1 | Add flutter_local_notifications dependency | ⏳ TODO |
| 11.0.2 | Create NotificationService (local only) | ⏳ TODO |
| 11.0.3 | Add settings toggle (Enable/Disable reminders) | ⏳ TODO |
| 11.0.4 | Add time picker for reminder schedule | ⏳ TODO |
| 11.0.5 | Smart skip (don't notify if already logged today) | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/notification_service.dart` | CREATE | Local notification logic |
| `packages/agro_core/lib/screens/agro_settings_screen.dart` | MODIFY | Add reminder settings |
| `pubspec.yaml` | MODIFY | Add flutter_local_notifications |

---

## Phase 10.0: Validação Inteligente e Alertas

### Status: [TODO]
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Prevenir erros de digitação e alertar sobre anomalias.

### Contexto
Produtor pode digitar 100mm em vez de 10mm (erro de zero). App deve alertar quando valor for incomum.

### Lógica de Validação

| Validação | Descrição | Threshold |
|-----------|-----------|-----------|
| Chuva Extrema | Alerta se > 100mm em 1 dia | "Confirma? Chuva muito forte" |
| Duplicata Temporal | Alerta se já existe registro nas últimas 2h | "Já registrou hoje às 14h" |
| Seca Prolongada | Aviso se não chove há > 30 dias | "Atenção: 45 dias sem chuva" |

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 10.0.1 | Add validation in AdicionarChuvaScreen | ⏳ TODO |
| 10.0.2 | Create ValidationService with threshold checks | ⏳ TODO |
| 10.0.3 | Add confirmation dialogs for extreme values | ⏳ TODO |
| 10.0.4 | Add drought alert in home screen | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/services/validation_service.dart` | CREATE | Threshold and anomaly detection |
| `lib/screens/adicionar_chuva_screen.dart` | MODIFY | Add smart validations |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Show drought alert |

---

## Phase 9.0: Melhorias de UX e Acessibilidade

### Status: [TODO]
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Otimizar para "Homem do Campo" (botões grandes, feedback tátil, modo de alto contraste).

### Princípios de Design (Revisitados)
1. **Botões Grandes**: Mínimo 56x56dp (dedos sujos/calejados)
2. **Feedback Tátil**: Vibração ao salvar/deletar
3. **Alto Contraste**: Modo específico para sol forte (tela visível ao ar livre)
4. **Modo Noturno Automático**: Escurece após 18h (produtor acorda às 5h)

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 9.0.1 | Increase FAB and button sizes (56dp minimum) | ⏳ TODO |
| 9.0.2 | Add haptic feedback (vibration) on actions | ⏳ TODO |
| 9.0.3 | Create high-contrast theme variant | ⏳ TODO |
| 9.0.4 | Add auto dark mode based on time | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `packages/agro_core/lib/theme/agro_theme.dart` | MODIFY | Add high-contrast theme |
| `lib/screens/*.dart` | MODIFY | Increase button sizes |
| `packages/agro_core/lib/screens/agro_settings_screen.dart` | MODIFY | Add accessibility settings |

---

## Phase 8.0: Persistência de Preferências do Usuário

### Status: [TODO]
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Salvar escolhas do usuário (idioma, tema, nome da fazenda) entre sessões.

### Contexto
Atualmente, a escolha de idioma não persiste (Phase 7.0 foi implementada sem persistência). Usuário precisa reescolher a cada abertura do app.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 8.0.1 | Create UserPreferences Hive model | ⏳ TODO |
| 8.0.2 | Save locale choice in preferences | ⏳ TODO |
| 8.0.3 | Save theme mode (light/dark/auto) | ⏳ TODO |
| 8.0.4 | Add optional farm name field | ⏳ TODO |
| 8.0.5 | Load preferences on app start | ⏳ TODO |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/models/user_preferences.dart` | CREATE | Hive model for settings |
| `lib/models/user_preferences.g.dart` | GENERATE | Hive adapter |
| `lib/main.dart` | MODIFY | Load preferences on startup |
| `packages/agro_core/lib/screens/agro_settings_screen.dart` | MODIFY | Save changes to Hive |

### Model: UserPreferences

| Campo | Tipo | Descrição |
|-------|------|-----------|
| locale | String? | 'pt_BR', 'en', or null (auto) |
| themeMode | String | 'light', 'dark', 'auto' |
| farmName | String? | Nome opcional da propriedade |
| reminderEnabled | bool | Habilitar lembretes (default: false) |
| reminderTime | String? | Horário do lembrete (HH:mm) |

---

## Phase 7.0: Seleção Manual de Idioma

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Permitir ao usuário escolher idioma manualmente (PT-BR/EN) sem persistência.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 7.0.1 | Add locale state management in main.dart | ✅ DONE |
| 7.0.2 | Update AgroSettingsScreen with language dialog | ✅ DONE |
| 7.0.3 | Add RadioListTile for language selection | ✅ DONE |
| 7.0.4 | Implement NumberFormat for locale-aware formatting | ✅ DONE |
| 7.0.5 | Fix decimal separator (comma/dot) across all widgets | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/main.dart` | MODIFY | StatefulWidget with locale state |
| `packages/agro_core/lib/screens/agro_settings_screen.dart` | MODIFY | Language selection dialog |
| `lib/widgets/*.dart` | MODIFY | NumberFormat for locale-aware numbers |
| `lib/screens/estatisticas_screen.dart` | MODIFY | Format numbers with locale |

### Note
Language choice is NOT persisted - app always starts in Auto mode (follows system).

---

## Phase 7.1: Padronização de Labels Android (Monorepo-Wide)

### Status: [DONE]
**Date Completed**: 2026-01-18
**Prioridade**: 🔵 FIX
**Objetivo**: Eliminar hardcoded app labels nos AndroidManifest.xml de todos os apps do monorepo, garantindo l10n.

### Context
Durante revisão do código, foi identificado que enquanto **planejachuva** já usa `@string/app_name` (configurado em Phase 6.2), os outros três apps (**planejavavaca**, **planejaaborracha**, **planejadiesel**) ainda possuem labels hardcoded diretamente no `AndroidManifest.xml`:

- `planejavavaca`: Hardcoded "Planeja Vaca"
- `planejaaborracha`: Hardcoded "Planeja Borracha"
- `planejadiesel`: Hardcoded "Planeja Diesel"

Isso viola a regra de **l10n obrigatória** do projeto (ver `CLAUDE.md` item 6).

### Solution
Criar arquivos `strings.xml` para cada app em `android/app/src/main/res/values/` (EN) e `values-pt-rBR/` (PT-BR), seguindo o padrão já implementado em `planejachuva`.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 7.1.1 | Create values/strings.xml for planejavavaca | ✅ DONE |
| 7.1.2 | Create values-pt-rBR/strings.xml for planejavavaca | ✅ DONE |
| 7.1.3 | Update AndroidManifest.xml for planejavavaca | ✅ DONE |
| 7.1.4 | Create values/strings.xml for planejaaborracha | ✅ DONE |
| 7.1.5 | Create values-pt-rBR/strings.xml for planejaaborracha | ✅ DONE |
| 7.1.6 | Update AndroidManifest.xml for planejaaborracha | ✅ DONE |
| 7.1.7 | Create values/strings.xml for planejadiesel | ✅ DONE |
| 7.1.8 | Create values-pt-rBR/strings.xml for planejadiesel | ✅ DONE |
| 7.1.9 | Update AndroidManifest.xml for planejadiesel | ✅ DONE |

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `apps/planejavavaca/android/app/src/main/res/values/strings.xml` | CREATE | English app name |
| `apps/planejavavaca/android/app/src/main/res/values-pt-rBR/strings.xml` | CREATE | Portuguese app name |
| `apps/planejavavaca/android/app/src/main/AndroidManifest.xml` | MODIFY | Use @string/app_name |
| `apps/planejaaborracha/android/app/src/main/res/values/strings.xml` | CREATE | English app name |
| `apps/planejaaborracha/android/app/src/main/res/values-pt-rBR/strings.xml` | CREATE | Portuguese app name |
| `apps/planejaaborracha/android/app/src/main/AndroidManifest.xml` | MODIFY | Use @string/app_name |
| `apps/planejadiesel/android/app/src/main/res/values/strings.xml` | CREATE | English app name |
| `apps/planejadiesel/android/app/src/main/res/values-pt-rBR/strings.xml` | CREATE | Portuguese app name |
| `apps/planejadiesel/android/app/src/main/AndroidManifest.xml` | MODIFY | Use @string/app_name |

### App Names (Localized)

| App | English (values/) | Português (values-pt-rBR/) |
|-----|-------------------|---------------------------|
| planejavavaca | Planeja Cattle | Planeja Vaca |
| planejaaborracha | Planeja Rubber | Planeja Borracha |
| planejadiesel | Planeja Diesel | Planeja Diesel |

---

## Phase 6.2: Configuração de Ambientes (Flavors)

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🟡 ARCHITECTURAL
**Objetivo**: Separar configurações de DEV e PRD (Google Services e nomes de app).

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.2.1 | Configure productFlavors (dev, prod) in gradle | ✅ DONE |
| 6.2.2 | Create src/dev and src/prod directories | ✅ DONE |
| 6.2.3 | Move google-services.json to src/dev | ✅ DONE |
| 6.2.4 | Update Manifest to use dynamic @string/app_name | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `android/app/build.gradle` | MODIFY | Added flavors and resValues |
| `AndroidManifest.xml` | MODIFY | Changed label to @string/app_name |
| `android/app/src/dev/google-services.json` | MOVE | Moved from app root |

---

## Phase 6.1: Configuração Google Services

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🔵 FIX
**Objetivo**: Configurar dependências do Google Services para suportar funcionalidades do Firebase.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.1.1 | Add google-services classpath (4.4.4) to project gradle | ✅ DONE |
| 6.1.2 | Apply google-services plugin to app gradle | ✅ DONE |
| 6.1.3 | Add Firebase BoM (34.8.0) and Analytics | ✅ DONE |
| 6.1.4 | Verify google-services.json placement | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `android/build.gradle` | MODIFY | Added Google Services classpath |
| `android/app/build.gradle` | MODIFY | Added plugins and dependencies |

---

## Phase 6.0: Backup e Compartilhamento

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Permitir exportar e importar dados de chuva de forma simples.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 6.0.1 | Create BackupService with export/import JSON | ✅ DONE |
| 6.0.2 | Create BackupScreen with export/import UI | ✅ DONE |
| 6.0.3 | Add share_plus and file_picker dependencies | ✅ DONE |
| 6.0.4 | Add Backup menu item in drawer | ✅ DONE |
| 6.0.5 | Text summary export for WhatsApp | ✅ DONE |
| 6.0.6 | Duplicate detection on import | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/services/backup_service.dart` | CREATE | Export/import JSON logic with share_plus |
| `lib/screens/backup_screen.dart` | CREATE | Backup screen with export/import buttons |
| `pubspec.yaml` | MODIFY | Added share_plus, file_picker, path_provider |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Added Backup drawer item |

---

## Phase 5.0: Resumos e Estatísticas Simples

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🟢 ENHANCEMENT
**Objetivo**: Mostrar informações úteis sobre o histórico de chuvas sem gráficos complexos.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 5.0.1 | Create ResumoMensalCard widget | ✅ DONE |
| 5.0.2 | Create EstatisticasScreen with all stats | ✅ DONE |
| 5.0.3 | Add monthly summary to home screen | ✅ DONE |
| 5.0.4 | Add month comparison indicator | ✅ DONE |
| 5.0.5 | Add Statistics menu item in drawer | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/resumo_mensal_card.dart` | CREATE | Monthly total card with comparison |
| `lib/screens/estatisticas_screen.dart` | CREATE | Full statistics screen |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Added summary card and stats menu |

---

## Phase 4.0: Edição e Exclusão de Registros

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Permitir corrigir erros e remover registros incorretos.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 4.0.1 | Create EditarChuvaScreen | ✅ DONE |
| 4.0.2 | Implement delete with confirmation dialog | ✅ DONE |
| 4.0.3 | Add undo functionality via SnackBar | ✅ DONE |
| 4.0.4 | Add swipe-to-delete in list | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/editar_chuva_screen.dart` | CREATE | Edit screen with delete button |
| `lib/widgets/registro_chuva_tile.dart` | MODIFY | Added Dismissible for swipe-to-delete |

---

## Phase 3.0: Registro de Nova Chuva

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🔴 CRÍTICO
**Objetivo**: Permitir registrar uma nova chuva de forma rápida e simples.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 3.0.1 | Create AdicionarChuvaScreen | ✅ DONE |
| 3.0.2 | Large numeric input for millimeters | ✅ DONE |
| 3.0.3 | Date picker with today as default | ✅ DONE |
| 3.0.4 | Optional observation field | ✅ DONE |
| 3.0.5 | Validation (0.1 - 500mm) | ✅ DONE |
| 3.0.6 | Success feedback via SnackBar | ✅ DONE |
| 3.0.7 | FAB on home screen | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/adicionar_chuva_screen.dart` | CREATE | Add rainfall screen with large input |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Added FAB with navigation |

---

## Phase 2.5: Lista de Registros de Chuva

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🔴 CRÍTICO
**Objetivo**: Exibir histórico de chuvas registradas de forma clara e organizada.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.5.1 | Create RegistroChuvasTile widget | ✅ DONE |
| 2.5.2 | Create EstadoVazio widget | ✅ DONE |
| 2.5.3 | Group records by month with headers | ✅ DONE |
| 2.5.4 | Intensity icons (light/moderate/heavy) | ✅ DONE |
| 2.5.5 | Implement CustomScrollView with slivers | ✅ DONE |
| 2.5.6 | Pull-to-refresh | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/widgets/registro_chuva_tile.dart` | CREATE | Record tile with intensity icon |
| `lib/widgets/estado_vazio.dart` | CREATE | Empty state widget |
| `lib/screens/lista_chuvas_screen.dart` | MODIFY | Full implementation with real data |

---

## Phase 2.4: Modelo de Dados e Persistência

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🔴 CRÍTICO
**Objetivo**: Definir estrutura de dados e implementar persistência com Hive.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.4.1 | Create RegistroChuva model with @HiveType | ✅ DONE |
| 2.4.2 | Generate Hive adapter with build_runner | ✅ DONE |
| 2.4.3 | Create ChuvaService with CRUD operations | ✅ DONE |
| 2.4.4 | Initialize service in main.dart | ✅ DONE |

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/models/registro_chuva.dart` | CREATE | Hive model with factory constructor |
| `lib/models/registro_chuva.g.dart` | GENERATE | Hive TypeAdapter |
| `lib/services/chuva_service.dart` | CREATE | Singleton service with CRUD |
| `lib/main.dart` | MODIFY | Added ChuvaService initialization |

### Model: RegistroChuva

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | int | Timestamp em milliseconds (chave única) |
| data | DateTime | Data da chuva |
| milimetros | double | Volume em mm (0.1 a 500.0) |
| observacao | String? | Nota opcional |
| criadoEm | DateTime | Quando foi registrado |

---

## Phase 2.3: Localização (l10n) do App

### Status: [DONE]
**Date Completed**: 2026-01-17
**Prioridade**: 🟡 IMPORTANTE
**Objetivo**: Adicionar todas as strings do app nos arquivos ARB.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.3.1 | Add chuva* strings to agro_core ARB files | ✅ DONE |
| 2.3.2 | Regenerate l10n with flutter gen-l10n | ✅ DONE |
| 2.3.3 | Remove redundant app-specific l10n | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `packages/agro_core/lib/l10n/arb/app_pt.arb` | MODIFY | Added 40+ chuva* strings |
| `packages/agro_core/lib/l10n/arb/app_en.arb` | MODIFY | Added 40+ chuva* strings (EN) |

### Note
All l10n strings are centralized in agro_core following the DRY principle. The app uses AgroLocalizations directly.

---

## Phase 2.0: Standard Menu Integration

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟢 ENHANCEMENT
**Objective**: Integrate agro_core standard menu (AgroDrawer) and base screens into planeja_chuva.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 2.0.1 | Create ListaChuvasScreen with AgroDrawer | ✅ DONE |
| 2.0.2 | Implement navigation to Settings, Privacy, About | ✅ DONE |
| 2.0.3 | Update main.dart to use ListaChuvasScreen | ✅ DONE |

### Files Modified

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/lista_chuvas_screen.dart` | CREATE | Main screen with AgroDrawer and navigation |
| `lib/main.dart` | MODIFY | Import and use ListaChuvasScreen |

---

## Phase 1.0: Privacy Onboarding Integration

### Status: [DONE]
**Date Completed**: 2026-01-17
**Priority**: 🟢 ENHANCEMENT
**Objective**: Integrate agro_core privacy onboarding flow into planeja_chuva app.

### Implementation Summary

| Sub-Phase | Description | Status |
|-----------|-------------|--------|
| 1.0.1 | Update pubspec.yaml with dependencies | ✅ DONE |
| 1.0.2 | Update main.dart with Hive initialization | ✅ DONE |
| 1.0.3 | Add AgroPrivacyStore.init() call | ✅ DONE |
| 1.0.4 | Wrap home screen with AgroOnboardingGate | ✅ DONE |
| 1.0.5 | Add l10n delegates and supported locales | ✅ DONE |
| 1.0.6 | Remove unused platform folders (windows, linux, macos, web) | ✅ DONE |

---

## Roadmap Visual

```
DONE ───────────────────────────────────────────────────────────────────────
  [1.0] Privacy Onboarding ✅
  [2.0] Menu Integration ✅
  [2.3] Localização (l10n) ✅
  [2.4] Modelo de Dados (Hive) ✅
  [2.5] Lista de Registros ✅
  [3.0] Registro de Nova Chuva ✅ MVP CORE
  [4.0] Edição e Exclusão ✅
  [5.0] Resumos e Estatísticas ✅
  [6.0] Backup e Compartilhamento ✅
  [6.1] Configuração Google Services ✅
  [6.2] Configuração de Flavors (dev/prod) ✅
  [7.0] Seleção Manual de Idioma ✅
  [7.1] Padronização de Labels Android (Monorepo) ✅

CURTO PRAZO (100% Offline) ────────────────────────────────────────────────
  [8.0] Persistência de Preferências ⏳
  [9.0] Melhorias de UX/Acessibilidade ⏳
  [10.0] Validação Inteligente ⏳

MÉDIO PRAZO (100% Offline) ────────────────────────────────────────────────
  [11.0] Notificações Locais (Lembretes) ⏳
  [12.0] Exportação Avançada (PDF/CSV) ⏳
  [13.0] Visualizações Simples ⏳

LONGO PRAZO (Híbrido: Offline + Sync Opcional) ───────────────────────────
  [14.0] Previsão do Tempo (Open-Meteo + Cache) ⏳
  [15.0] Estatísticas Regionais (Firestore + Opt-in) ⏳

FUTURO INDETERMINADO (Baixa Prioridade) ──────────────────────────────────
  [??.0] Gráficos Complexos (fl_chart) - Usar apenas se necessário
  [??.0] Mapa Visual de Propriedade - Google Maps (custo alto)
```

### Legenda de Categorias

| Categoria | Descrição | Dependência de Internet |
|-----------|-----------|-------------------------|
| **100% Offline** | Funciona completamente sem internet | ❌ Nenhuma |
| **Híbrido** | Tenta usar internet, degrada gracefully se offline | ⚠️ Opcional (timeout 2-3s) |
| **Online-First** | Requer internet para funcionar | ✅ Obrigatória |

**Estratégia do App**: Manter core 100% offline (fases 1-13), adicionar features extras híbridas (fases 14-15) que não prejudicam experiência offline.
```

---

## Arquivos do Projeto

### Estrutura Final

```
lib/
├── main.dart                            # Entry point with Hive init
├── models/
│   ├── registro_chuva.dart              # Hive model
│   ├── registro_chuva.g.dart            # Generated adapter
│   ├── user_preferences.dart            # [Phase 8.0] Settings persistence
│   ├── user_preferences.g.dart          # [Phase 8.0] Generated adapter
│   ├── propriedade_settings.dart        # [Phase 14.0] Location settings
│   ├── propriedade_settings.g.dart      # [Phase 14.0] Generated adapter
│   ├── weather_forecast.dart            # [Phase 14.0] Weather data model
│   ├── weather_forecast.g.dart          # [Phase 14.0] Generated adapter
│   └── regional_data.dart               # [Phase 15.0] Regional stats model
├── services/
│   ├── chuva_service.dart               # CRUD operations
│   ├── backup_service.dart              # Export/import logic
│   ├── export_service.dart              # [Phase 12.0] PDF/CSV export
│   ├── validation_service.dart          # [Phase 10.0] Smart validations
│   ├── notification_service.dart        # [Phase 11.0] Local reminders
│   ├── weather_service.dart             # [Phase 14.0] Open-Meteo integration
│   └── sync_service.dart                # [Phase 15.0] Firestore sync
├── screens/
│   ├── lista_chuvas_screen.dart         # Main screen with list
│   ├── adicionar_chuva_screen.dart      # Add new record
│   ├── editar_chuva_screen.dart         # Edit/delete record
│   ├── estatisticas_screen.dart         # Statistics
│   ├── backup_screen.dart               # Backup/restore
│   ├── propriedade_config_screen.dart   # [Phase 14.0] Location setup
│   ├── weather_detail_screen.dart       # [Phase 14.0] 5-day forecast
│   └── regional_stats_screen.dart       # [Phase 15.0] Regional comparison
└── widgets/
    ├── registro_chuva_tile.dart         # List item
    ├── estado_vazio.dart                # Empty state
    ├── resumo_mensal_card.dart          # Monthly summary
    ├── visualizacao_barras.dart         # [Phase 13.0] ASCII charts
    ├── comparacao_anual_card.dart       # [Phase 13.0] Year comparison
    └── weather_card.dart                # [Phase 14.0] Home weather widget
```

---

## 📋 RESUMO EXECUTIVO DAS DECISÕES (REVISADO)

### Data da Análise: 2026-01-17 (Atualizado após discussão)

#### Propostas Analisadas (Status Final)
1. **Cadastro de Propriedade com GPS** - ✅ Aceita (opcional para offline, obrigatório para features híbridas)
2. **Previsão do Tempo (Open-Meteo)** - ✅ Aceita (Phase 14.0 - sync em background)
3. **Estatísticas Regionais (Firestore)** - ✅ Aceita (Phase 15.0 - sync opcional com opt-in)

---

### Arquitetura Híbrida Inteligente

#### Princípios de Sync em Background

**1. Nunca Bloquear o Usuário**
- Sync acontece em segundo plano (WorkManager/background isolate)
- App funciona normalmente mesmo se sync falhar
- Timeout agressivo (2-3s) para não travar

**2. Atualização Periódica Automática**
- **Previsão do Tempo**: Atualizar a cada 6 horas (4x/dia)
- **Estatísticas Regionais**: Atualizar a cada 1 hora quando online
- **Sincronização de Registros**: Enviar pendentes a cada 12 horas (apenas Wi-Fi)

**3. Cache Local Sempre Disponível**
- Última previsão válida por 24h (mesmo sem internet)
- Últimas estatísticas válidas por 7 dias
- Badge visual: "Atualizado há X horas"

**4. Estratégia de Conectividade**
```dart
// Pseudocódigo da estratégia
if (isWiFi) {
  // Sync completo: enviar registros + buscar previsão + estatísticas
  syncEverything(timeout: 3s);
} else if (isMobileData && userAllowsMobileData) {
  // Sync leve: apenas buscar previsão (economiza dados)
  syncWeatherOnly(timeout: 2s);
} else {
  // Offline: usar cache
  showCachedData();
}
```

#### Priorização de Sync

| Prioridade | Operação | Frequência | Conectividade |
|------------|----------|------------|---------------|
| 🔴 Alta | Enviar registros de chuva | 12h | Wi-Fi only |
| 🟡 Média | Buscar previsão do tempo | 6h | Wi-Fi ou dados móveis (opt-in) |
| 🟢 Baixa | Buscar estatísticas regionais | 1h | Wi-Fi only |

---

### Decisões Técnicas

**✅ APROVADAS - Fases 8.0 a 15.0**

**Fases 8-13 (100% Offline)**:
- Mantêm arquitetura offline-first pura
- Não requerem dependências externas
- Agregam valor imediato ao usuário
- Complexidade compatível com MVP

**Fases 14-15 (Híbrido: Offline + Sync)**:
- Core continua offline (registrar chuva)
- Features extras degradam gracefully
- Sync em background não bloqueia usuário
- Firestore SDK gerencia complexidade (cache, retry, offline mode)

---

### Vantagens da Arquitetura Revisada

#### Firestore Offline Mode (Phase 15.0)
- **Cache Automático**: SDK gerencia cache local transparentemente
- **Sync Bidirecional**: Envia quando online, recebe atualizações automaticamente
- **Conflict Resolution**: Firestore resolve conflitos de escrita
- **Retry Automático**: Tenta reenviar dados que falharam
- **Sem Backend Custom**: Regras de segurança no Firestore substituem backend

#### Open-Meteo + Cache (Phase 14.0)
- **API Gratuita**: 10,000 requests/dia sem custo
- **Sem Autenticação**: Não precisa de chave de API
- **Dados Agrometeorológicos**: Específico para agricultura
- **Previsão Precisa**: Dados de múltiplos modelos meteorológicos

---

### Considerações de Privacidade e LGPD

**Phase 15.0 (Estatísticas Regionais)**:
1. **Opt-In Explícito**: Checkbox "Compartilhar dados anônimos para estatísticas regionais"
2. **Dados Minimizados**: Apenas {lat, lon, mm, date} - SEM nome, fazenda, device ID
3. **GeoHash Impreciso**: Agrupa em áreas de ~5km (não identifica propriedade exata)
4. **Direito de Exclusão**: Botão "Parar de compartilhar e deletar meus dados enviados"
5. **Transparência**: Mostrar na tela "Baseado em X propriedades da região"

**Compliance LGPD**:
- Consentimento separado de dados estatísticos (não obrigatório para usar app)
- Informação clara sobre o que é compartilhado
- Fácil revogação de consentimento
- Dados verdadeiramente anonimizados (sem possibilidade de identificação)

---

### Próximos Passos Recomendados

**Prioridade 1 - Curto Prazo (2-4 semanas)**:
1. Phase 8.0: Persistir preferências do usuário
2. Phase 9.0: Melhorias de UX/Acessibilidade

**Prioridade 2 - Médio Prazo (1-2 meses)**:
3. Phase 10.0: Validação inteligente (prevenir erros)
4. Phase 11.0: Notificações locais (lembretes)

**Prioridade 3 - Longo Prazo (3-6 meses)**:
5. Phase 12.0: Exportação avançada (PDF/CSV)
6. Phase 13.0: Visualizações simples (tendências)

**Prioridade 4 - Futuro (6+ meses)**:
7. Phase 14.0: Previsão do tempo (após consolidar base offline)
8. Phase 15.0: Estatísticas regionais (após ter massa crítica de usuários)

---
