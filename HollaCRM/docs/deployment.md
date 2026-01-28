# Deployment Guide for HollaCRM

This guide covers deployment of the HollaCRM HRM system across development, staging, and production environments using Tailscale for secure networking.

## Prerequisites

### Infrastructure Requirements
- Ubuntu 22.04 LTS servers (minimum 2GB RAM, 1 CPU core)
- Docker & Docker Compose installed
- Tailscale installed on all servers
- GitHub repository access

### Tailscale Setup
1. Create separate tailnets for each environment:
   - `dev.tailnet` (100.64.x.x)
   - `staging.tailnet` (100.80.x.x) 
   - `prod.tailnet` (100.96.x.x)

2. Configure ACLs in `tailscale/ACLs.hcl`

3. Generate auth keys for each environment:
   ```bash
   tailscale authkeys create --tags=tag:hollacrm-dev --reusable --ephemeral
   tailscale authkeys create --tags=tag:hollacrm-staging --reusable --ephemeral
   tailscale authkeys create --tags=tag:hollacrm-prod --reusable --ephemeral
   ```

## Environment Setup

### 1. Development Environment

**Server Configuration:**
```bash
# On dev server
sudo apt update && sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
sudo systemctl enable docker

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=tskey-auth-dev-xxxx --tag=tag:hollacrm-dev
```

**Deployment:**
```bash
git clone https://github.com/your-org/hollacrm.git
cd hollacrm

# Copy environment template and configure
cp .env.example .env
# Edit .env with your development secrets

# Deploy development stack
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Initialize database
docker-compose exec horilla python manage.py migrate
docker-compose exec horilla python manage.py createsuperuser
```

### 2. Staging Environment

**Server Configuration:**
```bash
# Similar to dev but with staging auth key
sudo tailscale up --authkey=tskey-auth-staging-xxxx --tag=tag:hollacrm-staging
```

**Deployment:**
```bash
git clone https://github.com/your-org/hollacrm.git
cd hollacrm

# Configure staging environment
cp .env.example .env
# Configure with staging secrets and tailscale IP (100.80.x.x)

# Deploy staging stack
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

### 3. Production Environment

**Server Configuration:**
```bash
# Production server setup
sudo tailscale up --authkey=tskey-auth-prod-xxxx --tag=tag:hollacrm-prod

# Harden system
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow from 100.96.0.0/16
```

**Deployment:**
```bash
git clone https://github.com/your-org/hollacrm.git
cd hollacrm

# Configure production environment
cp .env.example .env
# Configure with production secrets
# Generate strong passwords
# Configure SSL certificates

# Deploy production stack
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Setup SSL certificates
docker-compose exec traefik certificates
```

## CI/CD Pipeline Setup

### GitHub Secrets Configuration
Add the following secrets to your GitHub repository:

```yaml
Tailscale Auth Keys:
  TAILSCALE_DEV_AUTHKEY: tskey-auth-dev-xxxx
  TAILSCALE_STAGING_AUTHKEY: tskey-auth-staging-xxxx  
  TAILSCALE_PROD_AUTHKEY: tskey-auth-prod-xxxx

SSH Keys:
  DEV_SSH_KEY: -----BEGIN OPENSSH PRIVATE KEY-----
  STAGING_SSH_KEY: -----BEGIN OPENSSH PRIVATE KEY-----
  PROD_SSH_KEY: -----BEGIN OPENSSH PRIVATE KEY-----

Database Passwords:
  DEV_POSTGRES_PASSWORD: secure-dev-password
  STAGING_POSTGRES_PASSWORD: secure-staging-password
  PROD_POSTGRES_PASSWORD: secure-prod-password

Other Secrets:
  SLACK_WEBHOOK_URL: https://hooks.slack.com/services/xxxx
  DEPLOYMENT_TRACKER_URL: https://your-tracker.com/deployments
```

### Workflow Triggers
- **Development**: Push to `develop` branch
- **Staging**: Pull request to `main` branch
- **Production**: Manual trigger from GitHub Actions

## Security Configuration

### 1. Firewall Rules
```bash
# Ubuntu UFW configuration
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 100.96.0.0/16 to any port 443
sudo ufw allow from 100.80.0.0/16 to any port 443
sudo ufw allow from 100.64.0.0/16 to any port 443
```

### 2. SSL/TLS Configuration
- Automatic SSL via Traefik + Let's Encrypt
- HSTS headers enabled in production
- Security headers configured in nginx

### 3. Database Security
- Strong passwords
- Encrypted connections
- Regular backups
- Access logging

### 4. Application Security
- Django security middleware enabled
- CSRF protection
- Rate limiting
- Session security

## Monitoring and Logging

### 1. Prometheus + Grafana
Access monitoring dashboards:
- Grafana: `https://{TAILSCALE_IP}:3001`
- Prometheus: `https://{TAILSCALE_IP}:9090`

### 2. Log Aggregation
- Application logs: `/app/logs/`
- Nginx logs: `/var/log/nginx/`
- Docker logs: `docker-compose logs`

### 3. Health Checks
Built-in health checks for:
- Application: `/api/health/`
- Database: PostgreSQL health check
- Redis: Redis ping
- Frontend: `/health`

## Backup Strategy

### 1. Database Backups
- Daily automated backups
- Encrypted storage
- S3 upload option
- 30-day retention

### 2. Configuration Backups
- Docker Compose files in Git
- Environment variables in secure storage
- SSL certificates backed up

## Rollback Procedure

### Quick Rollback
```bash
# Rollback to previous image tag
docker-compose pull horilla:previous-tag
docker-compose up -d --no-deps horilla
```

### Full Rollback
```bash
# Rollback to previous deployment
git checkout previous-commit
docker-compose down
docker-compose up -d
```

## Troubleshooting

### Common Issues

1. **Tailscale Connection Issues**
   ```bash
   # Check Tailscale status
   sudo tailscale status
   
   # Restart Tailscale
   sudo systemctl restart tailscaled
   ```

2. **Database Connection Issues**
   ```bash
   # Check database logs
   docker-compose logs postgres
   
   # Test connection
   docker-compose exec postgres psql -U horilla -d horilla_prod
   ```

3. **Application Issues**
   ```bash
   # Check application logs
   docker-compose logs horilla
   
   # Restart application
   docker-compose restart horilla
   ```

### Performance Optimization

1. **Database Optimization**
   - Connection pooling
   - Query optimization
   - Regular vacuuming

2. **Application Optimization**
   - Redis caching
   - Static file compression
   - CDN integration

## Maintenance

### Regular Tasks
- Update dependencies
- Rotate secrets
- Review security logs
- Update SSL certificates
- Test backups

### Updates
```bash
# Update application
git pull origin main
docker-compose pull
docker-compose up -d

# Update system
sudo apt update && sudo apt upgrade -y
```

## Support

- **Documentation**: `/docs/`
- **Issues**: GitHub Issues
- **Emergency**: admin@hollacrm.com
- **Monitoring**: Slack alerts