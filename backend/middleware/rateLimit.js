const crypto = require('crypto');
const RateLimit = require('../models/RateLimit');
const { fail } = require('../utils/response');

// Counts requests per bucket in MongoDB, so the limit holds across Vercel's many
// short-lived server instances (an in-memory counter would not).
//
//   rateLimit({ name: 'login', by: 'email', max: 10, windowSec: 900 })
//
// `by` picks what is counted: 'ip', 'email' (from the request body) or 'user'
// (needs requireAuth first). Over the limit -> 429 with data.retryAfter (seconds).
// If the counter itself fails, the request is let through (and logged), so a
// limiter problem never locks everyone out.

const digest = (value) => crypto.createHash('sha256').update(String(value)).digest('hex').slice(0, 32);

// On Vercel the client address comes from a header Vercel sets itself, which callers cannot fake.
const clientIp = (req) => (process.env.VERCEL && req.headers['x-vercel-forwarded-for']) || req.ip || 'unknown';

const subjectOf = {
  ip: (req) => clientIp(req),
  email: (req) => String((req.body && req.body.email) ?? '').trim().toLowerCase(),
  user: (req) => (req.userId ? String(req.userId) : ''),
};

const wait = (seconds) => (seconds < 60 ? `${seconds} seconds` : `${Math.ceil(seconds / 60)} minutes`);

// Adds one hit to the bucket and returns it. A bucket whose window has passed
// starts over at 1, even if MongoDB has not yet removed the old row.
async function hit(key, windowMs) {
  const now = new Date();
  const next = new Date(now.getTime() + windowMs);
  const pipeline = [
    { $set: { _fresh: { $lte: [{ $ifNull: ['$expiresAt', new Date(0)] }, now] } } },
    {
      $set: {
        count: { $cond: ['$_fresh', 1, { $add: [{ $ifNull: ['$count', 0] }, 1] }] },
        expiresAt: { $cond: ['$_fresh', next, '$expiresAt'] },
      },
    },
    { $unset: '_fresh' },
  ];
  for (let attempt = 0; ; attempt++) {
    try {
      const res = await RateLimit.collection.findOneAndUpdate({ key }, pipeline, { upsert: true, returnDocument: 'after' });
      return res && res.value !== undefined ? res.value : res;
    } catch (err) {
      // Two first requests raced to create the same bucket; the second just retries.
      if (err.code !== 11000 || attempt >= 2) throw err;
    }
  }
}

module.exports = function rateLimit({ name, by, max, windowSec }) {
  const subjectFor = subjectOf[by];
  return async (req, res, next) => {
    try {
      const subject = subjectFor(req);
      if (subject) {
        const bucket = await hit(`${name}:${by}:${digest(subject)}`, windowSec * 1000);
        if (bucket.count > max) {
          const retryAfter = Math.max(1, Math.ceil((new Date(bucket.expiresAt).getTime() - Date.now()) / 1000));
          res.set('Retry-After', String(retryAfter));
          return fail(res, 429, `Too many attempts. Try again in ${wait(retryAfter)}.`, { retryAfter });
        }
      }
    } catch (err) {
      console.error('[rateLimit] counter failed, letting the request through:', err.message);
    }
    next();
  };
};
