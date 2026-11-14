# Kissan Fresh build flavors

Production behavior is available through the `prod` flavor and
`lib/main_prod.dart`. The isolated test application uses the
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
3. Configure `RAZORPAY_KEY`, `RAZORPAY_SECRET`, and
   `RAZORPAY_WEBHOOK_SECRET` in Firebase Secret Manager. Use Razorpay test
   credentials in development. The backend returns the public key ID when it
   creates an order.

## Run

Android Studio includes a shared **00 - Kissan Fresh Dev** Run/Debug
configuration and should show it first. Select it and press Run or Debug.
The project also declares `default-flavor: dev`, and `lib/main.dart` boots the
development environment, so Android Studio's automatically generated
`main.dart` configuration is safe and works without extra arguments.

Terminal equivalent:

```sh
flutter run --flavor dev -t lib/main_dev.dart
```

Emulator app verification is bypassed only in the dev flavor and only when the
native Android device is detected as an emulator. Disable that behavior with
`--dart-define=BYPASS_PHONE_VERIFICATION_ON_EMULATOR=false`. Firebase test phone
numbers and their fixed OTP codes must still be configured in the dev project.

Production release:

```sh
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
```

Development Cloud Functions require a Razorpay test key. They also reject
wallet operations unless `KISSAN_ENV=debug`, the Firebase project is not the
production project, and source refunds use an `rzp_test_` credential.

## Checkout rollout

- Verify App Check for the target Android and iOS builds and configure the
  Razorpay webhook for `order.paid` and `payment.captured`. The webhook signing
  secret must match `RAZORPAY_WEBHOOK_SECRET` and the gateway must capture the
  payment for fulfillment to proceed.
- In the existing Firestore rules, restrict `pending_orders`,
  `payment_requests`, `direct_order_requests`, and `failed_orders` to backend
  writes. Preserve the dashboard's authorized reads. The production rules
  are managed outside this mobile repository.
- Validate callback loss, app restart, duplicate events, stock/slot changes,
  and refund retry with Razorpay test credentials. Confirm the currently
  published client can still authenticate and check out against these callable
  endpoints before replacing the production functions.
