# 🥩 Fresh Meat Market

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#)

Artisanal halal meat delivery mobile application built with **Flutter**, featuring real-time butcher pricing synchronization via **Telegram Bot & Google Sheets**, interactive delivery location tracking, and duplicate-safe slide-to-confirm checkout.

---

## 📖 Overview

Fresh Meat Market connects consumers directly with trusted local artisanal butchers for fresh, ethically sourced halal cuts (mutton, chicken, beef, and coastal seafood). Designed with a modern crimson and cream visual direction, fluid liquid-motion navigation, and serverless price automation, the app provides a seamless ordering experience from cut selection to doorstep delivery.

---

## ✨ Implemented Features

### 🛒 Customer Experience
- **Artisanal Cut Catalog**: Browse mutton, chicken, beef, and seafood with weight selection options (500 g, 1 kg, 2 kg) and culinary cut descriptions.
- **Cinematic Fluid UI**: Custom spring-physics floating navigation dock (`LiquidSlidingDock`), rotating title ticker, and interactive fly-to-bag parabolic animations.
- **Interactive Delivery Address Selector**: Street map interface with vector drop-pin marker, GPS live location detection (`geolocator`), and saved address chips.
- **Duplicate-Safe Checkout**: Slide-to-order confirmation backed by UUIDv4 idempotency keys and a 90-second duplicate order prevention window.
- **Live Order Tracking**: Vector map view showing delivery rider position, milestone status progression, estimated delivery times, and direct driver contact options.
- **Digital Invoice**: Built-in thermal paper receipt view detailing itemized prices, delivery slots, and verification signatures.

### ⚙️ Store Owner & Backend Automation
- **Telegram Bot Price Controller**: Store owners update daily meat rates via inline buttons or chat commands (`/price mutton 850`), with changes logged instantly to Google Sheets.
- **Serverless Live Price Sync**: Automated polling and pull-to-refresh endpoints that synchronize live market prices from Google Apps Script into the app with offline caching (`SharedPreferences`).
- **Storefront Administration**: Admin portal to update shop name, operational status, opening hours, FSSAI / Halal certification details, and assign riders from the delivery fleet.
- **Authentication**: Firebase Authentication supporting Google Sign-In with transparent local guest fallback.

---

## 🛠️ Tech Stack

| Layer | Technologies |
|---|---|
| **Mobile Framework** | [Flutter](https://flutter.dev) (SDK `>=3.3.0 <4.0.0`) |
| **Language** | [Dart](https://dart.dev) 3.x |
| **State Management** | [Provider](https://pub.dev/packages/provider) |
| **Typography** | [Google Fonts](https://pub.dev/packages/google_fonts) (`Unbounded` & `Manrope`) |
| **Auth & Cloud** | [Firebase Core](https://pub.dev/packages/firebase_core), [Firebase Auth](https://pub.dev/packages/firebase_auth), [Google Sign-In](https://pub.dev/packages/google_sign_in) |
| **Device Services** | [Geolocator](https://pub.dev/packages/geolocator), [URL Launcher](https://pub.dev/packages/url_launcher), [Shared Preferences](https://pub.dev/packages/shared_preferences) |
| **Backend & Webhooks** | Google Apps Script, Google Sheets, Telegram Bot API, Node.js Serverless Webhook |

---

## 📂 Project Structure

```text
Fresh-Meat/
├── android/                   # Native Android host project (Kotlin, Gradle 8.x)
├── assets/images/             # Bundled cut imagery, avatars, and app logo
├── backend_automation/        # Serverless backend & Telegram bot automation
│   ├── api_webhook.js         # Node.js / Vercel serverless webhook handler
│   ├── README.md              # Detailed Google Sheets & Telegram bot setup guide
│   └── telegram_sheets_bot.gs # Google Apps Script backend logic
├── lib/
│   ├── models.dart            # Domain models (Product, CartItem, Order, UserProfile, etc.)
│   ├── data.dart              # Baseline catalog data, butchers, and cuts
│   ├── firebase_options.dart  # Firebase project configurations
│   ├── main.dart              # Flutter application entry point
│   ├── theme.dart             # Palette (Crimson, Ember, Cream) and typography tokens
│   ├── screens/
│   │   ├── splash_screen.dart       # Animated brand splash screen
│   │   ├── onboarding_screen.dart   # Customer onboarding walkthrough
│   │   ├── login_screen.dart        # Authentication (Google Sign-In / Guest)
│   │   ├── home_screen.dart         # Main storefront catalog & dock
│   │   ├── product_screen.dart      # Product weight selection & culinary details
│   │   ├── bag_screen.dart          # Cart, delivery slots & slide-to-confirm
│   │   ├── tracking_screen.dart     # Real-time order tracking & status timeline
│   │   ├── fish_screen.dart         # Seafood catalog & preview
│   │   └── admin_shop_screen.dart   # Butcher shop management & fleet assignment
│   ├── services/
│   │   ├── auth_service.dart        # Firebase & Google authentication
│   │   ├── location_service.dart    # GPS geolocation & address reverse-geocoding
│   │   ├── price_sync_service.dart  # Live Google Apps Script pricing sync
│   │   └── admin_role_service.dart  # Admin verification
│   ├── state/
│   │   └── app_state.dart           # Central ChangeNotifier with SharedPreferences persistence
│   └── widgets/
│       ├── all_cuts_menu.dart       # Full meat cut catalog modal
│       ├── delivery_address_sheet.dart # Interactive address sheet with pin map
│       ├── fly_to_bag.dart          # Parabolic curved cart animation
│       ├── google_user_avatar.dart  # User profile avatar & login trigger
│       ├── liquid_motion.dart       # Spring-physics animated bottom navigation dock
│       ├── paper_invoice.dart       # Printable thermal receipt widget
│       ├── real_map_view.dart       # Vector map painter for live tracking
│       └── steak.dart               # Procedural vector illustrations
├── test/                      # Comprehensive unit and widget tests
├── .gitignore                 # Environment, build, and platform ignore rules
├── LICENSE                    # MIT License
└── pubspec.yaml               # Flutter package dependencies and assets
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) `3.22.0` or higher
- [Dart SDK](https://dart.dev/get-dart) `3.3.0` or higher
- Android Studio / Android SDK platform-tools (API level 35 target)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/nfsprogramming/Fresh-Meat.git
   cd Fresh-Meat
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code analysis:
   ```bash
   flutter analyze
   ```
4. Launch the application:
   ```bash
   flutter run
   ```

---

## 🤖 Backend Automation Setup

The repository includes a serverless pricing backend in [`backend_automation/`](backend_automation/).

1. Open [Google Sheets](https://sheets.new) and create a sheet named **Fresh Meat Market Database**.
2. Open **Extensions > Apps Script** and paste [`backend_automation/telegram_sheets_bot.gs`](backend_automation/telegram_sheets_bot.gs).
3. Set your Telegram Bot Token and deploy the script as a Web App (access: *Anyone*).
4. Run `setupDatabaseSheets` to format your pricing and orders sheets.
5. In the Flutter app, open **Profile > Daily Pricing Automation** and paste your Web App URL to enable live rate synchronization.

For a full step-by-step walkthrough, see [`backend_automation/README.md`](backend_automation/README.md).

---

## 🧪 Testing

The repository includes unit and widget tests covering catalog rendering, state transitions, navigation docks, address selection, and price synchronization:

```bash
flutter test
```

All 21 tests pass without errors or warnings.

---

## 📦 Building for Release

To compile an Android release APK:

```bash
flutter build apk --release
```

The compiled package will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

To install directly to an attached Android device:
```bash
flutter install
```

---

## 🔒 Security & Data Privacy

- **No Hardcoded Secrets**: Credentials, keystores, and bot tokens must be provided via environment variables or configured in your private deployment.
- **Idempotent Ordering**: Every placed order generates a unique hash and UUIDv4 token to avoid unintentional double billing or duplicate deliveries.
- **Local Storage**: Customer profile, cart data, and delivery preferences are stored securely on-device using platform-native `SharedPreferences`.

---

## 🤝 Contributing

Contributions, feature requests, and bug reports are welcome!
1. Fork the project.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m "Add amazing feature"`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
