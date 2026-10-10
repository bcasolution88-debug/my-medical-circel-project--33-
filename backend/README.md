# Health Circle Backend (REST API)

Zero-dependency Python 3 + SQLite server replacing the prototype's `localStorage` stores.

```bash
python3 backend/server.py            # listens on 0.0.0.0:5061, seeds health_circle.db on first run
PORT=8080 HC_SECRET=prod-secret python3 backend/server.py
```

Point the Flutter app at it:
- Web preview: automatically uses same host, port 5061 (or `5060-` → `5061-` sandbox host swap).
- Android APK: `flutter build apk --dart-define=API_BASE=https://api.example.com`
  or change it at runtime in **我的 → 个人设置 → API 地址**.

Seed accounts (password `Pass@2026`): `me@healthcircle.app`, `allan@example.com`, `shier@example.com` …
`POST /api/auth/send-code` returns `devCode` so registration can be tested without SMTP.

See the docstring at the top of `server.py` for the full endpoint list.
