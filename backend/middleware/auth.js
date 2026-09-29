const jwt = require('jsonwebtoken');
const { fail } = require('../utils/response');

module.exports = function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return fail(res, 401, 'No token provided');

  try {
    req.userId = jwt.verify(token, process.env.JWT_SECRET).id;
    next();
  } catch {
    fail(res, 401, 'Invalid or expired token');
  }
};
