require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');

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
    res.status(500).json({ error: 'Database connection failed' });
  }
});

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

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
