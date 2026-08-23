# Reporte y matriz QA M8

Fecha de auditoría: 2026-08-21.

## Estado automatizado

| Área | Cobertura | Estado |
|---|---|---|
| Formato | `dart format .` | 122 archivos; sin cambios pendientes |
| Análisis | `flutter analyze` | Sin hallazgos |
| Flutter | tests unitarios/widgets M1–M8 | 109 aprobados |
| Android debug | compilación local | Verde con branding y manifest finales |
| Android toolchain | SDK 36 / licencias | Verde; command-line tools instaladas |
| Guard release | ambiente, HTTPS y firma | Rechaza APP_ENV ausente, HTTP y firma ausente |
| Laravel | lectura solamente | No modificado en M8 |

## Matriz de dispositivos

| Dispositivo | Android | Build | Resultado |
|---|---:|---|---|
| Widget test 320×568 | N/A | test | Verde |
| Widget test 360×800 | N/A | test | Verde |
| Widget test 390×844 | N/A | test | Verde |
| Widget test 412×915 | N/A | test | Verde |
| Widget test 800×1024 | N/A | test | Verde |
| Pixel 9 Pro XL AVD ARM | N/A | debug | Incompatible con host x86_64 |
| Pixel 10 Pro XL AVD x86_64 | pendiente | debug | AVD quedó offline durante arranque |
| Dispositivo físico | pendiente | release | Sin dispositivo conectado |

## Escenarios release pendientes de API HTTPS

- [ ] Cliente inmediato completo: login → job → match → quote → pago → workflow → review.
- [ ] Profesional completo: disponibilidad → invitación → quote → ejecución → review visible.
- [ ] Solicitud programada completa.
- [ ] Dos profesionales: solo uno gana; el otro recibe `JOB_ALREADY_TAKEN`.
- [ ] Pago pendiente/rechazado no habilita datos ni workflow.
- [ ] Webhook aprobado lleva al estado pagado correcto.
- [ ] Comisión nueva 15% y snapshot histórico preservado.
- [ ] Reinicio en searching, awaiting_payment e in_progress.
- [ ] Usuario A → logout → Usuario B sin datos cruzados.
- [ ] Job ajeno rechazado por API y mostrado amigablemente.
- [ ] Privacidad exacta pre-pago y exclusiva de participantes post-pago.
- [ ] Review 1–5, duplicada, Contact Guard y refresco del rating.
- [ ] Notificaciones listar, leer una y leer todas.
- [ ] Offline/red lenta/timeout/rate limit sin acciones falsas ni retries infinitos.
- [ ] Back Android en searching, checkout, detalle y formularios.
- [ ] Text scale 100%, 130% y 150% en dispositivo.

## Reanudacion M8 contra produccion - 2026-08-22

Estado: **EN PROGRESO / release bloqueado**. No avanzar a M9.

### Infraestructura

- `GET https://chambapp.com.mx/api/v1/health`: HTTP 200, `status=ok`, `api_version=v1`.
- HTTPS: certificado `CN=chambapp.com.mx`, Let's Encrypt, vigente del 2026-08-22 al 2026-11-20.
- La URL HTTP redirige con 301 a HTTPS.
- Catalogo de produccion restaurado: 30 categorias activas.
- API Google movil desplegada: una peticion incompleta devuelve 422, no 404.
- Webhook Mercado Pago corregido: una firma deliberadamente invalida devuelve 401 y no llega a mutar pagos.

### Produccion verificada

- Registro cliente y profesional: HTTP 201.
- Login con contrasena: HTTP 200.
- Sanctum `/me`: HTTP 200 con token; HTTP 401 despues de revocarlo.
- Separacion de roles: cliente en endpoint profesional devuelve 403.
- Perfil, disponibilidad, servicios, trabajos e invitaciones profesionales: HTTP 200/201.
- Solicitud inmediata: creada en `searching`.
- Matching: invitacion creada y aceptada; trabajo en `matched`.
- Cotizacion: creada, listada y aceptada.
- Workflow antes del pago: correctamente bloqueado con 403.
- Review antes de completar: correctamente bloqueada con 403.
- Solicitud programada: HTTP 201.
- Notificaciones de ambos roles: listadas y marcadas como leidas con HTTP 200.
- Logout y logout-all: HTTP 200; token revocado rechazado con 401.

### Automatizacion

- Laravel: 195/195 pruebas, 1227 assertions.
- Flutter: 113/113 pruebas (112 suite previa + prueba específica del rol administrador).
- `flutter analyze`: sin hallazgos.
- Jobs, matching, cotizaciones, integridad de pagos, webhook, workflow, reviews y notificaciones tienen cobertura automatizada verde.

### Firma release preparada

- Keystore privado vigente: `C:\Users\Roman\.chambapp\signing\chambapp-upload-v2.jks`.
- Alias: `chambapp-upload`.
- SHA-1: `4C:64:E2:F3:B0:CA:36:0A:2C:0E:CA:CB:DE:38:19:2E:46:B4:05:5F`.
- SHA-256 del certificado: `26:EF:A4:16:BF:CC:BC:7F:82:E9:1A:60:92:76:6F:B1:D9:DB:32:B7:85:25:60:BB:93:07:FA:1F:BF:E4:49:EF`.
- La contrasena esta cifrada con Windows DPAPI; no se almacena en texto plano. El cargador privado es `C:\Users\Roman\.chambapp\signing\load-release-signing.ps1`.

### Bloqueos antes del release final

1. Checkout de produccion devuelve 403 porque el profesional QA no tiene una cuenta vendedora de Mercado Pago conectada. Falta validar checkout HTTPS, pago pendiente/rechazado/aprobado y webhook aprobado con credenciales de prueba controladas.
2. Sin pago aprobado no se puede completar en produccion `paid -> on_the_way -> arrived -> in_progress -> awaiting_confirmation -> completed -> review`.
3. No hay dispositivo ni emulador Android conectado; falta instalar y ejecutar el APK release en Android.
4. La SHA-1 release debe registrarse como cliente OAuth Android para `com.chambapp.mobile` antes de validar Google en el artefacto firmado.

Por estos bloqueos no se generaron todavia `app-release.apk` ni `app-release.aab`, y M8 no se marca como completada.

### Panel administrativo móvil

- La APK reconoce el rol `admin` sin convertirlo en cliente o profesional.
- Navegación administrativa independiente con resumen, usuarios, verificación y cuenta.
- Dashboard con métricas reales de usuarios, profesionales, servicios, chambas, pagos, disputas y reportes.
- Gestión de usuarios: activar, suspender y bloquear; el administrador no puede modificar su propia cuenta.
- Gestión de profesionales: aprobar o rechazar con motivo obligatorio.
- Gestión completa adaptada a móvil: categorías, servicios, chambas, pagos, comisiones, reportes, reseñas y disputas.
- Categorías: crear, editar, activar y desactivar.
- Servicios: activar, desactivar, destacar y quitar destacado.
- Reportes y disputas: actualización de estados con auditoría.
- Reseñas: ocultar con motivo o restaurar, recalculando la reputación.
- Chambas, pagos y comisiones: consulta, búsqueda local y detalle resumido; los pagos son de solo lectura para evitar mutaciones financieras manuales.
- Todas las mutaciones conservan el registro de auditoría del backend.
- API protegida por Sanctum, cuenta activa y middleware `role:admin`.
- Producción confirma las rutas `/api/v1/admin/dashboard` y `/api/v1/admin/operations/categories`: devuelven 401 sin token, como corresponde.
- APK de prueba completa: `C:\Users\Roman\Desktop\Chambapp-admin-completo-prueba.apk`.
- SHA-256: `D04C759EB498D54A1B40CCFE7070CD8613FC401723B91945C085F5DC7C193943`.

## Casos automatizados existentes

La suite cubre login incorrecto, mapeo 401/403/404/409/422/429/5xx, ubicación permitida/denegada/GPS apagado, doble toque, expiración, `JOB_ALREADY_TAKEN`, `PROFESSIONAL_BUSY`, timeouts ambiguos, privacidad de modelos, fee no enviado, snapshots históricos, workflow, review, notificaciones y limpieza multiusuario.

Los resultados automatizados no se reportan como pruebas de producción ni sustituyen el dispositivo físico.
