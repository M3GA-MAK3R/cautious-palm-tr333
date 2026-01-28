# HollaCRM Testing & Operations Guide

## 🚀 Quick Start - Turn On

### Prerequisites
```bash
# Verify Docker is running
docker --version
docker compose version

# Verify Tailscale (if using)
tailscale status
```

### Step 1: Environment Setup
```bash
# Navigate to project
cd /Users/oniasbrown/Desktop/HollaCRM

# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

**Required .env variables:**
```bash
TS_AUTHKEY=tskey-auth-your-authkey-here
TAILNET_HOSTNAME=hrms-server
TAILNET_ENV=prod
DB_PASSWORD=your-secure-db-password
DJANGO_SECRET_KEY=your-32-char-secret-key
```

### Step 2: Deploy & Start
```bash
# Automated deployment (recommended)
./deploy.sh

# OR manual deployment
docker compose up -d
docker compose logs -f
```

### Step 3: Verify Health
```bash
# Check container status
docker compose ps

# Wait for healthy status
watch -n 2 'docker compose ps'

# Check logs if issues
docker compose logs horilla
docker compose logs postgres
```

### Step 4: Access System
```bash
# Get Tailscale IP
tailscale ip -4

# Test API endpoint
curl -H "Authorization: Token YOUR_TOKEN" http://100.x.x.x/api/employees/

# Access web interface
open http://100.x.x.x/admin/
```

---

## 🛑 Power Off - Clean Shutdown

### Graceful Shutdown
```bash
# Stop all services
docker compose down

# Verify stopped
docker compose ps
```

### Full Cleanup
```bash
# Complete cleanup script
./cleanup.sh

# OR manual cleanup
docker compose down -v --remove-orphans
docker system prune -f
docker volume prune -f
```

### Emergency Force Stop
```bash
# Force stop all containers
docker compose down --timeout 30 --force

# Kill all Docker containers
docker kill $(docker ps -q) 2>/dev/null || true
```

---

## 🧪 Testing Workflow

### 1. Unit Testing
```bash
# Test individual services
docker compose exec horilla python manage.py test

# Test with coverage
docker compose exec horilla python -m pytest --cov=employees
```

### 2. Integration Testing
```bash
# Test API endpoints
curl -f http://100.x.x.x/api/health/ || echo "Health check failed"

# Test database connection
docker compose exec postgres pg_isready -U postgres

# Test file uploads
curl -X POST -F "file=@test.txt" http://100.x.x.x/api/upload/
```

### 3. Load Testing
```bash
# Install Apache Bench
brew install apache2bench  # macOS
sudo apt-get install apache2-utils  # Linux

# Load test API
ab -n 100 -c 10 http://100.x.x.x/api/employees/

# Monitor during load test
docker stats
```

### 4. Security Testing
```bash
# Check for exposed ports
nmap -sS -O 100.x.x.x

# Test authentication
curl -v http://100.x.x.x/api/employees/  # Should return 401

# Test CORS headers
curl -H "Origin: http://malicious.com" http://100.x.x.x/api/
```

---

## 🧹 Code Hygiene Best Practices

### Pre-Commit Checklist
```bash
# 1. Update dependencies
docker compose exec horilla pip install --upgrade pip
docker compose exec horilla pip list --outdated

# 2. Run linting
docker compose exec horilla flake8 .
docker compose exec horilla black --check .
docker compose exec horilla isort --check-only .

# 3. Run security scan
docker compose exec horilla bandit -r .
docker compose exec horilla safety check

# 4. Run tests
docker compose exec horilla python manage.py test --keepdb
```

### Git Hygiene Commands
```bash
# Before commit
git status
git diff --staged
git add .
git commit -m "feat: add new feature - fixes #123"

# After commit
git push origin main
```

### Docker Hygiene
```bash
# Clean up unused resources
docker system prune -f
docker volume prune -f
docker image prune -f

# Remove old images
docker rmi $(docker images --filter "dangling=true" -q) 2>/dev/null || true

# Monitor resource usage
docker stats --no-stream
df -h  # Check disk space
```

### Environment Hygiene
```bash
# Check environment variables
docker compose exec horilla env | grep -E "(DB_|DJANGO_|TS_)"

# Validate configuration
docker compose config

# Check logs for errors
docker compose logs --tail=50 horilla | grep -i error
```

---

## 🔍 Troubleshooting Commands

### Service Issues
```bash
# Restart specific service
docker compose restart horilla

# Rebuild service
docker compose up -d --build horilla

# Check service logs
docker compose logs -f horilla

# Enter container for debugging
docker compose exec horilla bash
```

### Database Issues
```bash
# Check database connection
docker compose exec postgres psql -U postgres -d horilla -c "\dt"

# Recreate database
docker compose down postgres
docker volume rm hollacrm_postgres-data
docker compose up -d postgres
```

### Network Issues
```bash
# Test Tailscale connectivity
tailscale ping 100.96.0.1

# Restart Tailscale
docker compose restart tailscaled

# Check Docker networks
docker network ls
docker network inspect hollacrm_horilla_net
```

---

## 📊 Health Monitoring Commands

### Real-time Monitoring
```bash
# Container status
watch -n 2 'docker compose ps'

# Resource usage
watch -n 5 'docker stats --no-stream'

# Log monitoring
docker compose logs -f --tail=100

# System resources
htop
df -h
free -h
```

### Health Checks
```bash
# Application health
curl -f http://100.x.x.x/api/health/ || echo "API Down"

# Database health
docker compose exec postgres pg_isready -U postgres || echo "DB Down"

# Nginx health
curl -f http://100.x.x.x/health || echo "Frontend Down"

# Tailscale status
tailscale status
```

---

## 🚨 Emergency Procedures

### System Crash Recovery
```bash
# 1. Force stop everything
docker compose down --force

# 2. Check system resources
df -h
docker system df

# 3. Remove corrupted data if needed
docker system prune -af
docker volume prune -f

# 4. Restart cleanly
docker compose up -d

# 5. Monitor startup
docker compose logs -f
```

### Data Recovery
```bash
# Backup current data
docker compose exec postgres pg_dump -U postgres horilla > backup.sql

# Restore from backup
docker compose exec -T postgres psql -U postgres horilla < backup.sql

# Check backup integrity
docker compose exec postgres pg_dump -U postgres horilla | head
```

### Security Incident Response
```bash
# Check for unauthorized access
docker compose logs horilla | grep -i "unauthorized\|forbidden\|error"

# Rotate secrets
nano .env
docker compose down
docker compose up -d

# Update system
docker compose pull
docker compose up -d --force-recreate
```

---

## 📋 Daily Maintenance Checklist

```bash
# Morning Check
docker compose ps                    # Check services
docker compose logs --tail=20        # Check for errors
df -h                                # Check disk space
docker system df                     # Check Docker space

# During Day
docker stats --no-stream            # Monitor resources
git pull origin main                # Update code
docker compose pull                 # Update images

# End of Day
docker compose logs --tail=100 > daily-logs.txt  # Archive logs
docker system prune -f               # Clean up
```

---

## 🎯 Pro Tips

1. **Always test in a staging environment before production**
2. **Never commit secrets to Git - use environment variables**
3. **Regularly backup your database and configuration**
4. **Monitor resource usage to prevent issues**
5. **Keep dependencies updated regularly**
6. **Use meaningful commit messages**
7. **Test your backup and restore procedures**
8. **Document any custom configurations**
9. **Enable monitoring and alerting**
10. **Regular security scans and updates**