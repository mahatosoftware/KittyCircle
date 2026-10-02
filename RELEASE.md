# KittyCircle — Production Release & Deployment Guide

> **KittyCircle — Plan. Play. Celebrate.**

This document details steps for building production release artifacts, deploying Firebase security rules, setting up Remote Config, and releasing to Google Play Store and Apple App Store.

---

## 1. Deploying Firebase Infrastructure

### 1.1 Firestore & Storage Security Rules

Deploy security rules to your live Firebase project:

```bash
firebase deploy --only firestore:rules,storage
```

### 1.2 Remote Config Parameters

Configure the following key-value pairs in **Firebase Remote Config** console:

| Parameter Key | Default Value | Description |
|---|---|---|
| `enable_whatsapp_direct` | `true` | Toggles direct WhatsApp intent vs system sheet |
| `max_memories_per_event` | `50` | Maximum photos per event gallery |
| `featured_party_theme` | `Diwali Dhamaka` | Highlighted theme on theme library banner |
| `game_engine_enabled` | `true` | Remote kill-switch for live party games |

---

## 2. Building Release Binaries

### 2.1 Android APK & App Bundle

```bash
# Generate Release App Bundle (AAB) for Google Play
flutter build appbundle --release

# Generate Release APK for direct distribution
flutter build apk --release --split-per-abi
```

Artifact outputs:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APKs: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### 2.2 iOS IPA for App Store Connect

```bash
# Build iOS Release Archive
flutter build ipa --release
```

Open Xcode Organizer to validate and submit the `.xcarchive` to App Store Connect.

---

## 3. Pre-Release Checklist

- [x] Run `flutter test` — All unit, widget, and integration tests passing.
- [x] Confirm no Tambola/Housie references or code exist.
- [x] Ensure Firebase Auth phone sign-in APNs / SHA-256 fingerprints registered.
- [x] Confirm `firestore.rules` and `storage.rules` deployed.
- [x] Verify Crashlytics and Analytics initialization in `main.dart`.
