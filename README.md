# LoveQuiz

App de parejas: partidas de preguntas para conocerse mejor, con modo
presencial y en línea (Firestore), recuerdos de voz y temas especiales.

## Stack

- Flutter (Android / iOS)
- Firebase: Auth (Google), Cloud Firestore, Cloud Messaging, Cloud Functions
- GoRouter para la navegación
- Cloudinary para fotos de perfil y audio de recuerdos
- Motor de preguntas propio en `lib/features/game_engine` (convive con el flujo
  legacy de `lib/screens/game_play_screen.dart`)

## Estructura

- `lib/features/`: módulos por dominio (motor de juego, recuerdos de voz,
  notificaciones push).
- `lib/screens/`: pantallas del flujo legacy.
- `lib/services/`, `lib/data/`, `lib/config/`: servicios, bancos de preguntas y
  configuración (colores, Cloudinary, banderas beta).
- `test/`: tests del motor, del repositorio de recuerdos de voz y de flujos.

## Desarrollo

```bash
flutter pub get
flutter analyze
flutter test
```

### Notas de configuración

- **Cloudinary**: los presets `lovequiz_profiles` y `lovequiz_voice`
  (`lib/config/cloudinary_config.dart`) deben existir como *unsigned presets*
  en el dashboard (el segundo con `audio/*` en "Accepted files").
- **Backup de Android**: se excluye `shared_preferences` del backup/restore
  para no restaurar sesiones locales en otros dispositivos
  (`android/app/src/main/res/xml/*.xml`).
- **Rutas de desarrollo**: `/voice-demo` y `/engine-test` solo se registran en
  modo debug (`kDebugMode` en `lib/main.dart`).

## Modo beta

`BetaConfig.isBetaEnabled` activa el registro temprano de FCM. El borrado de
recuerdos de voz lo hace la Cloud Function con el SDK admin; el cliente no
puede borrarlos por reglas de Firestore (`allow delete: if false`).
