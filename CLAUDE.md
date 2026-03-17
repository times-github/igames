# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter-based gaming platform using GetX framework, Dio for networking, and responsive design for both mobile and desktop web. The app supports multi-language (Chinese, English, Indonesian) and includes authentication, game launching, user profiles, and payment features.

## Essential Commands

### Development
```bash
flutter pub get                    # Install/update dependencies
flutter run -d chrome              # Run web version (primary development target)
flutter run -d macos               # Run macOS version
flutter run -d android             # Run Android version
dart format .                      # Format code
```

After code generation, run `flutter run -d chrome` or press `r`/`R` in terminal to hot reload. Use Chrome MCP tool to verify generated web pages.

### Testing & Building
```bash
flutter test                       # Run all tests
flutter build web                  # Build for web
flutter build apk                  # Build for Android
flutter build ios                  # Build for iOS
```

## Architecture

### GetX Pattern
- **Controllers**: Business logic and state management (`lib/app/modules/*/controllers/`)
- **Views**: UI components (`lib/app/modules/*/views/`)
- **Bindings**: Dependency injection (`lib/app/modules/*/bindings/`)
- **Routes**: Centralized routing in `lib/app/routes/app_pages.dart`

Main routes:
- `/home` - Home page (initial route)
- `/game-start` - Game launcher with WebView
- `/user-profile` - User profile and wallet

### Key Modules
- `lib/app/modules/auth/` - Login/registration with crypto signing
- `lib/app/modules/home/` - Main landing page
- `lib/app/modules/gameStart/` - Game WebView integration
- `lib/app/modules/userProfile/` - User profile, wallet, deposit/withdraw
- `lib/app/modules/widgets/` - Shared components (gameMenu, language selector)

### Core Services
- `lib/app/utils/api_client.dart` - Centralized HTTP client with auth interceptor
- `lib/app/data/services/payment_services.dart` - Deposit/withdraw/bank list APIs
- `lib/app/data/services/userServices.dart` - User authentication and profile
- `lib/app/utils/signServices.dart` - Crypto signing for API requests

### Configuration
- `lib/config/app_config.dart` - API URLs, app metadata, feature flags
  - API base: `https://api.getwiner.win`
  - Game icons: `https://api.getwiner.win/`
- `lib/config/app_theme.dart` - Light/dark theme definitions
- `lib/config/app_colors.dart` - Color palette
- `lib/generated/locales.g.dart` - i18n translations (zh_CN, en_US, id_ID)

### Responsive Design
Uses breakpoint-based responsive system:
- Mobile: < 768px (1 column)
- Tablet: 768-1024px (2 columns)
- Desktop: 1024-1200px (3 columns)
- Large Desktop: > 1200px (4 columns)

Key utilities in `lib/app/utils/`:
- `ResponsiveUtils.isMobile/isTablet/isDesktop(context)`
- `ResponsiveUtils.responsiveValue()` - Return different values per breakpoint
- Use `LayoutBuilder` and `MediaQuery` for dynamic layouts

**Critical**: Web and mobile must share the same UI - no separate layouts per platform. Responsive design handles all screen sizes uniformly.

## Code Style

- Follow Dart conventions: 2-space indent, `lowerCamelCase` for variables/methods, `UpperCamelCase` for classes, `lower_snake_case` for files
- Use `dart format` for consistent formatting
- Localized strings via `generated/locales.g.dart` - no hardcoded UI text
- New assets must be declared in `pubspec.yaml`

## Payment Integration

Deposit/withdraw functionality implemented with:
- `/pay/deposit` - Returns payment URL for external browser
- `/pay/withdraw` - Submits withdrawal request with bank details
- `/pay/bankList` - Fetches available banks
- All requests require crypto signature via `signServices.dart`
- Uses `url_launcher` package for payment page redirects

## API Client Usage

All network requests go through `ApiClient()` singleton:
```dart
final response = await ApiClient().post('/endpoint', data: {...});
final response = await ApiClient().get('/endpoint', queryParameters: {...});
```

Auth token automatically injected via interceptor. Set `withAuth: false` to skip.

## Testing

Tests mirror source structure: `lib/app/modules/auth/...` → `test/app/modules/auth/...`
Use `flutter_test` for widgets, `test` for pure Dart logic.
