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

Biblioteca central de componentes, serviços e modelos reutilizáveis para a suíte de aplicativos **Agro**. O objetivo deste pacote é garantir consistência visual, comportamental e de dados entre todos os apps (PlanejaChuva, PlanejaBorracha, etc.).

## Features

*   **Identidade Visual Unificada**: Sistema de temas (Claro/Escuro), tipografia e cores padronizadas.
*   **Autenticação Centralizada**: Telas de Login com suporte a Google Sign-In e Login Anônimo, incluindo migração de contas.
*   **Gestão de Propriedades e Talhões**: Modelos e Serviços (CRUD) para gerenciar a estrutura básica do produtor rural (via Hive).
*   **Backup na Nuvem**: Sistema unificado de backup e restauração via Firebase Storage.
*   **Privacidade e LGPD**: Fluxo de consentimento, termos de uso, política de privacidade, **portabilidade de dados (Art. 18 V)** e **exclusão de dados (Art. 18 VI)**.
*   **Componentes UI**: Drawer de navegação, Cards, Botões, Seletores e Gráficos padronizados.
*   **Internacionalização (i18n)**: Suporte nativo a múltiplos idiomas (PT-BR, EN).
*   **Integrações**: Previsão do tempo (Open-Meteo), Seleção de Localização (Google Maps).
*   **Notificações Inteligentes**: Alertas de chuva em background (minutely forecast).
*   **Mapa Colaborativo**: Visualização de chuva em tempo real via mapa de calor.

## Instalação

Adicione ao `pubspec.yaml` dos aplicativos:

```yaml
dependencies:
  agro_core:
    path: ../../packages/agro_core
```

## Arquitetura

Consulte [ARCHITECTURE.md](ARCHITECTURE.md) para detalhes sobre a organização dos módulos.
