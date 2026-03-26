# Frontend (Flutter)

## Run locally

```bash
flutter pub get
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

## Build for Cloudflare Pages

```bash
flutter build web --release --dart-define=BACKEND_BASE_URL=https://YOUR_CLOUD_RUN_URL
```

Upload `build/web` to Cloudflare Pages.
