# Checklist Google Play

## Aplicación y artefacto

- [ ] Application ID confirmado: `com.chambapp.mobile`.
- [ ] `versionCode` superior a cualquier versión cargada.
- [ ] AAB release firmado con upload key.
- [ ] Google Play App Signing revisado/activado.
- [ ] API HTTPS definitiva verificada.
- [ ] APK release probado en dispositivo físico.
- [ ] Internal testing y pre-launch report sin bloqueos.

## Ficha de Play Store

- [ ] Nombre: Chambapp.
- [ ] Descripción corta y completa revisadas.
- [ ] Categoría seleccionada.
- [ ] Icono 512×512 aprobado por marca.
- [ ] Feature graphic preparada.
- [ ] Screenshots reales de teléfono y, si se distribuye, tablet.
- [ ] Email y sitio de soporte reales.
- [ ] URL pública de privacidad definitiva.
- [ ] Cuestionario de clasificación de contenido completado.
- [ ] Instrucciones y cuenta de prueba para revisores, sin versionar credenciales.

## Data Safety: inventario para revisión humana

La implementación usa o puede transmitir al backend:

- nombre, email y teléfono;
- rol y datos de perfil profesional;
- ubicación precisa al solicitar/activar disponibilidad;
- dirección, ciudad, estado y código postal;
- fotos elegidas por el usuario;
- solicitudes, servicios, cotizaciones y reseñas;
- estados y referencias de pagos procesados externamente por Mercado Pago.

- [ ] Confirmar recolección, finalidad, retención, cifrado y borrado con backend/legal.
- [ ] Declarar que la ubicación facilita profesionales/chambas cercanos.
- [ ] Confirmar que no existe tracking/background location.
- [ ] Confirmar que la app no recibe datos de tarjeta ni secretos de Mercado Pago.
- [ ] Revisar si cada dato se comparte con terceros antes de responder Play Console.

No copiar este inventario como declaración legal definitiva sin validación del responsable de privacidad.

## Requisitos pendientes conocidos

- [ ] Publicar la API y web bajo HTTPS.
- [ ] Publicar aviso de privacidad definitivo; la página actual del backend indica contenido de referencia pendiente de versión legal final.
- [ ] Definir mecanismo web/API de eliminación de cuenta si Play lo exige; no se encontró uno en el backend actual.
- [ ] Definir soporte y proceso de respuesta a incidentes.
- [ ] Confirmar marca, titularidad de assets y disponibilidad del Application ID en Play Console.
- [ ] Revisar políticas vigentes inmediatamente antes de publicar.

Las notificaciones actuales son internas; no se declara push/FCM. Google Sign-In, Crashlytics y chat no son requisitos del MVP actual.
