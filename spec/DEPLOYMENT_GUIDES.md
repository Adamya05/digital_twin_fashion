# Deployment Guides

Comprehensive guide for deploying the Virtual Try-On API across different environments including local development, Docker containerization, and cloud platforms (AWS, GCP, Azure).

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Docker Containerization](#docker-containerization)
- [AWS Deployment](#aws-deployment)
- [Google Cloud Platform Deployment](#google-cloud-platform-deployment)
- [Azure Deployment](#azure-deployment)
- [Database Setup and Migration](#database-setup-and-migration)
- [CDN Configuration](#cdn-configuration)
- [Monitoring and Logging](#monitoring-and-logging)
- [Backup and Recovery](#backup-and-recovery)
- [Scaling and Load Balancing](#scaling-and-load-balancing)
- [Security Configuration](#security-configuration)
- [CI/CD Pipeline](#cicd-pipeline)
- [Production Checklist](#production-checklist)

## Overview

This guide covers deploying the Virtual Try-On API and related services across multiple environments and cloud platforms. It includes:

- **Development**: Local setup with hot reload and debugging
- **Staging**: Production-like environment for testing
- **Production**: High-availability, scalable deployment
- **Multi-cloud**: AWS, GCP, and Azure deployment options

### Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   API Gateway   │    │   CDN/WAF       │
│   (ALB/GLB/ALB) │    │   (Kong/APIM)   │    │   (CloudFlare)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
    ┌─────────────────────────────┼─────────────────────────────┐
    │                             │                             │
┌───▼────┐  ┌────┐  ┌────┐  ┌────▼────┐  ┌─────────────────┐
│  API   │  │ API│  │ API│  │  WebSocket│  │   Background    │
│Server 1│  │2   │  │3   │  │  Server  │  │   Workers       │
└────────┘  └────┘  └────┘  └──────────┘  └─────────────────┘
    │         │         │         │              │
    └─────────┼─────────┼─────────┼──────────────┘
              │         │         │
    ┌─────────┼─────────┼─────────┼──────────────┐
    │         │         │         │              │
┌───▼────┐  ┌▼────┐  ┌▼────┐  ┌▼──────┐  ┌────▼────┐
│Redis   │  │PostgreSQL│  │File    │  │Message  │  │Monitoring│
│Cache   │  │Database  │  │Storage │  │Queue    │  │(Prometheus)│
└────────┘  └─────────┘  └────────┘  └─────────┘  └───────────┘
```

## Prerequisites

### Required Software

```bash
# Node.js and npm
node --version  # v18.0.0+
npm --version   # v9.0.0+

# Docker and Docker Compose
docker --version
docker-compose --version

# Git
git --version

# Database tools
sqlite3 --version
postgresql-client --version

# Cloud CLI tools
aws-cli --version          # For AWS
gcloud --version           # For GCP
az --version               # For Azure
```

### System Requirements

#### Development Environment
- **CPU**: 4+ cores
- **RAM**: 8GB+ 
- **Storage**: 50GB+ SSD
- **OS**: Linux, macOS, or Windows 10+

#### Production Environment
- **CPU**: 8+ cores per instance
- **RAM**: 16GB+ per instance
- **Storage**: 100GB+ SSD per instance
- **Network**: 1Gbps+ connection

### Required Accounts

1. **Cloud Provider Account**
   - AWS (Amazon Web Services)
   - Google Cloud Platform
   - Microsoft Azure
   - Digital Ocean (alternative)

2. **Domain and DNS**
   - Domain name registration
   - DNS management service

3. **SSL Certificates**
   - Let's Encrypt (free)
   - Commercial SSL provider

4. **Monitoring Services**
   - DataDog, New Relic, or similar
   - Log aggregation service

## Local Development Setup

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/virtual-tryon-api.git
cd virtual-tryon-api

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev

# In another terminal, start the mock server (optional)
cd api-server
npm install
npm run dev
```

### Complete Local Setup

```bash
#!/bin/bash
# scripts/local-setup.sh

echo "🚀 Setting up Virtual Try-On API for local development..."

# Check prerequisites
echo "Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm is required"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ git is required"; exit 1; }

# Set up main API server
echo "Setting up main API server..."
cd api-server
npm install

# Copy and configure environment
if [ ! -f .env ]; then
  cp .env.example .env
  echo "✅ Created .env file - please configure it"
fi

# Set up database
echo "Setting up database..."
mkdir -p data
npm run db:migrate
npm run db:seed

# Generate required directories
mkdir -p logs uploads temp

echo "✅ Main API server setup complete!"

# Set up mock server (optional)
read -p "Do you want to set up the mock server? (y/N): " setup_mock
if [[ $setup_mock =~ ^[Yy]$ ]]; then
  echo "Setting up mock server..."
  cd ../api-server
  npm install
  
  if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created mock server .env file"
  fi
  
  mkdir -p data logs uploads
  echo "✅ Mock server setup complete!"
fi

# Set up Flutter app (optional)
read -p "Do you want to set up the Flutter app? (y/N): " setup_flutter
if [[ $setup_flutter =~ ^[Yy]$ ]]; then
  echo "Setting up Flutter app..."
  cd ../flutter_app
  flutter pub get
  
  if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created Flutter .env file"
  fi
  
  echo "✅ Flutter app setup complete!"
fi

echo ""
echo "🎉 Local development setup complete!"
echo ""
echo "To start the servers:"
echo "Main API:    cd api-server && npm run dev"
echo "Mock API:    cd api-server && npm run dev"
echo "Flutter App: cd flutter_app && flutter run"
echo ""
echo "📚 Documentation available at:"
echo "API Docs:    http://localhost:3000/docs"
echo "API Health:  http://localhost:3000/health"
```

### Environment Configuration

```bash
# .env.development
NODE_ENV=development
PORT=3000
HOST=localhost

# Database
DB_TYPE=sqlite
DB_PATH=./data/development.db

# JWT Configuration
JWT_SECRET=your-development-jwt-secret-key-change-in-production
JWT_EXPIRES_IN=30m
REFRESH_TOKEN_EXPIRES_IN=7d

# Mock Data
MOCK_DATA_SIZE=medium
ENABLE_REALISTIC_DELAY=false
ENABLE_ERROR_SIMULATION=true
ERROR_RATE=0.05

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
CORS_CREDENTIALS=true

# Rate Limiting
ENABLE_RATE_LIMITING=false

# Logging
LOG_LEVEL=debug
LOG_FILE=./logs/development.log

# File Uploads
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=jpg,jpeg,png,gif,mp4,webm,glb,gltf

# Redis (optional for caching)
REDIS_URL=redis://localhost:6379

# External Services
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=
SMTP_PASS=

# Development features
ENABLE_SWAGGER=true
ENABLE_HOT_RELOAD=true
ENABLE_DEBUG_TOOLS=true
```

### Development Scripts

```json
{
  "scripts": {
    "dev": "nodemon server.js",
    "dev:api": "concurrently \"npm run dev\" \"npm run dev:mock\"",
    "dev:api:server": "nodemon api-server/server.js",
    "dev:mock:server": "nodemon api-server/server.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "db:migrate": "node scripts/migrate-db.js",
    "db:seed": "node scripts/seed-db.js",
    "db:reset": "node scripts/reset-db.js",
    "build": "npm run build:api",
    "build:api": "webpack --mode production",
    "start": "node server.js",
    "start:prod": "NODE_ENV=production node server.js",
    "docker:dev": "docker-compose -f docker-compose.dev.yml up",
    "docker:prod": "docker-compose -f docker-compose.yml up -d"
  }
}
```

### Docker Development Setup

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  api-server:
    build:
      context: ./api-server
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - ./api-server:/app
      - /app/node_modules
      - api-server-data:/app/data
    environment:
      - NODE_ENV=development
      - DB_TYPE=sqlite
    depends_on:
      - redis
      - postgres
    command: npm run dev

  mock-server:
    build:
      context: ./api-server
      dockerfile: Dockerfile.dev
    ports:
      - "3001:3000"
    volumes:
      - ./api-server:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - PORT=3000
      - MOCK_DATA_SIZE=large
    command: npm run mock:dev

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: virtual_tryon
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./sql/init:/docker-entrypoint-initdb.d

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
    environment:
      MH_STORAGE: maildir
      MH_MAILDIR_PATH: /maildir

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "8080:80"
    depends_on:
      - postgres

volumes:
  api-server-data:
  postgres-data:
  redis-data:
```

## Docker Containerization

### Production Dockerfile

```dockerfile
# api-server/Dockerfile
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY package-lock.json* ./

# Install dependencies
RUN npm ci --only=production --silent

# Production stage
FROM node:18-alpine AS production

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

# Create app directory
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

# Create necessary directories
RUN mkdir -p data logs uploads temp && \
    chown -R nodejs:nodejs data logs uploads temp

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Expose port
EXPOSE 3000

# Start command
CMD ["node", "server.js"]
```

### Docker Compose Production

```yaml
# docker-compose.yml
version: '3.8'

services:
  api-server:
    build:
      context: ./api-server
      dockerfile: Dockerfile
    image: virtual-tryon-api:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_TYPE=postgres
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=virtual_tryon
      - DB_USER=postgres
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASS=${SMTP_PASS}
      - CORS_ORIGIN=${CORS_ORIGIN}
    depends_on:
      - postgres
      - redis
    volumes:
      - api-uploads:/app/uploads
      - api-logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: virtual_tryon
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./sql/init:/docker-entrypoint-initdb.d
      - ./sql/backups:/backups
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/logs:/var/log/nginx
      - api-uploads:/var/www/uploads:ro
    depends_on:
      - api-server
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  backup:
    image: postgres:15-alpine
    environment:
      PGPASSWORD: ${DB_PASSWORD}
    volumes:
      - ./sql/backups:/backups
      - postgres-data:/var/lib/postgresql/data:ro
    command: >
      sh -c "
        while true; do
          pg_dump -h postgres -U postgres -d virtual_tryon | 
          gzip > /backups/backup_$$(date +%Y%m%d_%H%M%S).sql.gz
          find /backups -name 'backup_*.sql.gz' -mtime +7 -delete
          sleep 86400
        done
      "
    depends_on:
      - postgres

volumes:
  postgres-data:
  redis-data:
  api-uploads:
  api-logs:
```

### Multi-stage Dockerfile

```dockerfile
# Multi-stage build for optimization
FROM node:18-alpine AS base

# Install dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Development stage
FROM base AS development
COPY . .
CMD ["npm", "run", "dev"]

# Build stage
FROM base AS builder
COPY . .
RUN npm ci --only=dev
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Security updates
RUN apk update && apk upgrade

# Create user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=base --chown=nodejs:nodejs /app/package*.json ./
COPY --chown=nodejs:nodejs . .

# Create directories
RUN mkdir -p data logs uploads temp && \
    chown -R nodejs:nodejs data logs uploads temp

USER nodejs

EXPOSE 3000
CMD ["npm", "start"]
```

## AWS Deployment

### ECS Fargate Deployment

```json
{
  "family": "virtual-tryon-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "api-server",
      "image": "ACCOUNT.dkr.ecr.REGION.amazonaws.com/virtual-tryon-api:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "DB_HOST",
          "value": "virtual-tryon-db.cluster-REGION.rds.amazonaws.com"
        },
        {
          "name": "REDIS_URL",
          "value": "redis://virtual-tryon-cache:6379"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:ssm:REGION:ACCOUNT:parameter/virtual-tryon-db-password"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:ssm:REGION:ACCOUNT:parameter/virtual-tryon-jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/virtual-tryon-api",
          "awslogs-region": "REGION",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

### ECS Service Definition

```json
{
  "serviceName": "virtual-tryon-api-service",
  "cluster": "virtual-tryon-cluster",
  "taskDefinition": "virtual-tryon-api:1",
  "desiredCount": 3,
  "launchType": "FARGATE",
  "platformVersion": "LATEST",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "subnet-12345",
        "subnet-67890"
      ],
      "securityGroups": [
        "sg-12345"
      ],
      "assignPublicIp": "ENABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:REGION:ACCOUNT:targetgroup/virtual-tryon-api/12345",
      "containerName": "api-server",
      "containerPort": 3000
    }
  ],
  "serviceRegistries": [
    {
      "registryArn": "arn:aws:servicediscovery:REGION:ACCOUNT:service/virtual-tryon-api"
    }
  ],
  "deploymentConfiguration": {
    "maximumPercent": 200,
    "minimumHealthyPercent": 100
  },
  "deploymentController": {
    "type": "ECS"
  },
  "enableExecuteCommand": true
}
```

### RDS PostgreSQL Setup

```bash
#!/bin/bash
# scripts/setup-aws-rds.sh

# Variables
DB_INSTANCE_CLASS="db.t3.medium"
DB_ENGINE="postgres"
DB_ENGINE_VERSION="15.4"
DB_MASTER_USERNAME="postgres"
DB_NAME="virtual_tryon"
BACKUP_RETENTION=30
MULTI_AZ=true

# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name virtual-tryon-db-subnet-group \
  --db-subnet-group-description "Subnet group for Virtual Try-On DB" \
  --subnet-ids subnet-12345 subnet-67890 \
  --tags Key=Name,Value=virtual-tryon-db-subnet-group

# Create DB parameter group
aws rds create-db-parameter-group \
  --db-parameter-group-name virtual-tryon-db-params \
  --db-parameter-group-family postgres15 \
  --description "Parameter group for Virtual Try-On DB"

# Modify DB parameter group
aws rds modify-db-parameter-group \
  --db-parameter-group-name virtual-tryon-db-params \
  --parameters ParameterName=shared_preload_libraries,Value=pg_stat_statements \
  --parameters ParameterName=log_statement,Value=all \
  --parameters ParameterName=log_min_duration_statement,Value=1000

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier virtual-tryon-db \
  --db-instance-class $DB_INSTANCE_CLASS \
  --engine $DB_ENGINE \
  --engine-version $DB_ENGINE_VERSION \
  --master-username $DB_MASTER_USERNAME \
  --master-user-password $(openssl rand -base64 32) \
  --db-name $DB_NAME \
  --allocated-storage 100 \
  --storage-type gp2 \
  --storage-encrypted \
  --vpc-security-group-ids sg-12345 \
  --db-subnet-group-name virtual-tryon-db-subnet-group \
  --db-parameter-group-name virtual-tryon-db-params \
  --backup-retention-period $BACKUP_RETENTION \
  --multi-az \
  --enable-performance-insights \
  --monitoring-interval 60 \
  --monitoring-role-arn arn:aws:iam::ACCOUNT:role/rds-monitoring-role

echo "RDS instance created. Use AWS Console to get the master password."
```

### ElastiCache Redis Setup

```bash
#!/bin/bash
# scripts/setup-aws-elasticache.sh

# Variables
CACHE_NODE_TYPE="cache.t3.micro"
CACHE_ENGINE="redis"
CACHE_ENGINE_VERSION="7.0"
NUM_CACHE_NODES=1

# Create ElastiCache subnet group
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name virtual-tryon-cache-subnet-group \
  --cache-subnet-group-description "Subnet group for Virtual Try-On Cache" \
  --subnet-ids subnet-12345 subnet-67890

# Create ElastiCache parameter group
aws elasticache create-cache-parameter-group \
  --cache-parameter-group-name virtual-tryon-redis-params \
  --cache-parameter-group-family redis7 \
  --description "Parameter group for Virtual Try-On Redis"

# Create ElastiCache replication group
aws elasticache create-replication-group \
  --replication-group-id virtual-tryon-cache \
  --replication-group-description "Redis cache for Virtual Try-On API" \
  --cache-node-type $CACHE_NODE_TYPE \
  --engine $CACHE_ENGINE \
  --engine-version $CACHE_ENGINE_VERSION \
  --num-cache-clusters $NUM_CACHE_NODES \
  --cache-subnet-group-name virtual-tryon-cache-subnet-group \
  --cache-parameter-group-name virtual-tryon-redis-params \
  --port 6379 \
  --automatic-failover-enabled \
  --multi-az-enabled

echo "ElastiCache Redis cluster created."
```

### CloudFormation Template

```yaml
# infrastructure/cloudformation.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Virtual Try-On API Infrastructure'

Parameters:
  Environment:
    Type: String
    Default: production
    AllowedValues: [development, staging, production]
  
  DatabasePassword:
    Type: String
    NoEcho: true
    Description: RDS master password
  
  RedisPassword:
    Type: String
    NoEcho: true
    Description: Redis auth token

Resources:
  # VPC
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-vpc'

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-igw'

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-public-subnet-1'

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: 10.0.2.0/24
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-public-subnet-2'

  # Private Subnets
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: 10.0.3.0/24
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-private-subnet-1'

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: 10.0.4.0/24
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-private-subnet-2'

  # NAT Gateways
  NatGateway1EIP:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-nat-eip-1'

  NatGateway2EIP:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-nat-eip-2'

  NatGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway1EIP.AllocationId
      SubnetId: !Ref PublicSubnet1
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-nat-1'

  NatGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway2EIP.AllocationId
      SubnetId: !Ref PublicSubnet2
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-nat-2'

  # Route Tables
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-public-rt'

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet1

  PublicSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet2

  PrivateRouteTable1:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-private-rt-1'

  DefaultPrivateRoute1:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway1

  PrivateSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      SubnetId: !Ref PrivateSubnet1

  PrivateRouteTable2:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-private-rt-2'

  DefaultPrivateRoute2:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway2

  PrivateSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      SubnetId: !Ref PrivateSubnet2

  # Security Groups
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ALB
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
      SecurityGroupEgress:
        - IpProtocol: -1
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-alb-sg'

  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ECS tasks
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 3000
          ToPort: 3000
          SourceSecurityGroupId: !Ref ALBSecurityGroup
      SecurityGroupEgress:
        - IpProtocol: -1
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-ecs-sg'

  RDSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for RDS
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref ECSSecurityGroup
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-rds-sg'

  RedisSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ElastiCache
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 6379
          ToPort: 6379
          SourceSecurityGroupId: !Ref ECSSecurityGroup
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-redis-sg'

  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub '${Environment}-virtual-tryon-alb'
      Scheme: internet-facing
      Type: application
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup
      LoadBalancerAttributes:
        - Key: idle_timeout.timeout_seconds
          Value: '60'
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-virtual-tryon-alb'

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub '${Environment}-virtual-tryon-tg'
      Port: 3000
      Protocol: HTTP
      VpcId: !Ref VPC
      TargetGroupAttributes:
        - Key: deregistration_delay.timeout_seconds
          Value: '60'
        - Key: load_balancing.algorithm.type
          Value: 'round_robin'
        - Key: target_registration_stats.value
          Value: '600'
      HealthCheckPath: /health
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP

  # RDS Database Subnet Group
  DatabaseSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupName: !Sub '${Environment}-virtual-tryon-db-subnet-group'
      DBSubnetGroupDescription: Subnet group for Virtual Try-On database
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

  # RDS Database
  Database:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceClass: db.t3.medium
      DBInstanceIdentifier: !Sub '${Environment}-virtual-tryon-db'
      Engine: postgres
      EngineVersion: '15.4'
      MasterUsername: postgres
      MasterUserPassword: !Ref DatabasePassword
      DBName: virtual_tryon
      AllocatedStorage: 100
      StorageType: gp2
      StorageEncrypted: true
      DBSubnetGroupName: !Ref DatabaseSubnetGroup
      VPCSecurityGroups:
        - !Ref RDSSecurityGroup
      BackupRetentionPeriod: 30
      PreferredBackupWindow: '03:00-04:00'
      PreferredMaintenanceWindow: 'sun:04:00-sun:05:00'
      MultiAZ: true
      PubliclyAccessible: false
      DeletionProtection: true
      EnablePerformanceInsights: true
      PerformanceInsightsRetentionPeriod: 7

  # ElastiCache Subnet Group
  CacheSubnetGroup:
    Type: AWS::ElastiCache::SubnetGroup
    Properties:
      CacheSubnetGroupName: !Sub '${Environment}-virtual-tryon-cache-subnet-group'
      CacheSubnetGroupDescription: Subnet group for Virtual Try-On cache
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

  # ElastiCache Replication Group
  CacheCluster:
    Type: AWS::ElastiCache::ReplicationGroup
    Properties:
      ReplicationGroupId: !Sub '${Environment}-virtual-tryon-cache'
      Description: Redis cluster for Virtual Try-On API
      CacheNodeType: cache.t3.micro
      Engine: redis
      EngineVersion: '7.0'
      Port: 6379
      CacheSubnetGroupName: !Ref CacheSubnetGroup
      SecurityGroupIds:
        - !Ref RedisSecurityGroup
      NumCacheClusters: 1
      AutomaticFailoverEnabled: true
      MultiAZEnabled: true
      AuthToken: !Ref RedisPassword

  # ECS Cluster
  Cluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub '${Environment}-virtual-tryon-cluster'

  # ECS Task Definition
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub '${Environment}-virtual-tryon-api'
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      Cpu: 512
      Memory: 1024
      ExecutionRoleArn: !Sub 'arn:aws:iam::${AWS::AccountId}:role/ecsTaskExecutionRole'
      TaskRoleArn: !Sub 'arn:aws:iam::${AWS::AccountId}:role/ecsTaskRole'
      ContainerDefinitions:
        - Name: api-server
          Image: !Sub '${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/virtual-tryon-api:latest'
          PortMappings:
            - ContainerPort: 3000
              Protocol: tcp
          Environment:
            - Name: NODE_ENV
              Value: !Ref Environment
            - Name: DB_HOST
              Value: !GetAtt Database.Endpoint.Address
            - Name: DB_PORT
              Value: '5432'
            - Name: DB_NAME
              Value: virtual_tryon
            - Name: DB_USER
              Value: postgres
            - Name: REDIS_URL
              Value: !Sub 'redis://${CacheCluster.ConfigurationEndpoint.Address}:6379'
          Secrets:
            - Name: DB_PASSWORD
              ValueFrom: !Sub 'arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter/virtual-tryon-db-password'
            - Name: JWT_SECRET
              ValueFrom: !Sub 'arn:aws:ssm:${AWS::Region}:${AWS::AccountId}:parameter/virtual-tryon-jwt-secret'
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref LogGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: ecs
          HealthCheck:
            Command:
              - CMD-SHELL
              - curl -f http://localhost:3000/health || exit 1
            Interval: 30
            Retries: 3
            StartPeriod: 60
            Timeout: 5

  # CloudWatch Log Group
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub '/ecs/${Environment}-virtual-tryon-api'
      RetentionInDays: 30

  # ECS Service
  Service:
    Type: AWS::ECS::Service
    Properties:
      ServiceName: !Sub '${Environment}-virtual-tryon-api-service'
      Cluster: !Ref Cluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: 3
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          Subnets:
            - !Ref PrivateSubnet1
            - !Ref PrivateSubnet2
          SecurityGroups:
            - !Ref ECSSecurityGroup
          AssignPublicIp: DISABLED
      LoadBalancers:
        - ContainerName: api-server
          ContainerPort: 3000
          TargetGroupArn: !Ref TargetGroup
      DeploymentConfiguration:
        MaximumPercent: 200
        MinimumHealthyPercent: 100

Outputs:
  ALBDNSName:
    Description: DNS name of the load balancer
    Value: !GetAtt ApplicationLoadBalancer.DNSName
    Export:
      Name: !Sub '${Environment}-virtual-tryon-alb-dns'

  DatabaseEndpoint:
    Description: RDS endpoint address
    Value: !GetAtt Database.Endpoint.Address
    Export:
      Name: !Sub '${Environment}-virtual-tryon-db-endpoint'

  CacheEndpoint:
    Description: ElastiCache endpoint address
    Value: !GetAtt CacheCluster.ConfigurationEndpoint.Address
    Export:
      Name: !Sub '${Environment}-virtual-tryon-cache-endpoint'
```

### Deployment Script

```bash
#!/bin/bash
# scripts/deploy-aws.sh

set -e

# Configuration
STACK_NAME="virtual-tryon-infrastructure"
REGION="us-west-2"
ENVIRONMENT="production"
ECR_REPOSITORY="virtual-tryon-api"
ECS_CLUSTER="virtual-tryon-cluster"
SERVICE_NAME="virtual-tryon-api-service"

echo "🚀 Deploying Virtual Try-On API to AWS..."

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required"; exit 1; }

# Get AWS account ID and configure
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $AWS_ACCOUNT_ID"

# Configure AWS CLI if not already configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "⚠️  AWS CLI not configured. Please configure it first."
  aws configure
fi

# Get ECR login token
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push Docker image
echo "🐳 Building and pushing Docker image..."
cd api-server

docker build -t $ECR_REPOSITORY:latest .
docker tag $ECR_REPOSITORY:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY:latest

# Update ECS service with new image
echo "🔄 Updating ECS service..."
aws ecs update-service \
  --cluster $ECS_CLUSTER \
  --service $SERVICE_NAME \
  --force-new-deployment

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable \
  --cluster $ECS_CLUSTER \
  --services $SERVICE_NAME

echo "✅ Deployment completed successfully!"

# Get load balancer URL
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query 'Stacks[0].Outputs')

ALB_DNS=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="ALBDNSName") | .OutputValue')

echo "🌐 Application URL: http://$ALB_DNS"
echo "🏥 Health Check: http://$ALB_DNS/health"
```

This is just the first part of the comprehensive deploymemt guides. I'll continue with Google Cloud Platform deploymemt, Azure deploymemt, database setup, CDN configuration, monitoring, backup and recovery, scaling, security configuration, CI/CD pipeline, and production checklist.
