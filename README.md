# KittyCircle — Plan. Play. Celebrate.

<p align="center">
  <img src="assets/images/app_logo.png" width="160" alt="KittyCircle Logo" />
</p>

**KittyCircle** is a modern social, event-management, and party-game platform built specifically for recurring kitty party groups using **Flutter, Dart, Riverpod, and Firebase**.

---

## 🌟 Product Vision

Traditional kitty party groups struggle with disorganized WhatsApp chats, host tracking, manual RSVPs, contribution calculations, and repetitive party planning. **KittyCircle** elevates the entire experience into a social, fun, premium, and simple application focused on **running the actual party**.

> **Note**: KittyCircle is a general party platform. It does NOT include Tambola/Housie/Bingo games. Instead, it introduces an extensible **Party Games Engine**.

---

## ✨ Key Features

- **🌸 Multi-Kitty Group Management**: Belongs to multiple kitty groups with distinct schedules, members, contribution amounts, and currencies.
- **👑 Automatic Host Rotation & Scheduling**: Dynamic calendar listing past and upcoming hosts with single-tap host notification.
- **✨ Complete Party Event Planner**: Schedule parties, track RSVPs, manage potluck food items, timeline schedules, and dress code themes.
- **🎨 12 Theme Library Presets**: Festive themes (Diwali, Bollywood, Floral High Tea, Royal Ethnic) complete with dress codes, decor, food ideas, games, and prize recommendations.
- **🎮 Party Games Engine**: Extensible game engine with 9 built-in games:
  - 🎁 Lucky Draw (Random Winner Selection)
  - 🧠 Memory Challenge
  - 🎬 Bollywood Quiz
  - 😀 Emoji Guess (Puzzles & Proverbs)
  - 🎵 Guess the Song
  - ⚡ Rapid Fire
  - 🔤 Word Challenge
  - 🎯 Target Challenge
  - 🛠️ Custom Host Game
- **🏆 Live Podium & Confetti Celebration**: Declare winners with festive confetti, prize badges, and WhatsApp winner cards.
- **💰 Social Money Tracker**: Track group contributions (Paid, Pending, Partial, Exempt) and party expenses with budget visualizers without feeling like an accounting app.
- **📸 Memory Gallery**: High-res party photo gallery with group privacy.
- **💬 WhatsApp Native Invites & Summaries**: Pre-formatted WhatsApp deep link messages for group invites, party details, and winner declarations.
- **🔄 Automated Next Kitty Wizard**: 1-tap automated wizard that rotates the host, schedules the next meeting date, and resets contribution status.

---

## 📱 Tech Stack & Architecture

- **Frontend**: Flutter & Dart (Cross-platform Android, iOS, Tablet & Web)
- **State Management**: Riverpod 2.6 (`flutter_riverpod`)
- **Navigation**: GoRouter (`go_router`) with deep linking support
- **Backend Services**:
  - Firebase Authentication (Phone, Google Sign-In, Email/Password)
  - Cloud Firestore (Multi-tenant group isolation)
  - Firebase Cloud Storage (Photos, receipts)
  - Firebase Analytics & Crashlytics
- **Sharing & UI**: `share_plus`, `url_launcher`, `confetti`, `fl_chart`, `cached_network_image`, `shimmer`, `table_calendar`

---

## 🏛️ Architecture Overview

KittyCircle follows a strict **Feature-First Architecture** with Repository pattern:

```text
Flutter UI Views
   ↓
Presentation Widgets
   ↓
Riverpod Providers
   ↓
Application / Domain Layer
   ↓
Repositories & Firebase Services
   ↓
Firestore / Cloud Storage
```

---

## 🚀 Quick Start

1. **Clone repo & install packages**:
   ```bash
   flutter pub get
   ```

2. **Run tests**:
   ```bash
   flutter test
   ```

3. **Launch application**:
   ```bash
   flutter run
   ```

*(In non-Firebase or offline environments, KittyCircle runs seamlessly in **Demo Mode** with pre-populated sample Kitty data!)*

---

## 📚 Documentation Index

- [FIRESTORE_SCHEMA.md](file:///Volumes/DebasishApple/DeveloperExt/Apps/KittyCircle/FIRESTORE_SCHEMA.md) — Complete database schema & indexing
- [SECURITY_RULES.md](file:///Volumes/DebasishApple/DeveloperExt/Apps/KittyCircle/SECURITY_RULES.md) — Security authorization matrix & rule specs
- [GAME_ENGINE.md](file:///Volumes/DebasishApple/DeveloperExt/Apps/KittyCircle/GAME_ENGINE.md) — Party Games Engine developer guide
- [ARCHITECTURE.md](file:///Volumes/DebasishApple/DeveloperExt/Apps/KittyCircle/ARCHITECTURE.md) — Architectural pattern & layer boundaries
- [DEVELOPMENT_SETUP.md](file:///Volumes/DebasishApple/DeveloperExt/Apps/KittyCircle/DEVELOPMENT_SETUP.md) — Developer setup & testing guide
- [RELEASE.md](file:///Volumes/DebasishApple/DeveloperExt/Apps/KittyCircle/RELEASE.md) — Production release & deployment guide
