# Chambapp Mobile 📱🛠️

**Chambapp** es una aplicación móvil desarrollada en **Flutter** (Android & iOS) diseñada para conectar de forma rápida, segura y transparente a clientes con profesionales y trabajadores de diversos oficios (chambas), tanto en modalidad **on-demand** (inmediata) como **programada**.

La aplicación se comunica con una API REST en **Laravel**, manteniendo una separación estricta de responsabilidades, seguridad en los datos y sincronización de estados en tiempo real.

---

## 🚀 Características Principales

### 👤 Modo Cliente
- **Autenticación Segura:** Registro e inicio de sesión con tokens persistentes en almacenamiento seguro (`flutter_secure_storage`).
- **Exploración y Búsqueda:** Catálogo de categorías, servicios destacados y búsqueda en tiempo real con debounce y filtros avanzados.
- **Solicitud de Chambas:**
  - **Inmediata (On-Demand):** Flujo guiado para solicitar servicios urgentes con detección automática de ubicación y matching en vivo.
  - **Programada:** Agenda citas eligiendo fecha futura, franja horaria y dirección personalizada.
- **Gestión y Seguimiento:** Monitoreo en tiempo real del estado de cada chamba (`buscando`, `asignado`, `en camino`, `en progreso`, `finalizado`).
- **Cotizaciones y Pagos:** Recepción de cotizaciones transparentes y pasarela de pago segura.
- **Calificaciones y Reseñas:** Sistema de feedback con estrellas y comentarios para valorar el servicio recibido.
- **Favoritos y Notificaciones:** Guarda a tus profesionales de confianza y recibe alertas sobre el estado de tus solicitudes.

### 👷 Modo Profesional
- **Gestión de Disponibilidad:** Activa o desactiva tu disponibilidad operativa y define tu radio de cobertura (5, 10, 15 o 25 km) mediante GPS.
- **Oportunidades en Tiempo Real:** Recepción de invitaciones de trabajo cercanas con temporizador de expiración y aceptación inmediata.
- **Catálogo de Servicios:** Crea, edita y administra los servicios que ofreces con precios base y descripciones.
- **Flujo Operativo Paso a Paso:** Notifica al cliente tus avances con un solo toque: *En camino*, *Llegué al sitio*, *Iniciar trabajo* y *Finalizar trabajo*.
- **Control de Trabajos y Ganancias:** Historial detallado de chambas completadas, desglose de cotizaciones y métricas de ingresos.
- **Perfil Profesional:** Personalización de biografía, experiencia, zona de cobertura y foto de perfil.

---

## 🛠️ Stack Tecnológico

- **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x)
- **Gestor de Estado:** [Riverpod](https://riverpod.dev/) (StateNotifier / Providers)
- **Navegación:** [GoRouter](https://pub.dev/packages/go_router) con guards de autenticación y redirecciones dinámicas
- **Cliente HTTP:** [Dio](https://pub.dev/packages/dio) con interceptores para Bearer Tokens y manejo centralizado de errores
- **Almacenamiento Local:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) para credenciales y tokens cifrados
- **Geolocalización:** [Geolocator](https://pub.dev/packages/geolocator) para ubicación precisa y cálculo de radios de servicio
- **Diseño & UI:** Material Design personalizado con paleta de colores propia, dark/light ready y componentes reutilizables

---

## 📂 Estructura del Proyecto

El proyecto sigue una arquitectura modular y escalable orientada a características (**Feature-First**):

```text
lib/
├── app/                  # Configuración global, providers principales y rutas (GoRouter)
├── core/
│   ├── config/           # Variables de entorno y configuración de API
│   ├── constants/        # Constantes de la aplicación
│   ├── errors/           # Mapeo de errores HTTP a excepciones de dominio
│   ├── network/          # Cliente Dio, interceptores y manejo de sesiones
│   ├── storage/          # Almacenamiento seguro de tokens y preferencias
│   └── theme/            # Tokens de diseño, tipografía, colores y ThemeData
├── features/
│   ├── auth/             # Login, registro, splash y estado de autenticación
│   ├── catalog/          # Categorías, servicios, búsqueda y perfiles públicos
│   ├── favorites/        # Sistema de profesionales y servicios favoritos
│   ├── home/             # Pantallas principales para clientes
│   ├── jobs/             # Flujos de solicitud, cotizaciones, checkout y seguimiento
│   ├── location/         # Servicios de GPS y selector manual de dirección
│   ├── navigation/       # Shells y barras de navegación persistentes
│   ├── notifications/    # Centro de notificaciones in-app
│   ├── professional/     # Panel profesional: disponibilidad, servicios, perfil e invitaciones
│   ├── profile/          # Perfil de usuario y ajustes
│   └── reviews/          # Calificaciones y reseñas
└── shared/
    └── widgets/          # Componentes visuales reutilizables (botones, inputs, cards, headers)
```

---

## ⚙️ Configuración y Ejecución

### Prerrequisitos
- Flutter SDK (versión 3.24 o superior)
- Dart SDK 3.x
- Android Studio / Xcode configurados con sus emuladores correspondientes
- Backend de Chambapp en ejecución (local o remoto)

### 1. Clonar el repositorio e instalar dependencias
```bash
git clone https://github.com/roman00120/chambapp-mobile.git
cd chambapp-mobile
flutter pub get
```

### 2. Ejecución en desarrollo

#### Android Emulator
El emulador de Android utiliza `10.0.2.2` para comunicarse con el servidor local del host:
```bash
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

#### Dispositivo Físico
Para probar en un teléfono conectado a tu red local Wi-Fi:
```bash
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://TU_IP_LOCAL:8000/api/v1
```

#### Windows Desktop / Web
```bash
flutter run -d windows --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

---

## 🔒 Ambientes y Compilación para Producción

La aplicación maneja configuración por variables de compilación (`--dart-define`):

- **`APP_ENV=development`**: Habilita logs seguros de peticiones y respuestas para depuración.
- **`APP_ENV=production`**: Requiere obligatoriamente una URL segura HTTPS.

### Compilar APK / AppBundle de producción
```bash
# APK Release
flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://chambapp.com.mx/api/v1

# Android App Bundle (Play Store)
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://chambapp.com.mx/api/v1
```

---

## 🧪 Pruebas y Calidad de Código

El proyecto cuenta con una amplia suite de pruebas unitarias y de widgets que cubren los flujos críticos de la aplicación:

```bash
# Análisis estático de código
flutter analyze

# Formato de código
dart format --set-exit-if-changed .

# Ejecutar suite de pruebas
flutter test
```

---

## 📄 Licencia

Desarrollado por **Roman Velasco Moctezuma**. Todos los derechos reservados. Proyecto privado.
