# Flutter API Integration Quickstart

## 1. Instalar dependencias

- `flutter pub get`

## 2. Ejecutar app con URL del backend

Usa `--dart-define` para configurar API_BASE_URL:

- Emulador Android hacia localhost del host:
  - `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api`
- iOS Simulator en macOS:
  - `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api`
- Dispositivo fisico (ejemplo):
  - `flutter run --dart-define=API_BASE_URL=http://192.168.1.15:3000/api`

## 3. Flujo actual habilitado

- Login con backend real (`/auth/login`)
- Refresh token automatico por interceptor ante 401 (`/auth/refresh`)
- Cierre de sesion (`/auth/logout`)
- Bootstrap de sesion con `/auth/me`
- Selector de empresa activa (`/companies` + `/auth/select-company`)
- Listado y creacion basica de clientes (`/customers`)
- Listado y creacion basica de prestamos (`/loans`)
- Historial de pagos por prestamo, registro y anulacion (`/loans/:id/payments`, `/payments/:id/void`)

## 4. Archivos clave

- `lib/core/network/api_client.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/session/session_store.dart`
- `lib/core/session/session_controller.dart`
- `lib/features/auth/data/auth_api.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/home_screen.dart`
- `lib/features/companies/data/companies_api.dart`
- `lib/features/customers/data/customers_api.dart`
- `lib/features/customers/presentation/customers_screen.dart`
- `lib/features/loans/data/loans_api.dart`
- `lib/features/loans/presentation/loans_screen.dart`
- `lib/features/payments/data/payments_api.dart`
- `lib/features/payments/presentation/loan_payments_screen.dart`
