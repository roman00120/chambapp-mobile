# Seguridad de Chambapp Mobile

## Secretos

La app no debe contener tokens de Mercado Pago, secretos de webhook, `APP_KEY`, contraseñas de base de datos, client secrets ni credenciales de firma. `API_BASE_URL` es configuración pública.

El token Sanctum se guarda con `flutter_secure_storage`. No se persisten contraseñas. Logout intenta revocar el token, limpia almacenamiento local incluso si la API falla y los providers ligados al usuario eliminan caches privados.

## Firma

Keystore y contraseñas viven fuera del repositorio y se inyectan mediante variables de entorno protegidas. Consulta `RELEASE.md`. No adjuntes un keystore a issues ni reportes.

## Red y logs

Release exige entorno production y URL HTTPS. Android bloquea cleartext en main/release. Los logs de red solo existen en debug development y muestran método, ruta y status; nunca headers, bodies, token o contraseña.

## Reporte de vulnerabilidades

No publiques detalles explotables ni datos personales en un issue público. Antes del lanzamiento debe definirse un canal privado real de seguridad/soporte y documentarse su tiempo de respuesta.
