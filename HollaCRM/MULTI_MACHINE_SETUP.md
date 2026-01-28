# Multi-Machine Tailscale Testing Setup

This guide shows you how to deploy HollaCRM across multiple machines on your network using Tailscale for secure communication.

## 🏗️ Architecture Overview

```
Your Network with Tailscale
├── Machine A (192.168.1.100) → Tailscale IP: 100.64.0.100
│   └── HollaCRM Master Instance
├── Machine B (192.168.1.101) → Tailscale IP: 100.64.0.101  
│   └── HollaCRM Slave Instance
├── Machine C (192.168.1.102) → Tailscale IP: 100.64.0.102
│   └── Testing Client
└── Your Laptop → Tailscale IP: 100.64.0.50
    └── Management Interface
```

## 🚀 Step-by-Step Setup

### Step 1: Prepare GitHub Repository

```bash
# 1. Create GitHub repository (do this first on GitHub)
# Go to github.com → New repository → "hollacrm"

# 2. Initialize Git in your project
cd /Users/oniasbrown/Desktop/HollaCRM
git init

# 3. Add remote origin
git remote add origin https://github.com/yourusername/hollacrm.git

# 4. Create and configure .env for each machine
cp secrets.env.example .env
# Edit .env with your actual secrets

# 5. Add and commit files
git add .
git commit -m "feat: initial HollaCRM setup with Tailscale integration"

# 6. Push to GitHub
git branch -M main
git push -u origin main
```

### Step 2: Setup Machine A (Master Instance)

```bash
# Clone repository on Machine A
git clone https://github.com/yourusername/hollacrm.git
cd hollacrm

# Create environment file
cp secrets.env.example .env

# Edit .env for Machine A
nano .env
```

**Machine A .env Configuration:**
```bash
TS_AUTHKEY=tskey-auth-your-machine-a-authkey
TAILNET_HOSTNAME=hrms-master
TAILNET_ENV=prod
TAILNET_IP=100.64.0.100
DB_PASSWORD=master-db-password-123
DJANGO_SECRET_KEY=master-secret-key-32-chars
```

```bash
# Deploy on Machine A
./deploy.sh

# Verify access
tailscale ip -4  # Should show 100.64.0.100
curl http://100.64.0.100/health
```

### Step 3: Setup Machine B (Slave Instance)

```bash
# Clone repository on Machine B
git clone https://github.com/yourusername/hollacrm.git
cd hollacrm

# Create environment file
cp secrets.env.example .env

# Edit .env for Machine B
nano .env
```

**Machine B .env Configuration:**
```bash
TS_AUTHKEY=tskey-auth-your-machine-b-authkey
TAILNET_HOSTNAME=hrms-slave
TAILNET_ENV=staging
TAILNET_IP=100.64.0.101
DB_PASSWORD=slave-db-password-456
DJANGO_SECRET_KEY=slave-secret-key-32-chars
```

```bash
# Deploy on Machine B
./deploy.sh

# Verify access
tailscale ip -4  # Should show 100.64.0.101
curl http://100.64.0.101/health
```

### Step 4: Setup Machine C (Testing Client)

```bash
# Clone repository on Machine C
git clone https://github.com/yourusername/hollacrm.git
cd hollacrm

# Create environment file
cp secrets.env.example .env

# Edit .env for Machine C (testing client)
nano .env
```

**Machine C .env Configuration:**
```bash
TS_AUTHKEY=tskey-auth-your-machine-c-authkey
TAILNET_HOSTNAME=hrms-test
TAILNET_ENV=dev
# No need to run full stack on test client
```

### Step 5: Cross-Machine Testing

```bash
# From any machine on your Tailnet, test all instances:

# Test Master Instance
curl http://100.64.0.100/api/health/
curl http://100.64.0.100/admin/

# Test Slave Instance  
curl http://100.64.0.101/api/health/
curl http://100.64.0.101/admin/

# From your laptop
open http://100.64.0.100/admin/
open http://100.64.0.101/admin/
```

## 🔧 Configuration Management

### Create Machine-Specific Configs

Create separate environment files for each machine:

```bash
# On Machine A
cp secrets.env.example .env.master
# Edit with Machine A settings
ln -sf .env.master .env

# On Machine B
cp secrets.env.example .env.slave
# Edit with Machine B settings
ln -sf .env.slave .env

# On Machine C
cp secrets.env.example .env.client
# Edit with Machine C settings
ln -sf .env.client .env
```

### Docker Compose Overrides for Different Roles

Create `docker-compose.master.yml`, `docker-compose.slave.yml`, `docker-compose.client.yml`:

**docker-compose.master.yml:**
```yaml
version: '3.8'
services:
  postgres:
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"  # Expose DB for slave replication
  horilla:
    environment:
      DJANGO_SETTINGS_MODULE: horilla.settings.master
    volumes:
      - ./master-media:/app/media
```

**docker-compose.slave.yml:**
```yaml
version: '3.8'
services:
  horilla:
    environment:
      DJANGO_SETTINGS_MODULE: horilla.settings.slave
      DATABASE_URL: postgres://slave:${DB_PASSWORD}@100.64.0.100:5432/horilla
    volumes:
      - ./slave-media:/app/media
```

## 🧪 Testing Scenarios

### 1. Load Balancing Test
```bash
# Test both instances
for i in {1..10}; do
  curl http://100.64.0.100/api/health/
  curl http://100.64.0.101/api/health/
done
```

### 2. Database Replication Test
```bash
# Create data on master
curl -X POST http://100.64.0.100/api/employees/ \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"first_name": "Test", "last_name": "User", "email": "test@example.com"}'

# Verify on slave
curl http://100.64.0.101/api/employees/ \
  -H "Authorization: Token YOUR_TOKEN"
```

### 3. Failover Test
```bash
# Stop master
ssh machine-a "cd /path/to/hollacrm && docker compose down"

# Test if slave takes over
curl http://100.64.0.101/api/health/

# Restart master
ssh machine-a "cd /path/to/hollacrm && docker compose up -d"
```

## 🔄 Git Workflow for Multi-Machine Setup

### Branching Strategy
```bash
# Main branch for production
git checkout -b production

# Staging branch for testing
git checkout -b staging

# Development branch for features
git checkout -b development

# Machine-specific branches (optional)
git checkout -b machine-a-config
git checkout -b machine-b-config
```

### Deployment Commands
```bash
# Update production (Machine A)
git checkout production
git pull origin production
./deploy.sh

# Update staging (Machine B)
git checkout staging  
git pull origin staging
./deploy.sh

# Update dev (Machine C)
git checkout development
git pull origin development
./deploy.sh
```

## 🔐 Security Best Practices

### 1. Tailscale ACL Configuration
```hcl
# In your Tailscale admin console
{
  "groups": [
    {"name": "group:hrms-servers", "users": ["machine-a", "machine-b"]},
    {"name": "group:hrms-clients", "users": ["machine-c", "your-laptop"]},
  ],
  "acls": [
    {
      "action": "accept",
      "src":    ["group:hrms-servers"],
      "dst":    ["tag:hrms:*"],
    },
    {
      "action": "accept", 
      "src":    ["group:hrms-clients"],
      "dst":    ["tag:hrms:80", "tag:hrms:443", "tag:hrms:8000"],
    },
  ],
}
```

### 2. Environment Variable Security
```bash
# Never commit .env files
echo ".env" >> .gitignore
echo "secrets.env" >> .gitignore

# Use different auth keys per machine
# Generate from Tailscale admin panel
tailscale authkeys create --tags=tag:hrms-server --reusable --ephemeral
```

### 3. Git Security
```bash
# Ensure sensitive files are ignored
git check-ignore .env secrets.env

# Verify no secrets in history
git log --grep="password\|secret\|key" --oneline

# Use pre-commit hooks
npm install -g pre-commit
pre-commit install
```

## 📊 Monitoring Across Machines

### Centralized Monitoring Setup
```bash
# On Master (Machine A), enable Prometheus remote access
# Edit monitoring/prometheus.yml
global:
  external_labels:
    machine: 'master'
    region: 'production'

scrape_configs:
  - job_name: 'slave-metrics'
    static_configs:
      - targets: ['100.64.0.101:9090']
```

### Health Check Script
```bash
#!/bin/bash
# health-check.sh
echo "Checking HollaCRM cluster health..."

echo "Master (100.64.0.100):"
curl -s http://100.64.0.100/api/health/ && echo "✅ OK" || echo "❌ FAILED"

echo "Slave (100.64.0.101):"  
curl -s http://100.64.0.101/api/health/ && echo "✅ OK" || echo "❌ FAILED"

echo "Database Replication:"
# Add your replication check logic here
```

## 🚀 Quick Start Script

Create `setup-multi-machine.sh`:
```bash
#!/bin/bash
MACHINE=$1
ENV_FILE=".env.$MACHINE"

case $MACHINE in
  "master")
    TS_AUTHKEY="your-master-authkey"
    TAILNET_IP="100.64.0.100"
    ;;
  "slave") 
    TS_AUTHKEY="your-slave-authkey"
    TAILNET_IP="100.64.0.101"
    ;;
  "client")
    TS_AUTHKEY="your-client-authkey"
    TAILNET_IP="100.64.0.102"
    ;;
esac

cp secrets.env.example $ENV_FILE
sed -i "s/tskey-auth-your-authkey-here/$TS_AUTHKEY/" $ENV_FILE
sed -i "s/100.64.0.1/$TAILNET_IP/" $ENV_FILE
ln -sf $ENV_FILE .env

./deploy.sh
```

Usage:
```bash
# On Machine A
./setup-multi-machine.sh master

# On Machine B  
./setup-multi-machine.sh slave

# On Machine C
./setup-multi-machine.sh client
```

This setup allows you to test HollaCRM across multiple machines securely using Tailscale, with proper Git versioning and environment isolation!