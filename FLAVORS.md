# Kissan Fresh build flavors

Production behavior remains available through the `prod` flavor (and the
legacy `lib/main.dart` entry point). The isolated test application uses the
`dev` flavor and installs as `com.kissanfresh.app.debug`.

## Development Firebase configuration

The `com.kissanfresh.app.debug` app is registered in project
`kissan-fresh-development`, and its downloaded configuration is installed at
`android/app/src/dev/google-services.json` (gitignored).

Remaining local/service setup:

1. The dev flavor uses a fixed Roshan Gate location by default and makes no
   Google Maps, Places, or Geocoding calls. Set
   `--dart-define=USE_FIXED_DEBUG_LOCATION=false` and add a restricted
   `DEBUG_MAPS_API_KEY` only when explicitly testing real maps.
2. Configure App Check debug tokens and the required Authentication providers
   in the development Firebase project.
3. Pass a Razorpay test key to the dev build; never use a live key.

The local `config/dev.json` now contains the public test key ID and is
gitignored. Firebase test login details are stored in the dashboard repository's
gitignored `.debug-test-credentials.json` file.

## Run

Android Studio includes a shared **00 - Kissan Fresh Dev** Run/Debug
configuration and should show it first. Select it and press Run or Debug.
The project also declares `default-flavor: dev`, and `lib/main.dart` boots the
development environment, so Android Studio's automatically generated
`main.dart` configuration is safe and works without extra arguments.

Terminal equivalent:

```sh
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=config/dev.json
```

Emulator app verification is bypassed only in the dev flavor and only when the
native Android device is detected as an emulator. Disable that behavior with
`--dart-define=BYPASS_PHONE_VERIFICATION_ON_EMULATOR=false`. Firebase test phone
numbers and their fixed OTP codes must still be configured in the dev project.

Production release:

```sh
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
```

Never pass a live Razorpay key to the dev flavor. Cloud Functions also reject
wallet operations unless `KISSAN_ENV=debug`, the Firebase project is not the
production project, and source refunds use an `rzp_test_` credential.
