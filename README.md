# OURS — Your Private Universe

OURS is a private two-person space built with Flutter and Supabase.

## Current features

- Username-based registration and sign-in through Supabase Edge Functions.
- Create a private space and invite one other member with an 8-character code.
- Join an existing space with an invitation code.
- Realtime text, image, and document sharing between members of the same space.
- Images and files are stored in the private `duo-private` bucket and opened through short-lived signed URLs.
- Supported shared files: PDF, TXT, CSV, Word, Excel, PowerPoint, and ZIP (up to 20 MB).

## Requirements

- Flutter stable (Dart SDK >= 3.3.0 < 4.0.0)
- A Supabase project with the OURS schema, policies, RPC functions, and Edge Functions deployed.

## Configure Supabase

The Flutter app uses the Supabase project URL and a publishable client key in `lib/main.dart`.
A publishable key is intended for client applications; never put a Supabase secret/service-role key in the Flutter app.

The following Edge Functions are expected:

- `duo-username-register`
- `duo-username-login`

The app also expects the database RPC functions `create_duo_space`, `create_duo_invite`, and `redeem_duo_invite`.

## Run locally

```bash
flutter pub get
flutter run
```

## Build Android APK

```bash
flutter build apk --release
```

The Android app is branded as OURS, with a custom navy, gold, and lavender launcher mark. The GitHub Actions workflow builds an APK and uploads it as an artifact. Pull requests targeting `main` also run Flutter analysis and an Android release build.

## Security notes

- Keep Supabase secret/service-role keys only in trusted server-side environments.
- Keep Row Level Security enabled on private tables.
- Invitation codes should be shared only with the intended second member.
- Before a production release, review Edge Function rate limiting, authentication abuse protection, and storage policies.
