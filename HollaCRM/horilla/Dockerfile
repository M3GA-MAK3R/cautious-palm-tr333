FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gettext \
    curl \
    gnupg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r horilla && useradd -r -g horilla horilla

# Set work directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Create necessary directories
RUN mkdir -p /app/logs /app/media /app/static && \
    chown -R horilla:horilla /app

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to non-root user
USER horilla

# Collect static files (will be done in entrypoint)
RUN python manage.py collectstatic --noinput --dry-run || true

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health/ || exit 1

# Use gunicorn as production server
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["gunicorn", "--config", "gunicorn.conf.py", "horilla.wsgi:application"]