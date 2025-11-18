const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Emergency Forever Paws API Server Running',
    timestamp: new Date().toISOString(),
    environment: 'emergency-local'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Emergency Forever Paws API',
    version: '1.0.0-emergency',
    endpoints: {
      health: '/api/health',
      register: '/api/auth/register',
      login: '/api/auth/login'
    }
  });
});

// Registration endpoint
app.post('/api/auth/register', async (req, res) => {
  console.log('📋 Registration request received:', {
    body: req.body,
    headers: req.headers,
    timestamp: new Date().toISOString()
  });

  try {
    const { email, password, name } = req.body;

    // Validate required fields
    if (!email || !password || !name) {
      console.log('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: email, password, name'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      console.log('❌ Invalid email format:', email);
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    // Validate password strength
    if (password.length < 6) {
      console.log('❌ Weak password');
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
      });
    }

    // Simulate successful registration (since we can't connect to Supabase)
    console.log('✅ Registration would succeed with:', {
      email,
      name,
      userId: 'emergency-user-' + Date.now()
    });

    // Return success response
    res.json({
      success: true,
      message: 'Registration successful (emergency mode - no database)',
      data: {
        user: {
          id: 'emergency-user-' + Date.now(),
          email: email,
          name: name,
          created_at: new Date().toISOString()
        }
      }
    });

  } catch (error) {
    console.error('❌ Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed: ' + error.message
    });
  }
});

// Login endpoint
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  console.log('🔑 Login request received:', {
    email,
    timestamp: new Date().toISOString()
  });

  res.json({
    success: true,
    message: 'Login successful (emergency mode)',
    data: {
      user: {
        id: 'emergency-user-' + Date.now(),
        email: email,
        name: 'Emergency User'
      },
      token: 'emergency-jwt-token-' + Date.now()
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error: ' + err.message
  });
});

// 404 handler
app.use((req, res) => {
  console.log('❌ 404 Not found:', req.method, req.url);
  res.status(404).json({
    success: false,
    message: 'Endpoint not found: ' + req.method + ' ' + req.url
  });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log('🚀 Emergency Forever Paws API Server running on port', PORT);
  console.log('📋 Available endpoints:');
  console.log('  - GET  http://localhost:' + PORT + '/');
  console.log('  - GET  http://localhost:' + PORT + '/api/health');
  console.log('  - POST http://localhost:' + PORT + '/api/auth/register');
  console.log('  - POST http://localhost:' + PORT + '/api/auth/login');
});