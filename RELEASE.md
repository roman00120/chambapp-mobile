# Release Android de Chambapp

Este procedimiento prepara una versión controlada. No sustituye la validación en Play Console ni la revisión legal.

## 1. Prerrequisitos

- Flutter estable compatible con el proyecto.
- `flutter doctor -v` sin bloqueos Android.
- Android SDK 36, command-line tools y licencias aceptadas.
- API real disponible mediante HTTPS.
- Upload keystore respaldado de forma segura.
- Acceso a cuentas de prueba y entorno de pago controlado.

## 2. Crear el upload keystore una sola vez

Crea una carpeta privada fuera del repositorio y ejecuta `keytool` sin escribir contraseñas en el comando:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.chambapp\signing"
keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\.chambapp\signing\chambapp-upload.jks" `
  -alias chambapp-upload `
  -keyalg RSA `
  -keysize 4096 `
  -validity 10000
```

`keytool` solicitará las contraseñas de forma interactiva. Guárdalas en un administrador de contraseñas y respalda el keystore en una ubicación cifrada separada. Nunca lo copies al repositorio ni lo envíes por chat/correo sin cifrar.

Para Play Store, habilita y revisa Google Play App Signing. El archivo anterior debe tratarse como upload key, no como un artefacto público.

## 3. Configurar firma en la terminal o CI

```powershell
$env:CHAMBAPP_KEYSTORE_PATH="$env:USERPROFILE\.chambapp\signing\chambapp-upload.jks"
$env:CHAMBAPP_KEY_ALIAS="chambapp-upload"
$env:CHAMBAPP_STORE_PASSWORD="VALOR_DESDE_GESTOR_SEGURO"
$env:CHAMBAPP_KEY_PASSWORD="VALOR_DESDE_GESTOR_SEGURO"
```

No guardes estos valores en scripts versionados, `key.properties`, historial de shell o capturas. En CI usa secretos protegidos. Al terminar, cierra la terminal o elimina las variables.

## 4. Preparar versión

1. Incrementa `version:` en `pubspec.yaml`. La parte antes de `+` es `versionName`; la parte posterior es `versionCode` y debe aumentar en cada carga a Play.
2. Revisa cambios y dependencias.
3. Confirma la URL HTTPS definitiva.
4. Ejecuta:

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter pub outdated
```

## 5. Generar artefactos

```powershell
flutter build apk --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://DOMINIO-REAL/api/v1

flutter build appbundle --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://DOMINIO-REAL/api/v1
```

La compilación falla si la URL no es HTTPS, si falta `APP_ENV=production`, si falta la firma o si el keystore no existe.

## 6. Verificar firma y artefactos

```powershell
apksigner verify --verbose build\app\outputs\flutter-apk\app-release.apk
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
Get-FileHash build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

Registra rutas, hashes y tamaños en el reporte de release sin publicar credenciales.

## 7. QA release obligatorio

1. Instala el APK release firmado en un dispositivo físico.
2. Ejecuta los escenarios de `QA_REPORT.md` contra el entorno HTTPS controlado.
3. Comprueba que ningún request usa localhost, `10.0.2.2`, IP LAN o HTTP.
4. Valida ubicación permitida, denegada, bloqueada y GPS apagado.
5. Valida matching concurrente con dos profesionales.
6. Valida pago pendiente/rechazado/aprobado mediante webhook.
7. Cierra y abre durante searching, awaiting_payment e in_progress.
8. Confirma privacidad antes/después del pago y aislamiento multiusuario.

## 8. Publicación controlada

1. Completa `PLAY_STORE_CHECKLIST.md`.
2. Sube primero a Internal testing.
3. Revisa el pre-launch report.
4. Prueba la versión distribuida por Play.
5. Promueve gradualmente cuando no existan bloqueos.
6. Crea el tag Git solo después de verificar el artefacto publicado.

Conserva el AAB, hashes, mapeos/símbolos si se habilita obfuscation y la evidencia de QA según la política interna del proyecto.
