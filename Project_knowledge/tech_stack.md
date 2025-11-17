# Tech Stack

## Mobile App
- Framework: Flutter 3.x
- Language: Dart 3.x
- State Management: Riverpod (boleh diganti Provider/BLoC kalau diperlukan)
- Architecture: 
  - `presentation` (UI / widgets / screens)
  - `application` (state, controllers, use-cases)
  - `infrastructure` (Supabase services, repositories)
  - `domain` (models, entities)

## Backend
- BaaS: Supabase
- Database: PostgreSQL (default dari Supabase)
- SDK: `supabase_flutter ^2.x`
- Auth: **Tidak digunakan dulu** (single user per device)
- RLS: Boleh dimatikan dulu di tabel-tabel app selama fase offline/personal.

## Environment
- Build target: Android (minimal SDK disesuaikan default Flutter)
- iOS: optional (future)
