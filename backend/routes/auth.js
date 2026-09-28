const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendCode } = require('../utils/mailer');

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
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });
    if (password.length < 8) return res.status(400).json({ error: 'Password must be at least 8 characters' });

    const existing = await User.findOne({ email });
    if (existing?.isVerified) return res.status(409).json({ error: 'Email already in use' });

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
    res.json({ message: 'Verification code sent' });
  } catch (err) {
    console.error('[auth/signup error]:', err);
    res.status(500).json({ error: 'Signup failed: ' + (err.message || err) });
  }
});

// POST /api/auth/verify-email { email, code }
router.post('/verify-email', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { code } = req.body;
    const user = await User.findOne({ email });
    if (!user || !user.verifyCode || user.verifyCode !== code) {
      return res.status(400).json({ error: "That code doesn't match" });
    }
    user.isVerified = true;
    user.verifyCode = undefined;
    await user.save();
    res.json({ token: sign(user._id), email: user.email });
  } catch (err) {
    console.error('[auth/verify-email error]:', err);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// POST /api/auth/login { email, password }
router.post('/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password || '', user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    if (!user.isVerified) return res.status(403).json({ error: 'Please verify your email first' });
    res.json({ token: sign(user._id), email: user.email });
  } catch (err) {
    console.error('[auth/login error]:', err);
    res.status(500).json({ error: 'Login failed' });
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
    res.json({ message: 'If that email exists, a code was sent' });
  } catch (err) {
    console.error('[auth/forgot-password error]:', err);
    res.status(500).json({ error: 'Request failed' });
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
        return res.status(429).json({ error: `Please wait ${waitSec}s before resending`, retryAfter: waitSec });
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
    res.json({ message: 'Code resent' });
  } catch (err) {
    console.error('[auth/resend-code error]:', err);
    res.status(500).json({ error: 'Could not resend code' });
  }
});

// POST /api/auth/reset-password { email, code, newPassword }
router.post('/reset-password', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { code, newPassword } = req.body;
    if (!newPassword || newPassword.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    const user = await User.findOne({
      email,
      resetCode: code,
      resetCodeExpires: { $gt: new Date() },
    });
    if (!user) return res.status(400).json({ error: 'Invalid or expired code' });

    user.passwordHash = await bcrypt.hash(newPassword, 12);
    user.resetCode = undefined;
    user.resetCodeExpires = undefined;
    await user.save();
    res.json({ message: 'Password updated' });
  } catch (err) {
    console.error('[auth/reset-password error]:', err);
    res.status(500).json({ error: 'Reset failed' });
  }
});

module.exports = router;
