const mongoose = require('mongoose');

// One row per rate-limit bucket (e.g. "login:email:<hash>"). MongoDB deletes the
// row by itself once expiresAt passes, so nothing needs cleaning up.
const rateLimitSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true },
  count: { type: Number, default: 0 },
  expiresAt: { type: Date, required: true, index: { expireAfterSeconds: 0 } },
});

module.exports = mongoose.model('RateLimit', rateLimitSchema);
