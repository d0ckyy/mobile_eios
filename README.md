# eios

Flutter client for EIOS MRSU.

## Local setup

Create a local `.env` file in the project root before running the app. The file
is ignored by Git and must contain:

```env
CLIENT_ID=your_client_id_here
CLIENT_SECRET=your_client_secret_here
```

You can copy the values from `.env.example` and replace them with the real
credentials for your environment.

## Run

```bash
flutter pub get
flutter run
```
