# KittyCircle — Architecture & Technical Specifications

> **KittyCircle — Plan. Play. Celebrate.**

This document outlines the architectural pattern, state management model, directory layout, network fallback mechanisms, and platform responsiveness strategy for **KittyCircle**.

---

## 1. Feature-First Architecture Diagram

KittyCircle adheres strictly to clean code boundaries with a **Feature-First** architecture:

```text
                  ┌─────────────────────────────────────┐
                  │          Flutter UI Views           │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │     Presentation Layer (Widgets)    │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │       State Layer (Riverpod)        │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │    Domain / Application Services    │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │         Repository Layer            │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │   Data Layer (Firebase SDKs & Local)│
                  └─────────────────────────────────────┘
```

---

## 2. Layer Responsibilities

1. **Presentation Layer (`lib/features/<feature>/presentation/`)**:
   - Contains pure Flutter widgets, screens, and modals.
   - Strictly forbidden from making direct database or Firestore calls.
   - Watches Riverpod providers for state updates.

2. **State Layer (`lib/app/providers.dart` & feature providers)**:
   - Manages UI state, loading states, error handling, active streams, and user context.

3. **Domain Layer (`lib/features/<feature>/domain/`)**:
   - Contains immutable Dart data classes (`UserModel`, `GroupModel`, `EventModel`, etc.), value objects, enums, and state models.

4. **Data / Repository Layer (`lib/features/<feature>/data/`)**:
   - Encapsulates database operations behind clean repository interfaces. Handles dual operation modes: live Firebase Firestore streams and offline fallback memory stores.

5. **Core Utility Layer (`lib/core/`)**:
   - Application theme (`AppTheme`), typography (`AppTypography`), colors (`AppColors`), failures (`Failure`), WhatsApp service (`WhatsAppService`), deep links (`DeepLinkService`), notifications (`NotificationService`), and common reusable UI components.

---

## 3. Directory Layout

```text
lib/
├── app/
│   ├── app.dart              # MaterialApp entrypoint
│   ├── providers.dart        # Global Riverpod providers
│   └── router.dart           # GoRouter route map & deep link integration
├── core/
│   ├── constants/            # Colors, fonts, constants
│   ├── errors/               # Application Failure models
│   ├── extensions/           # Date & string extensions
│   ├── services/             # WhatsApp, Deep Links, Push Notifications, Analytics
│   ├── theme/                # Light & dark Material 3 theme builders
│   └── widgets/              # PrimaryButton, SecondaryButton, AppCard, etc.
└── features/
    ├── auth/                 # Authentication & Profile Onboarding
    ├── profile/              # Profile settings, preferences, account deletion
    ├── groups/               # Kitty group management & settings
    ├── members/              # Roster management & WhatsApp invitations
    ├── events/               # Event lifecycle, RSVPs, Attendance, Potluck, Timeline
    ├── games/                # Party Games Engine, Session manager, Winner declaration
    ├── contributions/        # Contribution tracking & payment status
    ├── expenses/             # Expense categorization & party budget visualizer
    ├── memories/             # Photo gallery & memory storage
    ├── notifications/        # Push notifications & in-app alerts
    └── sharing/              # External invitation & summary share helpers
```

---

## 4. Navigation & Deep Linking Strategy

Navigation is managed via `go_router` with deep link handling:

| Route Path | Screen | Deep Link Payload |
|---|---|---|
| `/` | `MainNavigationShell` (Home Tab) | N/A |
| `/login` | `LoginScreen` | N/A |
| `/profile` | `ProfileScreen` | `userId` |
| `/group/create` | `CreateGroupScreen` | N/A |
| `/group/:groupId` | `GroupDetailScreen` | `groupId` |
| `/join/group/:groupId` | `GroupDetailScreen` (Invitation Mode) | `groupId` |
| `/event/create` | `CreateEventScreen` | `groupId` |
| `/event/:eventId` | `EventDetailScreen` | `groupId`, `eventId` |
| `/theme-library` | `ThemeLibraryScreen` | N/A |
| `/create-next-kitty` | `CreateNextKittyScreen` | `groupId` |
| `/game-library` | `GameLibraryScreen` | `groupId`, `eventId` |
| `/game/host/:gameId` | `LiveGameHostScreen` | `groupId`, `eventId`, `gameId` |
| `/game/player/:gameId` | `PlayerGameScreen` | `groupId`, `eventId`, `gameId` |
| `/game/winners/:sessionId` | `WinnerDeclarationScreen` | `groupId`, `sessionId` |

---

## 5. Offline & Fallback Architecture

To guarantee zero-downtime during offline usage or local demo testing without a live Firebase backend connection:

```dart
// Check Firebase initialization gracefully
if (Firebase.apps.isNotEmpty) {
  // Execute live Firestore stream query
} else {
  // Fallback to reactive in-memory state repository
}
```
