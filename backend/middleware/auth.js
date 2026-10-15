const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { fail } = require('../utils/response');

// Accepts a token only while its account exists and the token's version still
// matches the user's tokenVersion (raised on password change/reset), so a stolen
// token stops working once the password changes or the account is deleted.
module.exports = async function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return fail(res, 401, 'No token provided');

  let payload;
  try {
    payload = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return fail(res, 401, 'Invalid or expired token');
  }

  try {
    const user = await User.findById(payload.id).select('tokenVersion').lean();
    if (!user || (user.tokenVersion || 0) !== (payload.v || 0)) {
      return fail(res, 401, 'Invalid or expired token');
    }
    req.userId = payload.id;
    next();
  } catch (err) {
    next(err);
  }
};
