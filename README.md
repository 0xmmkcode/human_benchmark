### Human Benchmark — ReactionLab

A fast, minimal reaction-time tester built with Flutter. Tap as soon as the screen turns green, chase your personal best, and compare on the global leaderboard.

This app gracefully runs with or without Firebase configured. When Firebase is present, scores are synced to Firestore and optional Google Sign‑In is supported.

### Features
- **Reaction test**: Randomized delay, clear visual states, instant feedback
- **Personal best**: Stored locally via `shared_preferences`
- **Leaderboard (optional)**: Firestore‑backed top scores
- **Auth (optional)**: Google Sign‑In (web and mobile)
- **Ads**: Google Mobile Ads (test IDs in debug, prod IDs in release)
- **Responsive UI**: Simple, accessible, and fast

### Tech Stack
- Flutter (Dart)
- Firebase: Core, Auth, Firestore
- Google Mobile Ads
- go_router, google_fonts, shared_preferences, gap

### Quick Start
1) Install Flutter and set up devices
2) Clone and fetch packages
```bash
git clone https://github.com/your-org-or-user/human_benchmark.git
cd human_benchmark
flutter pub get
```
3) (Optional) Configure Firebase — app still runs without it
- Create a Firebase project
- Enable Firestore and (optionally) Google Authentication
- Add platforms (Android, iOS, Web) and download config files
  - Android: place `google-services.json` in `android/app/`
  - iOS: add `GoogleService-Info.plist` to the Runner target
  - Web: run FlutterFire configure (see below)
- Recommended: use FlutterFire CLI to generate `lib/firebase_options.dart`
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```
If you skip Firebase, the app disables cloud features at runtime without crashing.

4) Run
```bash
flutter run
```

### Building
- Android (release):
```bash
flutter build apk --release
```
- iOS (release): open in Xcode after `flutter build ios --release`
- Web:
```bash
flutter build web --release
```

### Ads configuration
`lib/ad_helper.dart` selects Google Mobile Ads test unit IDs in debug and real IDs in release. Keep test IDs while developing to comply with AdMob policies.

### Firestore & Auth
- Scores are stored in the `leaderboard` collection keyed by `userId`
- Anonymous local play is supported; if signed in with Google, the Firebase UID is used
- Example rules and indexes are included at the repo root: `firestore.rules`, `firestore.indexes.json`

### Project structure (high level)
- `lib/main.dart`: app bootstrap, routes, Firebase init
- `lib/home_shell.dart`: bottom navigation and shell layout
- `lib/screens/reaction_time_page.dart`: core game screen
- `lib/screens/leaderboard_page.dart`: leaderboard UI
- `lib/services/leaderboard_service.dart`: Firestore writes/reads
- `lib/services/auth_service.dart`: Google sign‑in helpers
- `lib/models/user_score.dart`: score model and mapping
- `lib/ad_helper.dart`: AdMob unit ID selection
- `assets/images/`: icons and branding assets

### Development notes
- Dart SDK: see `pubspec.yaml` (`environment: sdk: ^3.8.0`)
- Linting: `flutter_lints` via `analysis_options.yaml`
- Formatting: `flutter format .`
- Analyze: `flutter analyze`

### Privacy
- Stores a pseudo‑random `userId` locally for anonymous play
- When Firebase is configured, best scores are written to Firestore
- No PII is required unless you opt into Google Sign‑In

### Troubleshooting
- If Firebase init fails, the app continues in offline mode
- Ensure Android `google-services.json` is under `android/app/`
- For iOS, confirm `GoogleService-Info.plist` is added to the Runner target
- For web, re‑run `flutterfire configure` if configs get out of sync

### License
This project’s license is not specified. Add one (e.g., MIT/Apache-2.0) if you plan to distribute.
