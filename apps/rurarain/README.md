# RuraRain

Rainfall management and climate intelligence app for rural producers. Part of the RuraCamp suite.

## Overview
RuraRain allows producers to log rainfall, view comparative statistics, and receive weather alerts.

## Hybrid Privacy (LGPD)
The app operates under a **Hybrid Privacy** model, giving users full control of their data:

1. **Strictly Confidential (Default)**: Data stays only on your device. Nothing leaves your phone (Anonymous mode).
2. **Private Backup (Cloud)**: When logged in (Google), records are saved to a private and secure cloud, allowing recovery if the device is lost.
3. **Social Network (Optional)**: If enabled (Option 2), allows commercial interactions and profile visibility.
4. **Collective Intelligence (Optional)**: If enabled (Option 3), anonymized data contributes to regional statistics.

## Features
- Rainfall logging by field plot
- Historical comparison
- Weather forecast (24h/7days)
- Drought and storm alerts
- Login with Google or Anonymous

## Development
This project uses modular Flutter (`agro_core`).
- **State Management**: Provider + Hive (Offline-First cache)
- **Backend**: Firebase (Auth, Firestore, Functions)

## Firebase Configuration

| Environment | Project | Command |
|-------------|---------|---------|
| Development | `ruracamp-dev` | `flutter run --flavor dev` |
| Production | `ruracamp-c1f38` | `flutter run --flavor prod` |

## Documentation
- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Changelog**: See [CHANGELOG.md](CHANGELOG.md)
