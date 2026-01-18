# Firebase Setup Manual - PlanejaCampo

## 📋 Checklist de Configuração

### 1. Baixar Arquivos do Firebase Console

#### Produção (PlanejaCampo)
- [ ] Acessar https://console.firebase.google.com
- [ ] Selecionar projeto **PlanejaCampo**
- [ ] Project Settings → Your apps → Android
- [ ] Download `google-services.json`
- [ ] Salvar em: `apps/planejachuva/android/app/src/prod/google-services.json`

#### Desenvolvimento (PlanejaCampoDev)
- [ ] Selecionar projeto **PlanejaCampoDev**
- [ ] Project Settings → Your apps → Android
- [ ] Download `google-services.json`
- [ ] Salvar em: `apps/planejachuva/android/app/src/dev/google-services.json`

---

## 📁 Estrutura de Pastas Esperada

```
apps/planejachuva/
├── android/
│   └── app/
│       └── src/
│           ├── dev/
│           │   └── google-services.json    ← PlanejaCampoDev
│           └── prod/
│               └── google-services.json    ← PlanejaCampo
└── lib/
    ├── firebase_options_dev.dart           ← Será criado
    └── firebase_options_prod.dart          ← Será criado
```

---

## 🔧 Configurar firebase_options.dart

Depois de baixar os arquivos `google-services.json`, siga estas etapas:

### 1. Abrir google-services.json (PROD)

Abra o arquivo `apps/planejachuva/android/app/src/prod/google-services.json` e encontre:

```json
{
  "project_info": {
    "project_number": "XXXXXXXXX",         ← Copie isso
    "project_id": "planejacampo",          ← Copie isso
    "storage_bucket": "planejacampo.appspot.com"  ← Copie isso
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:XXX:android:YYY",  ← Copie isso
        "android_client_info": {
          "package_name": "br.com.planejacampo.chuva"
        }
      },
      "api_key": [
        {
          "current_key": "AIzaSy..."  ← Copie isso
        }
      ]
    }
  ]
}
```

### 2. Preencher Template (PROD)

Substitua os valores no arquivo `apps/planejachuva/lib/firebase_options_prod.dart`:

```dart
// SUBSTITUA ESTES VALORES:
apiKey: 'AIzaSy...',                          ← current_key
appId: '1:XXX:android:YYY',                   ← mobilesdk_app_id
messagingSenderId: 'XXXXXXXXX',               ← project_number
projectId: 'planejacampo',                    ← project_id
storageBucket: 'planejacampo.appspot.com',    ← storage_bucket
```

### 3. Repetir para DEV

Repita o processo acima para o arquivo `google-services.json` de **dev** e preencha `firebase_options_dev.dart`.

---

## 🚀 Comandos para Criar Pastas (PowerShell)

```powershell
# Navegar até a pasta
cd apps\planejachuva\android\app\src

# Criar pastas dev e prod
New-Item -ItemType Directory -Path dev -Force
New-Item -ItemType Directory -Path prod -Force

# Verificar estrutura
tree /F
```

---

## ✅ Validar Configuração

Depois de tudo configurado, rode:

```powershell
# Testar build dev
flutter build apk --flavor dev -t lib/main.dart

# Testar build prod
flutter build apk --flavor prod -t lib/main.dart
```

---

## 📝 Informações Necessárias

Para criar os arquivos `firebase_options_*.dart`, você precisará extrair do `google-services.json`:

| Campo | Onde encontrar | Exemplo |
|-------|----------------|---------|
| `apiKey` | `client[0].api_key[0].current_key` | `AIzaSyBx...` |
| `appId` | `client[0].client_info.mobilesdk_app_id` | `1:123:android:abc` |
| `messagingSenderId` | `project_info.project_number` | `123456789` |
| `projectId` | `project_info.project_id` | `planejacampo` |
| `storageBucket` | `project_info.storage_bucket` | `planejacampo.appspot.com` |

---

## ⚠️ Importante

- **NÃO** versione `google-services.json` de produção no Git
- Adicione ao `.gitignore`:
  ```
  **/src/prod/google-services.json
  firebase_options_prod.dart
  ```
