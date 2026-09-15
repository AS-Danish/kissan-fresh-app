# Debug Firebase configuration

Create an Android app with package ID `com.kissanfresh.app.debug` in the
separate debug Firebase project, then place its downloaded configuration at:

`android/app/src/dev/google-services.json`

The file is intentionally not committed. The dev app fails closed if it ever
resolves to the production Firebase project (`kissanfresh-a72c1`).
