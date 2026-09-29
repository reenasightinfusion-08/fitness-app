const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendCode } = require('../utils/mailer');
const { ok, fail } = require('../utils/response');

const sign = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES || '7d' });

const genCode = () => String(Math.floor(100000 + Math.random() * 900000));
const RESET_TTL_MS = 15 * 60 * 1000;
const RESEND_COOLDOWN_MS = 30 * 1000;

// POST /api/auth/signup { email, password }
router.post('/signup', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { password } = req.body;
    if (!email || !password) return fail(res, 400, 'Email and password are required');
    if (password.length < 8) return fail(res, 400, 'Password must be at least 8 characters');

    const existing = await User.findOne({ email });
    if (existing?.isVerified) return fail(res, 409, 'Email already in use');

    const passwordHash = await bcrypt.hash(password, 12);
    const verifyCode = genCode();

    if (existing) {
      existing.passwordHash = passwordHash;
      existing.verifyCode = verifyCode;
      await existing.save();
    } else {
      await User.create({ email, passwordHash, verifyCode });
    }

    await sendCode(email, verifyCode, 'verify');
    ok(res, null, 'Verification code sent');
  } catch (err) {
    console.error('[auth/signup error]:', err);
    fail(res, 500, 'Signup failed: ' + (err.message || err));
  }
});

// POST /api/auth/verify-email { email, code }
router.post('/verify-email', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { code } = req.body;
    const user = await User.findOne({ email });
    if (!user || !user.verifyCode || user.verifyCode !== code) {
      return fail(res, 400, "That code doesn't match");
    }
    user.isVerified = true;
    user.verifyCode = undefined;
    await user.save();
    ok(res, { token: sign(user._id), email: user.email }, 'Signed in');
  } catch (err) {
    console.error('[auth/verify-email error]:', err);
    fail(res, 500, 'Verification failed');
  }
});

// POST /api/auth/login { email, password }
router.post('/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password || '', user.passwordHash))) {
      return fail(res, 401, 'Invalid email or password');
    }
    if (!user.isVerified) return fail(res, 403, 'Please verify your email first');
    ok(res, { token: sign(user._id), email: user.email }, 'Signed in');
  } catch (err) {
    console.error('[auth/login error]:', err);
    fail(res, 500, 'Login failed');
  }
});

// POST /api/auth/forgot-password { email }
router.post('/forgot-password', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const user = await User.findOne({ email });
    if (user) {
      user.resetCode = genCode();
      user.resetCodeExpires = new Date(Date.now() + RESET_TTL_MS);
      await user.save();
      await sendCode(email, user.resetCode, 'reset');
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
router.post('/resend-code', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const purpose = req.body.purpose === 'reset' ? 'reset' : 'verify';
    const user = await User.findOne({ email });
    if (user) {
      const sinceLast = user.lastCodeSentAt ? Date.now() - user.lastCodeSentAt.getTime() : Infinity;
      if (sinceLast < RESEND_COOLDOWN_MS) {
        const waitSec = Math.ceil((RESEND_COOLDOWN_MS - sinceLast) / 1000);
        return fail(res, 429, `Please wait ${waitSec}s before resending`, { retryAfter: waitSec });
      }
      const code = genCode();
      if (purpose === 'verify') {
        user.verifyCode = code;
      } else {
        user.resetCode = code;
        user.resetCodeExpires = new Date(Date.now() + RESET_TTL_MS);
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
router.post('/reset-password', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { code, newPassword } = req.body;
    if (!newPassword || newPassword.length < 8) {
      return fail(res, 400, 'Password must be at least 8 characters');
    }
    const user = await User.findOne({
      email,
      resetCode: code,
      resetCodeExpires: { $gt: new Date() },
    });
    if (!user) return fail(res, 400, 'Invalid or expired code');

    user.passwordHash = await bcrypt.hash(newPassword, 12);
    user.resetCode = undefined;
    user.resetCodeExpires = undefined;
    await user.save();
    ok(res, null, 'Password updated');
  } catch (err) {
    console.error('[auth/reset-password error]:', err);
    fail(res, 500, 'Reset failed');
  }
});

module.exports = router;
