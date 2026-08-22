# Chambapp Mobile — MVP Android (M1–M8)

Aplicación Flutter de Chambapp para Android/iOS. Incluye autenticación y sesión persistente (M1), experiencia cliente (M2), administración profesional (M3), matching on-demand (M4) y cotizaciones/pagos hospedados (M5). Laravel continúa siendo la única fuente de verdad para reglas de negocio.

## Requisitos

- Flutter 3.47.0 estable (Dart 3.13.0).
- Android Studio/SDK para Android o Xcode para iOS.
- Backend Chambapp ejecutándose localmente o una API HTTPS accesible.

En este equipo Flutter está en `C:\Users\USER\Desktop\fluter\.flutter_sdk` pero su carpeta `bin` no está en `PATH`. Los comandos pueden ejecutarse con la ruta completa o agregando el SDK al `PATH` del usuario.

Android Command-line Tools está instalado y las licencias están aceptadas. `flutter doctor -v` deja únicamente el aviso de que Flutter/Dart no están en el `PATH` del usuario; puede usarse la ruta completa indicada arriba.

## Instalación y ejecución

```powershell
flutter pub get
flutter run --dart-define=APP_ENV=development
```

El valor local predeterminado es:

```text
http://10.0.2.2:8000/api/v1
```

`10.0.2.2` apunta desde el Android Emulator al host. `localhost` dentro del emulador apunta al propio emulador. En un dispositivo físico usa la IP LAN del equipo:

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
```

Para probar en Windows/Web contra el backend local:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Ambientes

- `APP_ENV=development`: activa logging seguro de método, ruta y status; nunca imprime headers, tokens, contraseñas ni bodies.
- `APP_ENV=production`: exige que `API_BASE_URL` se proporcione explícitamente.
- Una compilación `release` exige `APP_ENV=production` y rechaza una `API_BASE_URL` que no sea HTTPS.

No existe una URL productiva predeterminada. Cuando el dominio real esté disponible:

```powershell
flutter run --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://DOMINIO-REAL/api/v1
```

Laravel usará `APP_URL=https://DOMINIO-REAL`; Flutter usará `API_BASE_URL=https://DOMINIO-REAL/api/v1`. Son valores distintos.

No se guardan secretos de backend en la aplicación. `API_BASE_URL` es configuración pública, no un secreto.

## Backend local

Desde el proyecto Laravel (sin modificarlo):

```powershell
php artisan serve --host=127.0.0.1 --port=8000
```

La app consume:

- `POST /auth/register`
- `POST /auth/login`
- `GET /me`
- `POST /auth/logout`
- `POST /auth/logout-all` (preparado en repository, aún sin acción de UI)
- `GET /categories`
- `GET /services` y `GET /services/{service}`
- `GET /professionals/{professional}`
- `GET|POST|DELETE /favorites`
- `GET /jobs` y `GET /jobs/{job}`
- `POST /jobs/immediate` y `POST /jobs/scheduled`
- `GET /jobs/{job}/status`
- `GET|PATCH /professional/profile`
- `GET|POST|PATCH|DELETE /professional/services`
- `GET|PUT /professional/availability`
- `GET /professional/job-invitations`
- `GET /professional/jobs`

El backend actual no expone `email` en `UserResource`. Para poder mostrar el correo después de reiniciar, la app conserva el correo ingresado junto al token en almacenamiento seguro. No se persiste contraseña ni una copia completa del usuario.

Google Login no está incluido: las rutas encontradas corresponden al flujo web y no existe un endpoint OAuth móvil en `/api/v1`.

## Arquitectura

```text
lib/
  app/                 # App, providers y router
  core/
    config/            # Ambientes y API_BASE_URL
    constants/
    errors/            # Excepciones y mapeo Dio → dominio
    network/           # Dio, Bearer interceptor y eventos 401
    storage/           # flutter_secure_storage
    theme/             # Colores, spacing, radios y ThemeData
  features/
    auth/              # data / domain / presentation
    catalog/           # Categorías, búsqueda, servicios y profesionales
    favorites/         # Favoritos optimistas con estado real
    home/presentation/ # Home cliente
    jobs/              # WIZARDS, listado, detalle, status y polling
    location/          # Geolocator y fallback manual
    navigation/        # Bottom navigation cliente con IndexedStack
    profile/presentation/
    professional/       # Perfil, servicios, disponibilidad, oportunidades y trabajos
  shared/widgets/      # Inputs, botones, feedback y error/retry
```

Se usa una arquitectura feature-first ligera. Riverpod administra la sesión y estados de envío; `go_router` protege splash/login/register/home/profile. Un 401 fuera de login/registro elimina la sesión local y activa el guard hacia login.

## Autenticación y errores

El token Sanctum se almacena con `flutter_secure_storage` y se adjunta como Bearer mediante un interceptor Dio. Splash lee el token y consulta `/me` sin demora artificial. Si la API no está disponible, muestra un estado reintentable sin borrar un token potencialmente válido; si recibe 401/403 de cuenta inválida, limpia la sesión.

Los errores 401, 403, 404, 409, 422, 429 y 5xx se convierten en mensajes de dominio. Los errores 422 se conservan por campo. El modelo también preserva códigos de negocio como `JOB_ALREADY_TAKEN`, `PROFESSIONAL_BUSY`, `PAYMENT_REQUIRED` y `LOCATION_STALE` para fases posteriores.

## Experiencia cliente M2

El cliente dispone de cinco tabs que conservan su estado: Inicio, Buscar, Mis chambas, Favoritos y Perfil. La home coordina una carga de categorías y otra de servicios; la búsqueda usa el endpoint remoto con debounce de 400 ms y permite filtrar por categoría.

Los perfiles públicos muestran únicamente nombre, avatar, bio, experiencia, ciudad/estado, rating, servicios y reseñas que entrega la API. Los modelos móviles de M2 no contienen teléfono, email, dirección exacta ni coordenadas privadas.

### Ubicación y permisos

Se usa `geolocator`. Android solicita únicamente `ACCESS_COARSE_LOCATION` y `ACCESS_FINE_LOCATION`; iOS declara `NSLocationWhenInUseUsageDescription`. No se solicita background location.

Estados soportados:

- Detectando ubicación.
- Ubicación encontrada.
- Permiso denegado o bloqueado.
- GPS desactivado.
- Error de ubicación.

El usuario siempre puede escribir dirección, ciudad, estado y código postal. Explorar el catálogo no requiere permiso. Si el emulador no devuelve coordenadas, configura una ubicación simulada desde Extended controls → Location y verifica que Location esté activado. Para un permiso bloqueado, restablécelo desde Settings → Apps → Chambapp → Permissions.

### Solicitudes y polling

“Ahora” usa un wizard de categoría, descripción, ubicación y confirmación. Bloquea doble envío y navega a “Buscando profesional”. Esta pantalla consulta `/jobs/{id}/status` cada 5 segundos, pausa al ir a background, actualiza inmediatamente al volver y se detiene cuando termina la búsqueda.

“Programar” exige una fecha futura, una de las cuatro franjas admitidas por OpenAPI y dirección manual completa. Después abre el detalle con confirmación. “Mis chambas” consume el listado paginado propio, ofrece filtros exactos soportados por API y pull-to-refresh.

No existe un endpoint API de cancelación de búsqueda en M2; por ello esa acción no se muestra.

## Calidad y tests

```powershell
dart format .
flutter analyze
flutter test
```

Los tests Flutter no usan el backend real. Cubren mapper de errores, repositories, secure storage, parsing, privacidad, ubicación concedida/denegada, formularios, doble tap, polling searching→matched, expiración y tamaños 320×568, 360×800, 390×844, 412×915 y 800×1024.

## Experiencia profesional M3

El rol `professional` abre una navegación independiente con Inicio, Chambas, Servicios, Ganancias y Perfil. La disponibilidad siempre se consulta al servidor; abrir la app no activa al profesional. Los estados Disponible, No disponible y Ocupado se muestran con texto e icono, y el switch espera confirmación de la API.

La pantalla de disponibilidad reutiliza Geolocator con permiso mientras se usa la app. Permite actualizar coordenadas y elegir uno de los radios admitidos por Laravel: 5, 10, 15 o 25 km. No existe ubicación en segundo plano ni tracking continuo. Ante GPS apagado o permiso denegado, perfil y servicios continúan disponibles.

El perfil permite editar nombre, teléfono, bio, experiencia, ciudad, estado, código postal y una imagen elegida de la galería. Los estados de verificación son solo lectura. Los servicios propios pueden crearse, editarse y eliminarse lógicamente con confirmación. La API actual no ofrece una acción para reactivar un servicio eliminado.

Los modelos de invitación no almacenan teléfono, email, WhatsApp, dirección exacta ni coordenadas del cliente. Los trabajos asignados consumen `/professional/jobs`; el detalle continúa sujeto a `JobRequestResource` y sus reglas de privacidad post-pago.

No existe una API de resumen de ganancias. La pestaña correspondiente muestra un estado vacío sin calcular ni inventar importes.

### Solución de problemas profesional

- Si no se puede activar disponibilidad, actualiza primero la ubicación y verifica que GPS esté encendido.
- Si el permiso quedó bloqueado, habilítalo desde los ajustes del sistema; las demás funciones no se bloquean.
- Si una actualización falla sin conexión, la app no muestra un estado optimista: reintenta cuando la API vuelva a estar disponible.
- Las imágenes de perfil admiten JPEG, PNG o WebP hasta 2 MB; las de servicios, hasta cinco archivos de 4 MB.

## Matching on-demand M4

El cliente consulta `/jobs/{job}/status` cada cinco segundos durante `searching`. El polling se pausa en background, consulta inmediatamente al volver y aplica backoff progresivo ante errores. Después de `matched` consulta más lentamente hasta `awaiting_quote`. La pantalla muestra tiempo transcurrido, zona aproximada y el perfil público seguro del profesional ganador; nunca inventa cantidad de profesionales conectados.

Los profesionales disponibles consultan `/professional/job-invitations` cada ocho segundos mientras Inicio o Chambas están visibles. El feed deduplica por id, conserva el orden del backend, incorpora oportunidades nuevas y usa `expires_at` solo como countdown visual; al llegar a cero vuelve a consultar al servidor.

Aceptar y rechazar usan exclusivamente:

- `POST /professional/job-invitations/{invitation}/accept`
- `POST /professional/job-invitations/{invitation}/decline`

La UI bloquea doble tap y no declara victoria antes de la respuesta. `JOB_ALREADY_TAKEN`, `PROFESSIONAL_BUSY`, `LOCATION_STALE`, expiración y rate limiting tienen mensajes estables. Ante un timeout ambiguo, la app consulta nuevamente invitaciones y trabajos profesionales: si el Job ya aparece asignado muestra éxito; si sigue disponible exige actualización antes de reintentar; si desapareció informa que ya no está disponible.

El polling se detiene en background, en tabs no visibles y cuando el profesional está unavailable o busy. No se ejecutan servicios Android en segundo plano ni se instaló Firebase.

### Privacidad M4

Flutter no decide el ganador, no calcula cercanía y no implementa locks. Las invitaciones muestran categoría, descripción, zona y distancia aproximada entregadas por Laravel. El perfil del match contiene solo nombre, avatar, rating, verificación y trabajos completados. No existen chat, teléfono, email, WhatsApp, dirección exacta ni coordenadas del cliente en estos modelos.

## Alcance

M4 no implementa cotización completa, checkout, Mercado Pago, acciones de ejecución del trabajo, chat, reviews nuevas, push, tracking GPS ni publicación en stores. El backend realiza todo el matching y resuelve atómicamente qué profesional gana; Flutter solo representa el resultado.

## Cotizaciones y pagos M5

El profesional asignado puede enviar una cotización con precio y descripción. La pantalla muestra una estimación visual del 15%, pero nunca envía ni persiste fee, monto profesional o estado financiero: Laravel calcula los valores oficiales. Los rechazos del `ContactInformationGuard` se presentan por campo sin intentar evadirlos.

El cliente lista las cotizaciones propias, puede aceptar o rechazar con confirmación y pasa a `awaiting_payment` solo después de la respuesta del servidor. El checkout consume `/jobs/{job}/checkout`, no envía un amount y abre la URL devuelta por Laravel en el navegador externo mediante `url_launcher`; Flutter no captura tarjeta ni contiene credenciales de Mercado Pago.

Volver del navegador no implica pago aprobado. La pantalla consulta `/payments/{payment}` y refresca el Job al volver a foreground. Soporta `pending`, `processing`, `approved`, `rejected`, `cancelled`, `refunded` y estados desconocidos. Si crear checkout termina en timeout, primero consulta el Job para descubrir un intento existente y nunca crea otro automáticamente.

Los importes se conservan como strings decimales. El profesional ve `gross_amount`, `platform_fee_percent`, `platform_fee` y `professional_amount` retornados por `PaymentResource`, por lo que un snapshot histórico distinto de 15% no se recalcula. Antes de `paid` Flutter descarta dirección y coordenadas aunque aparecieran inesperadamente; desde `paid` muestra únicamente datos operativos entregados por `JobRequestResource` a participantes autorizados.

M5 termina en `paid`: no implementa En camino, llegada, ejecución, finalización, chat, reviews, push ni tracking GPS.

## Operación de la chamba M6

El detalle de Job representa el workflow pagado mediante acciones explícitas: `/on-the-way`, `/arrived`, `/start`, `/finish` y `/confirm`. Flutter nunca envía un `status` genérico. Un mapper central elige la única acción disponible según rol y estado, bloquea doble tap y vuelve a consultar el Job después de cada respuesta o timeout ambiguo.

El flujo profesional es `paid → on_the_way → arrived → in_progress → awaiting_confirmation`. Solo el cliente propietario puede confirmar con el `completion_code` condicional entregado por el detalle API, llegando a `completed`. El cliente también puede usar `/dispute` con motivos estructurados; esto lleva a `disputed`, no modifica Payment y no significa reembolso automático.

El detalle consulta cada siete segundos mientras está visible y el Job permanece operativo. El polling se pausa en background y en estados terminales, se reanuda al volver y no instala procesos de fondo. Al reiniciar, vuelve a cargar el Job desde Laravel y recupera la acción correcta.

Desde `paid`, dirección y coordenadas solo se muestran si `JobRequestResource` las entrega. “Abrir en mapas” usa una aplicación externa; no existe tracking GPS continuo. La API actual no entrega un teléfono operativo en `JobRequestResource`, por lo que M6 no inventa ni muestra un botón de llamada. No se implementaron chat, timer financiero, refund, resolución de disputas ni reviews de M7.

El desglose financiero sigue siendo el snapshot inmutable de `PaymentResource`: M6 no recalcula gross, porcentaje, fee ni monto profesional.

## Reseñas, notificaciones, favoritos e historial M7

Al completar una chamba, el cliente puede publicar una única calificación de 1 a 5 estrellas y un comentario opcional. El formulario usa `/jobs/{job}/review`, bloquea doble envío y muestra por campo los rechazos del `ContactInformationGuard`. El estado de reseña se recupera desde el Job, así que un reinicio muestra “Calificado” y no vuelve a ofrecer la acción. Los perfiles públicos consultan `/professionals/{professional}/reviews`; la app no inventa insignias ni información privada que la API no entregue.

Las notificaciones consumen el listado paginado propio, muestran el `unread_count` global exacto y permiten marcar una o todas como leídas. Solo navegan mediante el destino estructurado y seguro entregado por la API (`job` o `professional`); tipos futuros siguen siendo legibles y URLs externas o destinos desconocidos no se ejecutan. Al volver a foreground se refresca el estado. M7 no agrega Firebase ni push remoto: la bandeja es in-app.

Favoritos mantiene sincronización optimista contra Laravel con rollback ante error. Notificaciones, favoritos y caches de trabajos observan al usuario autenticado y se vacían al cerrar sesión, evitando mezclar datos entre cuentas. El historial cliente agrupa Activas, Completadas, Canceladas y Todas; el profesional conserva sus grupos operativos e históricos.

M7 no implementa chat, nuevos pagos, cambios de matching ni funciones de M8.

## Android y permisos

- Application ID y namespace: `com.chambapp.mobile`.
- Nombre visible: `Chambapp`.
- Versión inicial: `1.0.0+1` (`versionName=1.0.0`, `versionCode=1`).
- `minSdk=24`, `compileSdk=36` y `targetSdk=36` mediante Flutter 3.47.
- Permisos declarados: `INTERNET`, `ACCESS_COARSE_LOCATION` y `ACCESS_FINE_LOCATION`.
- No se solicitan cámara, almacenamiento ni ubicación en segundo plano.
- El selector de imágenes usa el mecanismo moderno provisto por `image_picker`.
- El tráfico HTTP está bloqueado en main/release. Solo debug permite cleartext para desarrollo local.

El icono launcher, adaptive icon y splash usan el logo vigente proporcionado para la app. El original completo se conserva en `assets/branding/chambapp-logo-current.jpeg` y el recorte maestro del icono en `assets/branding/chambapp-icon-source.png`. El mismo logo completo aparece en el splash Flutter y en los encabezados de autenticación. El splash nativo desaparece cuando Flutter dibuja el primer frame; la validación de sesión continúa en la pantalla Flutter correspondiente.

Si el permiso de ubicación queda bloqueado permanentemente, la UI ofrece **Abrir configuración**. No existe tracking continuo.

## Firma Android release

Release nunca usa la llave debug. Gradle exige cuatro variables de entorno y falla de forma explícita si falta alguna:

- `CHAMBAPP_KEYSTORE_PATH`
- `CHAMBAPP_KEY_ALIAS`
- `CHAMBAPP_STORE_PASSWORD`
- `CHAMBAPP_KEY_PASSWORD`

La creación y respaldo del upload keystore se realizan manualmente siguiendo [RELEASE.md](RELEASE.md). No guardes el keystore, contraseñas, `key.properties` ni credenciales en el repositorio.

## Builds

Debug local:

```powershell
flutter build apk --debug
```

Release, cuando existan API HTTPS y firma:

```powershell
flutter build apk --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://DOMINIO-REAL/api/v1

flutter build appbundle --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://DOMINIO-REAL/api/v1
```

Los artefactos quedan en `build/app/outputs/flutter-apk/` y `build/app/outputs/bundle/release/`; `build/` está ignorado por Git.

## Dispositivo y emulador

- Emulador Android: usa `10.0.2.2` para alcanzar el backend del host.
- Dispositivo físico: usa temporalmente la IP LAN del host en development y confirma conectividad/firewall.
- Producción: solo dominio HTTPS real; nunca localhost, `10.0.2.2` ni IP LAN.
- Antes de publicar instala el APK release firmado en un dispositivo físico y ejecuta la matriz de [QA_REPORT.md](QA_REPORT.md).

## Solución de problemas de toolchain

Si `flutter doctor -v` reporta command-line tools faltantes, abre Android Studio → SDK Manager → SDK Tools, instala **Android SDK Command-line Tools (latest)** y ejecuta:

```powershell
flutter doctor --android-licenses
flutter doctor -v
```

Si Gradle informa que falta la firma, configura las cuatro variables `CHAMBAPP_*` de la sección anterior. Si production informa que falta la URL, proporciona ambos `dart-define`; no agregues un fallback productivo al código.

## Publicación

Consulta [RELEASE.md](RELEASE.md), [PLAY_STORE_CHECKLIST.md](PLAY_STORE_CHECKLIST.md), [QA_REPORT.md](QA_REPORT.md) y [SECURITY.md](SECURITY.md). No publiques automáticamente ni declares información legal/Data Safety sin revisión humana.
