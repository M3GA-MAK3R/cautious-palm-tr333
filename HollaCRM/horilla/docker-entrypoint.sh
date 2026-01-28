#!/bin/bash
set -e

# Default values
if [ -z "$DJANGO_SETTINGS_MODULE" ]; then
    export DJANGO_SETTINGS_MODULE=horilla.settings
fi

# Wait for database to be ready
if [ "$DATABASE_URL" ]; then
    echo "Waiting for database to be ready..."
    
    # Extract database host from DATABASE_URL
    DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    
    # Wait for database
    timeout=60
    while ! nc -z $DB_HOST 5432; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "Database connection timeout"
            exit 1
        fi
        echo "Waiting for database... $timeout seconds remaining"
        sleep 1
    done
    echo "Database is ready!"
fi

# Wait for Redis to be ready
if [ "$REDIS_URL" ]; then
    echo "Waiting for Redis to be ready..."
    
    # Extract Redis host from REDIS_URL
    REDIS_HOST=$(echo $REDIS_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    
    timeout=30
    while ! nc -z $REDIS_HOST 6379; do
        timeout=$((timeout - 1))
        if [ $timeout -eq 0 ]; then
            echo "Redis connection timeout"
            exit 1
        fi
        echo "Waiting for Redis... $timeout seconds remaining"
        sleep 1
    done
    echo "Redis is ready!"
fi

# Run database migrations
echo "Running database migrations..."
python manage.py migrate --noinput || {
    echo "Migration failed, attempting to continue..."
}

# Create superuser if not exists
echo "Creating superuser if needed..."
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@hollacrm.com', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
EOF

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput || {
    echo "Static file collection failed, attempting to continue..."
}

# Create default data if needed
echo "Creating default data..."
python manage.py shell << EOF
from django.core.management import call_command
try:
    call_command('loaddata', 'initial_data.json', verbosity=0)
    print('Initial data loaded')
except:
    print('No initial data file found or failed to load')
EOF

# Set correct permissions
echo "Setting permissions..."
chown -R horilla:horilla /app/media /app/static /app/logs 2>/dev/null || true

# Start the application
echo "Starting application..."
exec "$@"