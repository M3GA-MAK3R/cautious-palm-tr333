#!/bin/bash

echo "🚀 Starting HollaCRM deployment..."

# 1. Start stack
echo "📦 Starting Docker containers..."
docker compose up -d

echo "⏳ Waiting for services to be ready..."
docker compose logs -f &
LOGS_PID=$!

# Wait for healthy state
echo "⏱️ Waiting for services to become healthy..."
timeout 300 bash -c 'until docker compose ps --format json | jq -r ".[].Health" | grep -q "healthy"; do sleep 5; done'

if [ $? -eq 0 ]; then
    echo "✅ All services are healthy!"
else
    echo "❌ Services failed to become healthy within 5 minutes"
    docker compose logs
    exit 1
fi

# Stop following logs
kill $LOGS_PID 2>/dev/null || true

# 2. Superuser + test data
echo "👤 Creating superuser..."
docker exec -it horilla bash -c "
    python manage.py shell << 'EOF'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@easyhr.com', 'admin123')
    print('✅ Superuser created: admin/admin123')
else:
    print('ℹ️ Superuser already exists')
EOF
"

echo "📊 Creating demo data..."
docker exec -i horilla python manage.py shell < demo_data.py

# 3. Test Tailscale access
echo "🔗 Testing Tailscale access..."
TAILNET_IP=$(tailscale ip -4)
if [ -z "$TAILNET_IP" ]; then
    echo "⚠️ Tailscale not configured, using localhost for testing"
    TEST_URL="http://localhost/api/employees/"
else
    TEST_URL="http://${TAILNET_IP}/api/employees/"
fi

echo "Testing API endpoint: $TEST_URL"

# Get auth token
echo "🔑 Getting authentication token..."
AUTH_TOKEN=$(docker exec horilla python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'horilla.settings')
django.setup()
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.get(username='admin')
token, created = Token.objects.get_or_create(user=user)
print(token.key)
")

echo "Auth Token: $AUTH_TOKEN"

# Test API endpoint
echo "🌐 Testing API access..."
curl -H "Authorization: Token $AUTH_TOKEN" \
     -H "Content-Type: application/json" \
     "$TEST_URL" || {
    echo "❌ API test failed"
    echo "📋 Container status:"
    docker compose ps
    echo "📋 Recent logs:"
    docker compose logs --tail=50 horilla
    exit 1
}

echo "✅ API test successful!"
echo ""
echo "🎉 HollaCRM deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "   Admin URL: http://${TAILNET_IP:-localhost}/admin/"
echo "   API URL:   http://${TAILNET_IP:-localhost}/api/"
echo "   Username:  admin"
echo "   Password:  admin123"
echo ""
echo "🔧 Management Commands:"
echo "   View logs:    docker compose logs -f"
echo "   Stop stack:   docker compose down"
echo "   Restart:      docker compose restart"
echo ""
echo "📊 Demo Data Created:"
echo "   - 5 Employees with different departments"
echo "   - Leave requests for each employee"
echo "   - Sample payroll data"
echo "   - Performance records"