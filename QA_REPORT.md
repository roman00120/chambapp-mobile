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

## Casos automatizados existentes

La suite cubre login incorrecto, mapeo 401/403/404/409/422/429/5xx, ubicación permitida/denegada/GPS apagado, doble toque, expiración, `JOB_ALREADY_TAKEN`, `PROFESSIONAL_BUSY`, timeouts ambiguos, privacidad de modelos, fee no enviado, snapshots históricos, workflow, review, notificaciones y limpieza multiusuario.

Los resultados automatizados no se reportan como pruebas de producción ni sustituyen el dispositivo físico.
