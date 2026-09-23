# TravelWise Mobile

Flutter mobile client for the TravelWise travel planning platform (SE3090).

## Getting Started

```bash
cd mobile
flutter pub get
flutter run
```

### Environment Configuration

Copy `.env` and set the correct backend URL:
- **Android emulator**: `http://10.0.2.2:5135/api`
- **Desktop / iOS simulator**: `http://localhost:5135/api`

## Architecture

- **State Management**: Riverpod (StateNotifier)
- **Networking**: Dio with auth interceptors
- **Routing**: GoRouter with auth redirect guards
- **Design System**: Liquid Glass (native BackdropFilter)
- **Token Storage**: flutter_secure_storage
