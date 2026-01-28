# Gunicorn configuration file
import os
import multiprocessing

# Server socket
bind = "0.0.0.0:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Max requests per worker to prevent memory leaks
max_requests = 1000
max_requests_jitter = 100

# Logging
accesslog = "/app/logs/access.log"
errorlog = "/app/logs/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "horilla"

# Server mechanics
daemon = False
pidfile = "/tmp/horilla.pid"
user = "horilla"
group = "horilla"
tmp_upload_dir = None

# SSL (if needed)
# keyfile = "/path/to/keyfile"
# certfile = "/path/to/certfile"

# Preload application for better performance
preload_app = True

# Graceful shutdown timeout
graceful_timeout = 30

# Worker process memory limit (in MB)
memory_limit = 1024

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Performance tuning
worker_tmp_dir = "/dev/shm"

# Monitoring
statsd_host = os.environ.get("STATSD_HOST", "localhost")
statsd_prefix = os.environ.get("STATSD_PREFIX", "horilla")

# Health check endpoint
def when_ready(server):
    server.log.info("Server is ready. Listening on %s", server.address)

def worker_int(worker):
    worker.log.info("Worker received INT or QUIT signal")
    import sys
    sys.exit(0)

# Custom hooks for monitoring
def post_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)

def worker_exit(server, worker):
    server.log.info("Worker exiting (pid: %s)", worker.pid)