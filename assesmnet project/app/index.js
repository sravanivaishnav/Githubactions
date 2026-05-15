name: Terraform Plan
// Minimal Node.js HTTP server as the app entrypoint
const http = require('http');

const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ message: 'Hello from app/index.js' }));
});

server.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});

module.exports = server;
        working-directory: infra
