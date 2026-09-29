// Every API response uses this envelope:
//   success: { success: true,  message, data }
//   error:   { success: false, message, data }   (data is null unless extra context, e.g. { retryAfter })
const ok = (res, data = null, message = 'OK', status = 200) =>
  res.status(status).json({ success: true, message, data });

const fail = (res, status, message, data = null) =>
  res.status(status).json({ success: false, message, data });

const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { ok, fail, asyncHandler };
