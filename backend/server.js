require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const stretchRoutes = require('./routes/stretches');
const routineRoutes = require('./routes/routines');
const customRoutineRoutes = require('./routes/customRoutines');
const activeRoutineRoutes = require('./routes/activeRoutines');
const { ok, fail } = require('./utils/response');
const openapi = require('./docs/openapi');

const app = express();
app.use(cors());
app.use(express.json());

// Reusable MongoDB connection for both Vercel serverless & local dev
let isConnected = false;
async function connectDB() {
  if (isConnected || mongoose.connection.readyState >= 1) return;
  const db = await mongoose.connect(process.env.MONGO_URI);
  isConnected = db.connections[0].readyState;
  console.log('MongoDB connected');
}

// Middleware to ensure DB connection is ready for each request
app.use(async (_req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    console.error('Database connection error:', err.message);
    fail(res, 500, 'Database connection failed');
  }
});

app.get('/health', (_req, res) => ok(res, { ok: true }, 'Healthy'));
// API docs — UI loaded from CDN because swagger-ui's bundled assets 404 on Vercel serverless.
app.get('/api/docs.json', (_req, res) => res.json(openapi));
app.get('/api/docs', (_req, res) => {
  res.type('html').send(`<!doctype html>
<html><head><meta charset="utf-8"><title>Fitness API Docs</title>
<link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css"></head>
<body><div id="ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
<script>SwaggerUIBundle({ url: '/api/docs.json', dom_id: '#ui', persistAuthorization: true });</script>
</body></html>`);
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/stretches', stretchRoutes);
app.use('/api/routines', routineRoutes);
app.use('/api/custom-routines', customRoutineRoutes);
app.use('/api/active-routines', activeRoutineRoutes);

app.use((_req, res) => fail(res, 404, 'Route not found'));

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('[unhandled error]:', err);
  fail(res, err.name === 'ValidationError' || err.name === 'CastError' ? 400 : 500,
    err.name === 'ValidationError' || err.name === 'CastError' ? err.message : 'Internal server error');
});

const port = process.env.PORT || 4000;

// When running locally, start the HTTP server
if (!process.env.VERCEL) {
  connectDB()
    .then(() => {
      app.listen(port, '0.0.0.0', () => {
        console.log(`Backend server running:`);
        console.log(`  - Local:   http://localhost:${port}`);
        console.log(`  - Network: http://0.0.0.0:${port}`);
      });
    })
    .catch((err) => {
      console.error('MongoDB connection failed:', err.message);
    });
}

module.exports = app;
