FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json
COPY package.json .

# Install dependencies
RUN npm install --production

# Copy application code
COPY server.js .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "server.js"]
