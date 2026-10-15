const crypto = require('crypto');
const { fail } = require('../utils/response');

// Guards content-management routes (create/delete stretches and routines).
// Callers send the secret from ADMIN_API_KEY in an `x-admin-key` header.
// Fails closed: if ADMIN_API_KEY is unset or too short, every call is refused.
const MIN_KEY_LENGTH = 16;
const digest = (value) => crypto.createHash('sha256').update(String(value)).digest();

module.exports = function requireAdminKey(req, res, next) {
  const expected = process.env.ADMIN_API_KEY || '';
  if (expected.length < MIN_KEY_LENGTH) return fail(res, 403, 'Admin access is not enabled');

  const provided = req.headers['x-admin-key'];
  if (typeof provided !== 'string' || !crypto.timingSafeEqual(digest(provided), digest(expected))) {
    return fail(res, 401, 'Invalid admin key');
  }
  next();
};
