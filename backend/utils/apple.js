const crypto = require('crypto');
const jwt = require('jsonwebtoken');

// Sign in with Apple: verifies the identity token the iOS app gets from Apple.

const APPLE_ISSUER = 'https://appleid.apple.com';
const JWKS_URL = `${APPLE_ISSUER}/auth/keys`;
const KEYS_TTL_MS = 60 * 60 * 1000;
const FETCH_TIMEOUT_MS = 8000;

// For the native flow the token's audience is the app's bundle id.
const clientId = () => (process.env.APPLE_CLIENT_ID || 'com.sightinfusion.fitness').trim();

const sha256Hex = (value) => crypto.createHash('sha256').update(String(value)).digest('hex');

let keyCache = { keys: null, fetchedAt: 0 };

async function fetchJson(url, options = {}) {
  const res = await fetch(url, { ...options, signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
  if (!res.ok) throw new Error(`Apple responded ${res.status}`);
  return res.json();
}

async function getKeys(force = false) {
  const fresh = keyCache.keys && Date.now() - keyCache.fetchedAt < KEYS_TTL_MS;
  if (fresh && !force) return keyCache.keys;
  const { keys } = await fetchJson(JWKS_URL);
  keyCache = { keys, fetchedAt: Date.now() };
  return keys;
}

async function findKey(kid) {
  let key = (await getKeys()).find((k) => k.kid === kid);
  // Apple rotates keys; one forced refresh covers a token signed by a brand-new key.
  if (!key) key = (await getKeys(true)).find((k) => k.kid === kid);
  return key;
}

/**
 * Verifies an Apple identity token and returns its claims.
 * `rawNonce` is the unhashed nonce the app generated; the token must carry its SHA-256.
 * Throws when anything about the token is wrong.
 */
async function verifyIdentityToken(identityToken, rawNonce) {
  const decoded = jwt.decode(identityToken, { complete: true });
  if (!decoded || decoded.header.alg !== 'RS256' || !decoded.header.kid) {
    throw new Error('Malformed Apple identity token');
  }
  const jwk = await findKey(decoded.header.kid);
  if (!jwk) throw new Error('Unknown Apple signing key');

  const payload = jwt.verify(identityToken, crypto.createPublicKey({ key: jwk, format: 'jwk' }), {
    algorithms: ['RS256'],
    issuer: APPLE_ISSUER,
    audience: clientId(),
  });

  if (typeof rawNonce !== 'string' || !rawNonce || payload.nonce !== sha256Hex(rawNonce)) {
    throw new Error('Apple nonce mismatch');
  }
  if (!payload.sub) throw new Error('Apple token has no subject');
  return payload;
}

// Test hook: lets tests supply signing keys instead of fetching Apple's.
function _setKeysForTest(keys) {
  keyCache = { keys, fetchedAt: Date.now() };
}

module.exports = { verifyIdentityToken, sha256Hex, _setKeysForTest };
