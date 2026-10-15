const router = require('express').Router();
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendCode } = require('../utils/mailer');
const apple = require('../utils/apple');
const { OAuth2Client } = require('google-auth-library');
const { ok, fail, asyncHandler } = require('../utils/response');
const requireAuth = require('../middleware/auth');
const rateLimit = require('../middleware/rateLimit');

// Limits per client address and per email, so one attacker can neither hammer one
// account from many addresses nor many accounts from one address.
const MIN = 60;
const HOUR = 60 * MIN;
const limit = (name, ipMax, emailMax, windowSec) => [
  rateLimit({ name, by: 'ip', max: ipMax, windowSec }),
  rateLimit({ name, by: 'email', max: emailMax, windowSec }),
];
const limits = {
  signup: limit('signup', 10, 5, HOUR),
  verifyEmail: limit('verify', 30, 5, 15 * MIN),
  login: limit('login', 30, 10, 15 * MIN),
  google: rateLimit({ name: 'google', by: 'ip', max: 30, windowSec: 15 * MIN }),
  apple: rateLimit({ name: 'apple', by: 'ip', max: 30, windowSec: 15 * MIN }),
  forgot: limit('forgot', 10, 3, HOUR),
  resend: limit('resend', 20, 5, HOUR),
  // verify-reset-code and reset-password share one budget per email.
  reset: limit('reset', 30, 8, 15 * MIN),
  changePassword: rateLimit({ name: 'chgpw', by: 'user', max: 10, windowSec: 15 * MIN }),
};

// The token carries the user's tokenVersion, so changing or resetting the password
// (which raises it) signs the account out everywhere else.
const sign = (user) =>
  jwt.sign({ id: user._id, v: user.tokenVersion || 0 }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES || '30d',
  });

const googleClient = new OAuth2Client();
// Comma-separated OAuth client IDs the app's ID tokens may be issued for
// (the Web client ID the Flutter app passes as serverClientId).
const googleAudiences = () =>
  String(process.env.GOOGLE_CLIENT_IDS || '').split(',').map((id) => id.trim()).filter(Boolean);

const genCode = () => String(crypto.randomInt(100000, 1000000));
const RESET_TTL_MS = 15 * 60 * 1000;
const VERIFY_TTL_MS = 15 * 60 * 1000;
// Wrong guesses allowed against one code before it is thrown away (the user can ask for a new one).
const MAX_CODE_ATTEMPTS = 6;
const RESEND_COOLDOWN_MS = 30 * 1000;

const safeEqual = (a, b) => {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
};

// Counts a wrong guess against the user's current 'verify' or 'reset' code, and
// drops the code once it has been guessed at too many times.
async function recordMiss(user, kind) {
  const attemptsField = kind === 'verify' ? 'verifyAttempts' : 'resetAttempts';
  const updated = await User.findOneAndUpdate({ _id: user._id }, { $inc: { [attemptsField]: 1 } }, { new: true });
  if (updated && updated[attemptsField] >= MAX_CODE_ATTEMPTS) {
    await User.updateOne(
      { _id: user._id },
      { $set: kind === 'verify' ? { verifyCode: null, verifyCodeExpires: null } : { resetCode: null, resetCodeExpires: null } },
    );
  }
}

// The user whose live (unexpired, not over-guessed) reset code equals `code`, or null.
async function findByResetCode(email, code) {
  const user = await User.findOne({ email, resetCode: { $ne: null }, resetCodeExpires: { $gt: new Date() } });
  if (!user || (user.resetAttempts || 0) >= MAX_CODE_ATTEMPTS) return null;
  if (!safeEqual(user.resetCode, code)) {
    await recordMiss(user, 'reset');
    return null;
  }
  return user;
}

// POST /api/auth/signup { email, password }
router.post('/signup', limits.signup, async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { password } = req.body;
    if (!email || typeof password !== 'string' || !password) return fail(res, 400, 'Email and password are required');
    if (password.length < 8) return fail(res, 400, 'Password must be at least 8 characters');

    const existing = await User.findOne({ email });
    if (existing?.isVerified) return fail(res, 409, 'Email already in use');

    const passwordHash = await bcrypt.hash(password, 12);
    const verifyCode = genCode();
    const verifyFields = { verifyCode, verifyCodeExpires: new Date(Date.now() + VERIFY_TTL_MS), verifyAttempts: 0 };

    if (existing) {
      Object.assign(existing, { passwordHash, ...verifyFields });
      await existing.save();
    } else {
      await User.create({ email, passwordHash, ...verifyFields });
    }

    try {
      await sendCode(email, verifyCode, 'verify');
    } catch (mailErr) {
      console.error('[auth/signup] email failed:', mailErr.message);
      return fail(res, 500, "Couldn't send the email. Please try again.");
    }
    ok(res, null, 'Verification code sent');
  } catch (err) {
    console.error('[auth/signup error]:', err);
    fail(res, 500, 'Signup failed');
  }
});

// POST /api/auth/verify-email { email, code }
router.post('/verify-email', limits.verifyEmail, async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const code = String(req.body.code ?? '');
    const user = await User.findOne({ email });
    const live = user && user.verifyCode && user.verifyCodeExpires > new Date()
      && (user.verifyAttempts || 0) < MAX_CODE_ATTEMPTS;
    if (!live || !safeEqual(user.verifyCode, code)) {
      if (live) await recordMiss(user, 'verify');
      return fail(res, 400, "That code doesn't match");
    }
    user.isVerified = true;
    user.verifyCode = undefined;
    user.verifyCodeExpires = undefined;
    user.verifyAttempts = 0;
    await user.save();
    ok(res, { token: sign(user), email: user.email }, 'Signed in');
  } catch (err) {
    console.error('[auth/verify-email error]:', err);
    fail(res, 500, 'Verification failed');
  }
});

// POST /api/auth/login { email, password }
router.post('/login', limits.login, async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = typeof req.body.password === 'string' ? req.body.password : '';
    const user = await User.findOne({ email });
    if (user && !user.passwordHash) {
      return fail(res, 401, 'This account uses Google sign-in. Tap "Continue with Google".');
    }
    if (!user || !(await bcrypt.compare(password || '', user.passwordHash))) {
      return fail(res, 401, 'Invalid email or password');
    }
    if (!user.isVerified) return fail(res, 403, 'Please verify your email first');
    ok(res, { token: sign(user), email: user.email }, 'Signed in');
  } catch (err) {
    console.error('[auth/login error]:', err);
    fail(res, 500, 'Login failed');
  }
});

// POST /api/auth/google { idToken, intent? }
// Verifies a Google ID token, then signs in the matching account — creating a
// verified one on first use, or linking Google to an existing account that has
// the same (Google-verified) email. With intent "signup" (the sign-up screen) an
// existing account is refused with 409 instead of being signed in.
router.post('/google', limits.google, asyncHandler(async (req, res) => {
  const { idToken } = req.body;
  if (typeof idToken !== 'string' || !idToken) return fail(res, 400, 'Google ID token is required');
  const audience = googleAudiences();
  if (!audience.length) return fail(res, 500, 'Google sign-in is not configured');

  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({ idToken, audience });
    payload = ticket.getPayload();
  } catch (err) {
    return fail(res, 401, 'Google sign-in failed. Please try again.');
  }
  if (!payload?.email || !payload.email_verified) {
    return fail(res, 401, 'Your Google email is not verified');
  }

  const email = payload.email.trim().toLowerCase();
  let user = await User.findOne({ $or: [{ googleId: payload.sub }, { email }] });
  if (user && req.body.intent === 'signup') {
    return fail(res, 409, 'An account with this Google account already exists. Please log in instead.');
  }
  if (!user) {
    user = await User.create({
      email,
      googleId: payload.sub,
      isVerified: true,
      name: payload.name || '',
    });
  } else {
    if (user.googleId && user.googleId !== payload.sub) {
      return fail(res, 409, 'This email is linked to a different Google account');
    }
    // An email/password signup that was never verified could have been made by someone
    // else using this address, so Google taking over the account drops that password.
    if (!user.isVerified) user.passwordHash = null;
    user.googleId = payload.sub;
    user.isVerified = true;
    user.verifyCode = undefined;
    user.verifyCodeExpires = undefined;
    await user.save();
  }
  ok(res, { token: sign(user), email: user.email }, 'Signed in');
}));

// POST /api/auth/apple { identityToken, nonce, name? }
// Verifies an Apple identity token (and that it was minted for this nonce), then signs in
// the matching account: found by Apple id first, otherwise by the token's verified email
// (Apple's private-relay addresses included), otherwise created. Apple only shares the
// person's name the first time, so the app passes it along and it is used for new accounts.
router.post('/apple', limits.apple, asyncHandler(async (req, res) => {
  const { identityToken, nonce, name } = req.body;
  if (typeof identityToken !== 'string' || !identityToken || typeof nonce !== 'string' || !nonce) {
    return fail(res, 400, 'Apple identity token is required');
  }

  let payload;
  try {
    payload = await apple.verifyIdentityToken(identityToken, nonce);
  } catch (err) {
    return fail(res, 401, 'Apple sign-in failed. Please try again.');
  }

  const email = typeof payload.email === 'string' ? payload.email.trim().toLowerCase() : '';
  const emailVerified = payload.email_verified === true || payload.email_verified === 'true';

  let user = await User.findOne({ appleId: payload.sub });
  if (!user) {
    if (!email || !emailVerified) {
      return fail(res, 401, 'Apple did not share a verified email for this account');
    }
    user = await User.findOne({ email });
    if (!user) {
      user = await User.create({
        email,
        appleId: payload.sub,
        isVerified: true,
        name: typeof name === 'string' ? name.trim().slice(0, 80) : '',
      });
    } else {
      if (user.appleId && user.appleId !== payload.sub) {
        return fail(res, 409, 'This email is linked to a different Apple account');
      }
      // Same reasoning as Google: an unverified password signup may belong to someone else.
      if (!user.isVerified) user.passwordHash = null;
      user.appleId = payload.sub;
      user.isVerified = true;
      user.verifyCode = undefined;
      user.verifyCodeExpires = undefined;
      await user.save();
    }
  }

  ok(res, { token: sign(user), email: user.email }, 'Signed in');
}));

// POST /api/auth/forgot-password { email }
router.post('/forgot-password', limits.forgot, async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const user = await User.findOne({ email });
    if (user) {
      user.resetCode = genCode();
      user.resetCodeExpires = new Date(Date.now() + RESET_TTL_MS);
      user.resetAttempts = 0;
      await user.save();
      // A failed send is only logged: the reply must look the same either way.
      await sendCode(email, user.resetCode, 'reset').catch((mailErr) =>
        console.error('[auth/forgot-password] email failed:', mailErr.message));
    }
    // Same response whether or not the account exists, so the endpoint can't
    // be used to check which emails are registered.
    ok(res, null, 'If that email exists, a code was sent');
  } catch (err) {
    console.error('[auth/forgot-password error]:', err);
    fail(res, 500, 'Request failed');
  }
});

// POST /api/auth/resend-code { email, purpose: 'verify' | 'reset' }
router.post('/resend-code', limits.resend, async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const purpose = req.body.purpose === 'reset' ? 'reset' : 'verify';
    const user = await User.findOne({ email });
    // A verified account never needs a verification code, so none is sent to it.
    if (user && !(purpose === 'verify' && user.isVerified)) {
      const sinceLast = user.lastCodeSentAt ? Date.now() - user.lastCodeSentAt.getTime() : Infinity;
      if (sinceLast < RESEND_COOLDOWN_MS) {
        const waitSec = Math.ceil((RESEND_COOLDOWN_MS - sinceLast) / 1000);
        return fail(res, 429, `Please wait ${waitSec}s before resending`, { retryAfter: waitSec });
      }
      const code = genCode();
      if (purpose === 'verify') {
        user.verifyCode = code;
        user.verifyCodeExpires = new Date(Date.now() + VERIFY_TTL_MS);
        user.verifyAttempts = 0;
      } else {
        user.resetCode = code;
        user.resetCodeExpires = new Date(Date.now() + RESET_TTL_MS);
        user.resetAttempts = 0;
      }
      user.lastCodeSentAt = new Date();
      await user.save();
      await sendCode(email, code, purpose);
    }
    ok(res, null, 'Code resent');
  } catch (err) {
    console.error('[auth/resend-code error]:', err);
    fail(res, 500, 'Could not resend code');
  }
});

// POST /api/auth/reset-password { email, code, newPassword }
router.post('/reset-password', limits.reset, async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const code = String(req.body.code ?? '');
    const { newPassword } = req.body;
    if (typeof newPassword !== 'string' || newPassword.length < 8) {
      return fail(res, 400, 'Password must be at least 8 characters');
    }
    if (!code) return fail(res, 400, 'Invalid or expired code');
    const user = await findByResetCode(email, code);
    if (!user) return fail(res, 400, 'Invalid or expired code');

    user.passwordHash = await bcrypt.hash(newPassword, 12);
    user.resetCode = undefined;
    user.resetCodeExpires = undefined;
    user.resetAttempts = 0;
    user.tokenVersion = (user.tokenVersion || 0) + 1;
    await user.save();
    ok(res, null, 'Password updated');
  } catch (err) {
    console.error('[auth/reset-password error]:', err);
    fail(res, 500, 'Reset failed');
  }
});

// POST /api/auth/verify-reset-code { email, code }
// Checks a reset code without using it up, so the app can show the new-password
// step only after the code is right. reset-password still checks it again.
router.post('/verify-reset-code', limits.reset, asyncHandler(async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const code = String(req.body.code ?? '');
  if (!code) return fail(res, 400, 'Invalid or expired code');
  const user = await findByResetCode(email, code);
  if (!user) return fail(res, 400, 'Invalid or expired code');
  ok(res, null, 'Code verified');
}));

// POST /api/auth/change-password { currentPassword, newPassword }  (signed in)
router.post('/change-password', requireAuth, limits.changePassword, asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (typeof newPassword !== 'string' || newPassword.length < 8) {
    return fail(res, 400, 'Password must be at least 8 characters');
  }
  const user = await User.findById(req.userId);
  if (!user) return fail(res, 404, 'User not found');
  if (!user.passwordHash) {
    return fail(res, 400, 'This account has no password yet. Use "Forgot current password?" to set one.');
  }
  if (!(await bcrypt.compare(typeof currentPassword === 'string' ? currentPassword : '', user.passwordHash))) {
    return fail(res, 400, 'Current password is incorrect');
  }
  user.passwordHash = await bcrypt.hash(newPassword, 12);
  user.tokenVersion = (user.tokenVersion || 0) + 1;
  await user.save();
  // Every other session is now signed out; this one continues on the fresh token.
  ok(res, { token: sign(user) }, 'Password updated');
}));

module.exports = router;
