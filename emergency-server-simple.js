const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 3001;

// Simple CORS headers
function setCORSHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json');
}

// Parse JSON body
function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => body += chunk.toString());
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        reject(new Error('Invalid JSON'));
      }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const method = req.method;

  console.log(`📡 ${method} ${path} - ${new Date().toISOString()}`);

  // Handle CORS preflight
  if (method === 'OPTIONS') {
    setCORSHeaders(res);
    res.statusCode = 200;
    res.end();
    return;
  }

  try {
    if (path === '/' && method === 'GET') {
      setCORSHeaders(res);
      res.statusCode = 200;
      res.end(JSON.stringify({
        success: true,
        message: 'Emergency Forever Paws API (No Dependencies)',
        version: '1.0.0-emergency',
        endpoints: {
          health: '/api/health',
          register: '/api/auth/register',
          login: '/api/auth/login'
        }
      }));
    }
    else if (path === '/api/health' && method === 'GET') {
      setCORSHeaders(res);
      res.statusCode = 200;
      res.end(JSON.stringify({
        success: true,
        message: 'Emergency Forever Paws API Server Running',
        timestamp: new Date().toISOString(),
        environment: 'emergency-local-no-deps'
      }));
    }
    else if (path === '/api/auth/register' && method === 'POST') {
      const body = await parseBody(req);
      console.log('📋 Registration request received:', body);

      const { email, password, name } = body;

      // Validate required fields
      if (!email || !password || !name) {
        setCORSHeaders(res);
        res.statusCode = 400;
        res.end(JSON.stringify({
          success: false,
          message: 'Missing required fields: email, password, name'
        }));
        return;
      }

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        setCORSHeaders(res);
        res.statusCode = 400;
        res.end(JSON.stringify({
          success: false,
          message: 'Invalid email format'
        }));
        return;
      }

      // Validate password strength
      if (password.length < 6) {
        setCORSHeaders(res);
        res.statusCode = 400;
        res.end(JSON.stringify({
          success: false,
          message: 'Password must be at least 6 characters long'
        }));
        return;
      }

      console.log('✅ Registration would succeed with:', { email, name });

      setCORSHeaders(res);
      res.statusCode = 200;
      res.end(JSON.stringify({
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
      }));
    }
    else if (path === '/api/auth/login' && method === 'POST') {
      const body = await parseBody(req);
      console.log('🔑 Login request received:', { email: body.email });

      setCORSHeaders(res);
      res.statusCode = 200;
      res.end(JSON.stringify({
        success: true,
        message: 'Login successful (emergency mode)',
        data: {
          user: {
            id: 'emergency-user-' + Date.now(),
            email: body.email,
            name: 'Emergency User'
          },
          token: 'emergency-jwt-token-' + Date.now()
        }
      }));
    }
    else {
      setCORSHeaders(res);
      res.statusCode = 404;
      res.end(JSON.stringify({
        success: false,
        message: 'Endpoint not found: ' + method + ' ' + path
      }));
    }
  } catch (error) {
    console.error('❌ Server error:', error.message);
    setCORSHeaders(res);
    res.statusCode = 500;
    res.end(JSON.stringify({
      success: false,
      message: 'Internal server error: ' + error.message
    }));
  }
});

server.listen(PORT, () => {
  console.log('🚀 Emergency Forever Paws API Server (No Dependencies) running on port', PORT);
  console.log('📋 Available endpoints:');
  console.log('  - GET  http://localhost:' + PORT + '/');
  console.log('  - GET  http://localhost:' + PORT + '/api/health');
  console.log('  - POST http://localhost:' + PORT + '/api/auth/register');
  console.log('  - POST http://localhost:' + PORT + '/api/auth/login');
});