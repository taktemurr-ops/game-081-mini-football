# Mini Football — Game 081

Original offline Flutter/Dart penalty shootout prototype for Android and iOS.

## Features implemented in code
- Five-round shootout against randomized opponent AI
- Choose left, center or right to shoot and defend
- Keeper saves, goals, score, early clinch calculation
- Replay, status prompts and 2D illustrated stadium
- Six game-rules tests
- GitHub Actions Flutter analyze/test/Android debug APK pipeline

## Local developer commands
```bash
flutter create --platforms=android,ios .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Release readiness
**Prototype only, not A-to-Z complete or production-ready.** No passing CI result or signed build has been verified. Full multiplayer/league content, real ads and in-app purchases, accessibility, save data, real-device QA and store approvals are outstanding. See `docs/RELEASE_CHECKLIST.md`.
