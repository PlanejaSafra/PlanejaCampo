# Planeja Chuva

Aplicativo para gestão pluviométrica e inteligência climática para produtores rurais. Parte da suíte PlanejaCampo.

## Visão Geral
O Planeja Chuva permite que o produtor registre chuvas, visualize estatísticas comparativas e receba alertas meteorológicos.

## Privacidade Híbrida (LGPD)
O aplicativo opera em um modelo de **Privacidade Híbrida**, colocando o usuário no controle total de seus dados:

1.  **Estritamente Confidencial (Padrão)**: Seus dados ficam apenas no seu dispositivo. Nada sai do seu celular.
2.  **Backup Privado (Opcional)**: Se ativado (Opção 1), seus registros são salvos em nuvem privada e segura (Google Cloud), permitindo recuperação e sincronização.
3.  **Rede Social (Opcional)**: Se ativado (Opção 2), permite interações comerciais e visibilidade de perfil.
4.  **Inteligência Coletiva (Opcional)**: Se ativado (Opção 3), dados anonimizados contribuem para estatísticas regionais.

## Funcionalidades
- Registro de chuvas por talhão
- Comparativo histórico
- Previsão do tempo (24h/7dias)
- Alertas de seca e tempestade
- Login com Google ou Anônimo

## Desenvolvimento
Este projeto utiliza Flutter modularizado (`agro_core`).
- **Gerenciamento de Estado**: Provider + Hive (Offline-First cache)
- **Backend**: Firebase (Auth, Firestore, Functions)
