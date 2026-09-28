# fitness-backend

Express + MongoDB auth API for the Loosen (fitness-app) Flutter client.

## Setup

1. `npm install`
2. Copy `.env.example` to `.env` and fill in `MONGO_URI` (an Atlas connection
   string works) and `JWT_SECRET` (any long random string).
3. `npm run dev`

Without `SMTP_*` filled in, verification/reset codes are printed to this
console instead of emailed — fine for development.

## Endpoints (all under `/api/auth`)

| Method | Path              | Body                              |
|--------|-------------------|------------------------------------|
| POST   | /signup           | `{ email, password }`             |
| POST   | /verify-email     | `{ email, code }`                 |
| POST   | /login            | `{ email, password }`             |
| POST   | /forgot-password  | `{ email }`                       |
| POST   | /resend-code      | `{ email, purpose }` (verify/reset)|
| POST   | /reset-password   | `{ email, code, newPassword }`    |

Successful `verify-email` / `login` return `{ token, email }` — a JWT the
Flutter app stores and sends as `Authorization: Bearer <token>` on future
requests. Protect new routes with `middleware/auth.js`.

## Connecting from the Flutter app

- Android emulator: use `http://10.0.2.2:4000`
- Physical device: use your computer's LAN IP, e.g. `http://192.168.1.23:4000`
  (must be on the same Wi-Fi; check with `ipconfig`)
- iOS simulator: `http://localhost:4000` works
