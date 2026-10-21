# Shopesphere

Shopesphere is a Flutter shopping app prototype. It uses [DummyJSON](https://dummyjson.com/) for product data, demo authentication, and cart API requests. A local SQLite database keeps each signed-in user's cart available after the app closes. Checkout is a demo flow; it does not process payments or create a real order.

## Features

- Sign in and restore a saved session. Access and refresh tokens are stored with `flutter_secure_storage`.
- Browse the product catalog, search products, and filter by category.
- View product information, reviews, and a swipeable image gallery with thumbnails.
- Add products to the cart from the product details page, adjust quantities, and remove items.
- Persist cart contents locally in SQLite, separated by user, and attempt to sync cart changes with DummyJSON.
- Review totals and complete a demo checkout without payment processing.

## Requirements

- Flutter SDK with Dart **3.13.5 or newer** (see the SDK constraint in `pubspec.yaml`).
- Android Studio and an Android SDK for Android development, or macOS with Xcode for iOS development.
- Network access for sign-in and product catalog requests.

Check your Flutter installation and available devices:

```bash
flutter doctor
flutter devices
```

## Setup

```bash
git clone <repository-url>
cd ecommerce_app
flutter pub get
flutter run
```

If more than one device is connected, choose one explicitly:

```bash
flutter run -d <device-id>
```

Sign in with an account supported by the [DummyJSON authentication API](https://dummyjson.com/docs/auth). The app needs internet access to sign in and load products.

## Development commands

```bash
# Format Dart files
dart format lib test

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Build a release Android APK
flutter build apk --release

# Build an iOS release (requires macOS and Xcode)
flutter build ios --release
```

## Project layout

```text
lib/
  api/          HTTP client and API error handling
  constants/    Shared app colors and visual constants
  data/         Local SQLite cart database
  model/        Product and user models
  provider/     Riverpod authentication, product, and cart state
  screens/      Login, product details, cart, checkout, and profile screens
  main.dart     App entry point and session/splash flow
test/           Product model, cart calculation, and widget tests
```

## Data and persistence

The API client uses `https://dummyjson.com` as its base URL. Product and authentication requests require a network connection. DummyJSON is a demo API, so remote cart mutations should be treated as simulated and may not remain available between sessions.

Cart contents are stored in the app's SQLite database (`shopesphere.db`) under the signed-in user's ID. The cart is written locally before a remote sync is attempted. If syncing fails, the local cart remains available and the cart screen offers a retry action. Existing cart data from older app versions is imported from secure storage when possible. Authentication tokens remain in secure storage and are not kept in the cart database.

The SQLite implementation targets Flutter platforms supported by `sqflite` (Android, iOS, and macOS). Web and desktop platforms without a compatible SQLite factory need a different storage implementation.

## Tests

Tests are in `test/`:

- `product_model_test.dart` covers product parsing, image fallback, reviews, and serialization.
- `cart_provider_test.dart` covers discounted unit prices, line totals, cart quantity, and subtotal calculations.
- `product_card_test.dart` checks product card content and verifies the card does not show an add-to-cart button.

Run them with `flutter test`.

## Troubleshooting

- **Flutter or Dart version errors:** install a Flutter SDK that includes Dart 3.13.5 or newer, then run `flutter pub get` again.
- **No device found:** start an Android emulator or connect an Android device with USB debugging enabled. For iOS, use a simulator or device configured in Xcode on macOS.
- **Sign-in or catalog errors:** check internet access and use an account supported by DummyJSON. The app can restore a saved session if the profile endpoint is temporarily unavailable.
- **Android/iOS plugin setup issues:** run `flutter doctor` and follow its platform-specific setup guidance.
