# KittyCircle — Development Setup Guide

> **KittyCircle — Plan. Play. Celebrate.**

This guide covers prerequisites, local environment configuration, running unit & integration tests, and executing **KittyCircle** on Android, iOS, or macOS.

---

## 1. Prerequisites

Before building KittyCircle, verify your environment has the following installed:

- **Flutter SDK**: `>=3.3.0` (Dart SDK `>=3.0.0`)
- **Android SDK**: API level 21 or higher
- **Xcode**: 14.0 or higher (for iOS / macOS builds)
- **CocoaPods**: Installed via `brew install cocoapods` or `gem install cocoapods`
- **Firebase CLI**: Installed via `npm install -g firebase-tools`

---

## 2. Local Setup Steps

### Step 1: Clone Repository & Install Dependencies

```bash
cd KittyCircle
flutter pub get
```

### Step 2: Configure Firebase Options

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Link your Firebase project:
   ```bash
   flutterfire configure --project=your-firebase-project-id
   ```

*(Note: If no Firebase project is configured yet, KittyCircle will run seamlessly in Demo Mode with populated in-memory data!)*

---

## 3. Running the App

### Run on Mobile Simulator / Emulator

```bash
# Android
flutter run -d android

# iOS Simulator
flutter run -d iPhone
```

### Quick Demo Mode Sign-In
On the login screen, tap **"Quick Demo Sign-In"** to bypass phone verification and test the complete app experience immediately with pre-loaded sample Kitty groups.

---

## 4. Running Test Suites

KittyCircle includes complete unit, widget, and end-to-end integration test coverage.

### Run All Tests

```bash
flutter test
```

### Run Specific Test Files

```bash
# Unit Tests (Group Repository)
flutter test test/unit/group_test.dart

# Unit Tests (Event Model & RSVP)
flutter test test/unit/event_test.dart

# Unit Tests (Party Games Engine)
flutter test test/unit/game_engine_test.dart

# Integration Test (Full Party Lifecycle Flow)
flutter test test/integration/full_party_flow_test.dart
```
