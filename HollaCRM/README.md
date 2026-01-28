# HollaCRM MVP Architecture

Production-ready HRM system built with Horilla + React + Tailscale CI/CD

## Architecture Overview

```
Tailscale Networks (isolated tailnets)
├── dev.tailnet (100.64.x.x)    ← CI/CD testing
├── staging.tailnet (100.80.x.x) ← QA  
└── prod.tailnet (100.96.x.x)   ← Customer deployments
       └── Multi-tenant Horilla sites
```

## Project Structure

```
HollaCRM/
├── docker-compose.yml           # Main orchestration
├── .env.example                 # Environment template
├── .github/workflows/           # CI/CD pipelines
│   ├── ci.yml                  # Testing and builds
│   ├── deploy-dev.yml          # Dev deployment
│   ├── deploy-staging.yml      # Staging deployment
│   └── deploy-prod.yml         # Production deployment
├── horilla/                    # Horilla backend
│   ├── Dockerfile
│   ├── requirements.txt
│   └── gunicorn.conf.py
├── react-dashboard/            # React frontend
│   ├── Dockerfile
│   ├── package.json
│   ├── src/
│   └── public/
├── monitoring/                 # Monitoring configs
│   ├── prometheus.yml
│   └── grafana/
├── init-scripts/              # Database initialization
│   └── init.sql
├── tailscale/                 # Tailscale configs
│   ├── ACLs.hcl
│   └── dns.config
└── docs/                      # Documentation
    ├── deployment.md
    └── security.md
```

## Quick Start

1. **Clone and setup**
```bash
git clone <repo-url>
cd HollaCRM
cp .env.example .env
# Edit .env with your secrets
```

2. **Tailscale Setup**
```bash
# Generate auth keys for each environment
# Configure ACLs in tailscale/ACLs.hcl
# Add environment-specific IPs to .env
```

3. **Deploy**
```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Production  
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Security Features

- **Tailscale Isolation**: Separate tailnets for dev/staging/prod
- **Zero Trust Access**: Only authorized devices can access
- **TLS Everywhere**: Automatic SSL with Traefik + Let's Encrypt
- **RBAC**: Role-based access control in Horilla
- **Network Segmentation**: Docker networks per service

## CI/CD Pipeline

- **Automated Testing**: Unit, integration, security scans
- **Multi-Environment**: Deploy to dev → staging → production
- **Rollback Support**: Automatic rollback on failures
- **Monitoring**: Prometheus + Grafana dashboards

## Environment Variables

```bash
# Core
SECRET_KEY=your-secure-secret-key
POSTGRES_PASSWORD=secure-db-password
REDIS_PASSWORD=secure-redis-password

# Tailscale
TAILSCALE_AUTH_KEY=tskey-auth-xxxx
TAILSCALE_IP=100.96.x.x
ACME_EMAIL=admin@hollacrm.com

# Monitoring
GRAFANA_PASSWORD=secure-grafana-password
PROMETHEUS_RETENTION=200h
```

## Access URLs

- **React Dashboard**: https://{TAILSCALE_IP}.nip.io
- **Horilla API**: https://{TAILSCALE_IP}.nip.io/api/
- **Traefik Dashboard**: http://{TAILSCALE_IP}:8080
- **Grafana**: http://{TAILSCALE_IP}:3001

## Support

- 📧 admin@hollacrm.com
- 📖 docs/deployment.md
- 🔧 GitHub Issues