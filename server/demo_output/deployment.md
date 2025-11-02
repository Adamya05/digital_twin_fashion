# Deployment Guide

## Prerequisites

### System Requirements
- Node.js 18.0.0 or higher
- npm or yarn package manager
- 1GB+ available disk space
- 512MB+ RAM

### Network Requirements
- Port 3000 (configurable)
- HTTPS for production (recommended)
- CORS configured for client domains

## Installation Steps

### 1. Clone and Setup
```bash
git clone <repository>
cd virtual-tryon-mock-server
cp .env.example .env
# Edit .env with your configuration
```

### 2. Install Dependencies
```bash
npm install
# or
yarn install
```

### 3. Configure Environment
Edit `.env` file with your settings:
```env
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
JWT_SECRET=your-super-secret-production-key
```

### 4. Start Server
```bash
# Development
npm run dev

# Production
npm start

# Using PM2 (recommended for production)
pm2 start server.js --name "tryon-mock-server"
```

## Production Deployment

### Using PM2
```bash
# Install PM2
npm install -g pm2

# Start with ecosystem file
pm2 start ecosystem.config.js

# Monitor
pm2 monit

# Logs
pm2 logs tryon-mock-server
```

### Using Docker
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
EXPOSE 3000

USER node
CMD ["npm", "start"]
```

```bash
# Build and run
docker build -t tryon-mock-server .
docker run -p 3000:3000 tryon-mock-server
```

### Using systemd
Create service file:
```ini
[Unit]
Description=Virtual Try-On Mock Server
After=network.target

[Service]
Type=simple
User=node
WorkingDirectory=/path/to/server
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable tryon-mock-server
sudo systemctl start tryon-mock-server
```

## Environment-Specific Configuration

### Development
```env
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug
ENABLE_MOCK_AUTH=true
ENABLE_COMPRESSION=false
```

### Staging
```env
NODE_ENV=staging
PORT=3000
LOG_LEVEL=info
ENABLE_MOCK_AUTH=true
ENABLE_COMPRESSION=true
```

### Production
```env
NODE_ENV=production
PORT=3000
LOG_LEVEL=warn
ENABLE_MOCK_AUTH=false
ENABLE_COMPRESSION=true
AUTO_SAVE=true
```

## Security Hardening

### 1. Environment Variables
```bash
# Set secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)

# Set secure session secret
SESSION_SECRET=$(openssl rand -base64 32)
```

### 2. Firewall Configuration
```bash
# Allow only necessary ports
sudo ufw allow 22    # SSH
sudo ufw allow 3000  # Application
sudo ufw enable
```

### 3. SSL/TLS Setup
Use reverse proxy (nginx) for SSL termination:
```nginx
server {
    listen 443 ssl;
    server_name api.tryon.com;

    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 4. Rate Limiting
Configure rate limits based on expected traffic:
```env
RATE_LIMIT_WINDOW_MS=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100  # 100 requests per 15 minutes
```

## Monitoring & Maintenance

### Health Monitoring
```bash
# Check server status
curl http://localhost:3000/health

# Check API health
curl http://localhost:3000/api/health
```

### Log Management
```bash
# View recent logs
tail -f logs/app.log

# Rotate logs
logrotate /path/to/logrotate.conf
```

### Backup Strategy
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf backup_$DATE.tar.gz data/ logs/
```

### Performance Monitoring
Monitor key metrics:
- Response time
- Memory usage
- CPU utilization
- Error rates
- Request volume

## Scaling Considerations

### Horizontal Scaling
- Use load balancer (nginx, HAProxy)
- Stateless architecture supports multiple instances
- Shared storage for static assets

### Database Migration
When ready to move from mock to real database:
1. Export mock data
2. Set up MongoDB/PostgreSQL
3. Update DATABASE_URL
4. Run migration scripts
5. Update application code

### CDN Integration
For static assets:
1. Upload 3D models to CDN
2. Update model URLs
3. Configure CORS for CDN
4. Set appropriate cache headers

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

#### Permission Errors
```bash
# Fix file permissions
chmod +x start.sh
chown -R node:node /path/to/server
```

#### Memory Issues
```bash
# Monitor memory usage
ps aux | grep node

# Increase memory limit
node --max-old-space-size=2048 server.js
```

### Debug Mode
```bash
# Enable debug logging
LOG_LEVEL=debug npm run dev

# Enable verbose npm
npm install --verbose
```

### Log Analysis
```bash
# Search for errors
grep "ERROR" logs/app.log

# Analyze response times
grep "duration" logs/app.log | tail -100
```

## Support & Maintenance

### Regular Maintenance Tasks
1. Update dependencies monthly
2. Review and rotate logs
3. Monitor disk usage
4. Check security advisories
5. Test backup/restore procedures

### Emergency Procedures
1. Stop server: `pm2 stop tryon-mock-server`
2. Check logs: `pm2 logs tryon-mock-server`
3. Restart if needed: `pm2 restart tryon-mock-server`
4. Rollback if necessary: Use previous version

### Contact Information
- Development Team: dev@company.com
- Production Issues: ops@company.com
- Documentation: docs.company.com
