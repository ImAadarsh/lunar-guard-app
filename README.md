# Lunar Security — Guard app (Flutter)

Guard mobile app with backend integration for:
- Login + optional 2FA
- Profile/session restore
- Shift list + attendance check-in/out
- Patrol scan submission + history
- Incident submission + photo upload
- SOS trigger
- Dashboard summary
- Live QR scanner and map preview

## Brand

- Primary navy/teal: `#0D3240` / `#0A1F28`
- Assets: `assets/images/logo_full.jpeg`, `logo_mark.png` (copied from repo root)

## Required backend

Start API first:

```bash
cd ../backend
npm run db:migrate
npm run seed:demo
npm start
```

Demo guard login:
- Email: `guard@lunarsecurity.demo`
- Password: `GuardDemo#2026`

## Environment variables

### 1) Backend `.env` (required location)

File: `../backend/.env`

Add/verify:

```env
PORT=4000
UPLOAD_FILES_DIR=
GOOGLE_MAPS_API_KEY=
```

`UPLOAD_FILES_DIR` can stay empty to use default `backend/uploads`.

### 2) Flutter API base URL

Use `--dart-define` when running:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:4000
```

For physical Android over USB, use `adb reverse` (recommended):

```bash
adb reverse tcp:4000 tcp:4000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:4000
```

### 3) Google Maps API key (where to add)

You must set this in two places:

1) **Run-time dart define** for in-app checks:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
```

2) **Platform files** for native map SDK:

- Android: set `GOOGLE_MAPS_API_KEY=YOUR_KEY` in:
  `android/local.properties`
- iOS: set `GOOGLE_MAPS_API_KEY=YOUR_KEY` in:
  `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`

The app already reads these placeholders from:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### One-time: generate Android / iOS / macOS / Web

This repo was scaffolded with `lib/` only. If `flutter run` says **devices are not supported by this project**, generate platform folders:

```bash
cd lunar_security_guard
flutter pub get
flutter create . --platforms=android,ios,macos,web
```

Or: `chmod +x scripts/bootstrap_platforms.sh && ./scripts/bootstrap_platforms.sh`

### Run on a physical Android phone (e.g. A015)

1. On the phone: **Settings → Developer options → USB debugging** (on). Connect USB.
2. Accept the **RSA fingerprint** prompt on the phone when you first `flutter run`.
3. List devices:
   ```bash
   flutter devices
   ```
4. Reverse backend port (USB):
   ```bash
   adb reverse tcp:4000 tcp:4000
   ```
5. Run on that device (use the id from the list, e.g. `00116646S014276`):
   ```bash
   flutter run -d 00116646S014276 \
     --dart-define=API_BASE_URL=http://127.0.0.1:4000 \
     --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
   ```
   Or pick interactively: `flutter run` (choose device when prompted).

If Android tooling complains: `flutter doctor` and `flutter doctor --android-licenses`.

### Desktop / Chrome (optional)

```bash
flutter run -d macos
flutter run -d chrome
```

## Structure

- `lib/theme/` — colors + `ThemeData` (Material 3, Inter via `google_fonts`)
- `lib/features/splash/` — branded splash → login
- `lib/features/auth/` — email/password (mock sign-in → main shell)
- `lib/features/shell/` — `NavigationBar` + 5 tabs
- Tabs: `home`, `shift`, `patrol`, `safety`, `profile`

## Verification

```bash
flutter pub get
flutter analyze
flutter test
```

If API requests fail on device, first verify:
- backend running on port `4000`
- `adb reverse --list` includes `tcp:4000 tcp:4000`
- `API_BASE_URL` dart define matches your setup
