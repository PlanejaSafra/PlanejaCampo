<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Agro Core

Core library of reusable components, services, and models for the **RuraCamp** app suite. This package ensures visual, behavioral, and data consistency across all apps (RuraRain, RuraRubber, RuraCattle, RuraFuel).

## Features

*   **Identidade Visual Unificada**: Sistema de temas (Claro/Escuro), tipografia e cores padronizadas.
*   **Autenticação Centralizada**: Telas de Login com suporte a Google Sign-In e Login Anônimo, incluindo migração de contas.
*   **Gestão de Propriedades e Talhões**: Modelos e Serviços (CRUD) para gerenciar a estrutura básica do produtor rural (via Hive).
*   **Backup na Nuvem**: Sistema unificado de backup e restauração via Firebase Storage.
*   **Privacidade e LGPD**: Fluxo de consentimento, termos de uso, política de privacidade, **portabilidade de dados (Art. 18 V)** e **exclusão de dados (Art. 18 VI)**.
*   **Componentes UI**: Drawer de navegação, Cards, Botões, Seletores e Gráficos padronizados.
*   **Internacionalização (i18n)**: Suporte nativo a múltiplos idiomas (PT-BR, EN).
*   **Integrações**: Previsão do tempo (Open-Meteo), Seleção de Localização (Google Maps).
*   **Notificações Inteligentes**: Alertas de chuva detalhados em background (Início exato, Duração, Intensidade).
*   **Mapa do Tempo**: Visualização de radar meteorológico (RainViewer) em tempo real e mapa de calor colaborativo.
*   **Infraestrutura Offline-First** (CORE-78): Base unificada para sincronização de dados (Hive + Firestore).
    *   **Sync Inteligente**: Sincroniza apenas quando há Wi-Fi/Dados.
    *   **Zero Conflito**: Uso de "Server Timestamps" para garantir a verdade dos dados.
    *   **Alta Performance**: Índices em memória para acesso instantâneo.

## Instalação

Adicione ao `pubspec.yaml` dos aplicativos:

```yaml
dependencies:
  agro_core:
    path: ../../packages/agro_core
```

## Arquitetura

Consulte [ARCHITECTURE.md](ARCHITECTURE.md) para detalhes sobre a organização dos módulos.
