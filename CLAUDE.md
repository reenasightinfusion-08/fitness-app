# Project rules

## API response format (mandatory, backend + Flutter)
Every endpoint — including `/health` and error/404 handlers — returns the same envelope:

- Success: `{ "success": true,  "message": "...", "data": <object | array | null> }`
- Error:   `{ "success": false, "message": "...", "data": null }` (extra context such as `retryAfter` goes inside `data`)

Backend: never call `res.json(...)` directly. Use `ok(res, data, message, status?)` and `fail(res, status, message, data?)` from `backend/utils/response.js`, and wrap async handlers in `asyncHandler`. Unhandled errors are caught by the error middleware in `server.js`.

Flutter: all HTTP goes through `AuthService._decode`, which reads `success` / `message` / `data`. Do not read `error`, `token` or other keys from the top level of a response body. New endpoints must follow this format, and a list goes in `data` as an array.

## API docs (Swagger)
The OpenAPI spec lives in `backend/docs/openapi.js` (UI at `/api/docs`, JSON at `/api/docs.json`). Whenever an endpoint or a User/Stretch model field is added or changed, update this file in the same change.
