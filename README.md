# SamadhanAI Main Website

Flutter web frontend for the SamadhanAI citizen portal.

## Build for Netlify

Install Flutter 3.41.6, then run from this repository root:

```sh
flutter pub get
flutter build web --release --dart-define=API_BASE_URLS=https://backendsai.netlify.app/api/v1 --dart-define=REQUIRE_HTTPS=true
```

Deploy the contents of `build/web` to Netlify. The `web/_redirects` rule keeps
Flutter client-side routes working on refresh.

The API base URL is public client configuration. Never add backend credentials,
database credentials, or provider secrets to this repository or to Dart defines.
Firebase web configuration in `lib/firebase_options.dart` is client-side
configuration; secure Firebase with Authentication authorized domains, API-key
restrictions where supported, and server-side authorization.

After the Netlify site has a URL, add that exact HTTPS origin to the backend's
`CORS_ALLOWED_ORIGINS` and add its hostname to Firebase Authentication's
authorized domains. Authentication and API connectivity must be verified on
the deployed site before production use.
