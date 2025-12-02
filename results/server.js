const express = require('express');
const app = express();
const port = 8080;

// Middleware
app.use(express.json());

// Root endpoint - service status
app.get('/', (req, res) => {
  const response = {
    service: 'results',
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  };
  res.json(response);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ healthy: true });
});

// Start server
app.listen(port, () => {
  console.log(`Results service listening on port ${port}`);
});
