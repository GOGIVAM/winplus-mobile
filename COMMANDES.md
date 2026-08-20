# WinPlus Mobile — Commandes de lancement

## Prérequis
- Flutter 3.41.4+ installé
- Android SDK installé (`C:\Users\Miguel\AppData\Local\Android\Sdk`)
- NDK 27.0.12077973 installé (version fixée dans `android/app/build.gradle.kts`)
- Pixel 6 branché en USB avec débogage USB activé
- **Ouvrir un nouveau terminal** après toute modification des variables d'environnement

---

## Variables d'environnement (à vérifier si build échoue)

```powershell
$env:GRADLE_USER_HOME = "M:\dev-cache\gradle"
$env:TEMP             = "M:\dev-cache\flutter-temp"
$env:TMP              = "M:\dev-cache\flutter-temp"
```

Ces variables sont persistantes (niveau utilisateur) mais nécessitent un **nouveau terminal** pour être effectives.

---

## Lancement

### Vérifier les appareils connectés
```powershell
flutter devices
```

### Lancer sur le Pixel 6 (debug)
```powershell
cd m:\win\winplus\winplus-mobile
flutter run
```

### Lancer sur un device spécifique
```powershell
flutter run -d <device-id>
```

### Lancer en release
```powershell
flutter run --release
```

---

## Build

### Nettoyer le cache (à faire si build échoue)
```powershell
flutter clean
```

### Nettoyer + relancer (combo le plus fiable)
```powershell
flutter clean && flutter run
```

### Compiler un APK debug
```powershell
flutter build apk --debug
```

### Compiler un APK release
```powershell
flutter build apk --release
```

L'APK se trouve dans : `build\app\outputs\flutter-apk\`

---

## Dépendances

### Installer / mettre à jour les packages
```powershell
flutter pub get
```

### Vérifier les dépendances outdated
```powershell
flutter pub outdated
```

---

## Diagnostic

### Vérifier l'environnement Flutter
```powershell
flutter doctor -v
```

### Voir les logs de l'appareil en temps réel
```powershell
flutter logs
```

### Hot reload (dans une session flutter run active)
- `r` — Hot reload
- `R` — Hot restart
- `q` — Quitter

---

## Problèmes connus

| Erreur | Solution |
|---|---|
| `NDK did not have a source.properties` | Supprimer `C:\Users\Miguel\AppData\Local\Android\Sdk\ndk\28.2.13676358` puis `flutter clean && flutter run` |
| `not enough space on the disk` | Vérifier que `GRADLE_USER_HOME` pointe vers M: — ouvrir un nouveau terminal |
| `No devices found` | Vérifier USB debugging activé sur le Pixel 6, accepter la popup de confiance |
| `Gradle task assembleDebug failed` | `flutter clean` puis relancer |
