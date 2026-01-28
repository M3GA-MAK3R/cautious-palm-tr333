#!/bin/bash

# Backup script for HollaCRM production database
# This script runs daily and creates encrypted backups

set -euo pipefail

# Configuration
BACKUP_DIR="/backups"
RETENTION_DAYS=30
DB_HOST="postgres"
DB_NAME="horilla_prod"
DB_USER="horilla"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/hollacrm_backup_${TIMESTAMP}.sql"
ENCRYPTED_FILE="${BACKUP_FILE}.enc"
LOG_FILE="${BACKUP_DIR}/backup.log"

# S3 configuration (optional)
S3_BUCKET=${S3_BUCKET:-""}
S3_PREFIX="hollacrm-backups"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send notifications
notify() {
    local status=$1
    local message=$2
    
    # Send to Slack if webhook is configured
    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        curl -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-type: application/json' \
            --data "{\"text\":\"Backup $status: $message\"}" || true
    fi
    
    # Send email if configured
    if [[ -n "${EMAIL_RECIPIENTS:-}" && -n "${EMAIL_SUBJECT:-}" ]]; then
        echo "$message" | mail -s "Backup $status: $EMAIL_SUBJECT" "$EMAIL_RECIPIENTS" || true
    fi
}

# Start backup process
log "Starting backup process..."

# Check if database is accessible
if ! pg_isready -h "$DB_HOST" -U "$DB_USER"; then
    error_msg="Database is not accessible"
    log "$error_msg"
    notify "FAILED" "$error_msg"
    exit 1
fi

# Create database backup
log "Creating database backup..."
if ! pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" --no-password --verbose --format=custom --compress=9 > "$BACKUP_FILE"; then
    error_msg="Database backup failed"
    log "$error_msg"
    notify "FAILED" "$error_msg"
    exit 1
fi

# Verify backup file was created and has content
if [[ ! -f "$BACKUP_FILE" || ! -s "$BACKUP_FILE" ]]; then
    error_msg="Backup file is empty or missing"
    log "$error_msg"
    notify "FAILED" "$error_msg"
    exit 1
fi

# Encrypt backup if encryption key is provided
if [[ -n "${ENCRYPTION_KEY:-}" ]]; then
    log "Encrypting backup..."
    if ! openssl enc -aes-256-cbc -salt -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE" -k "$ENCRYPTION_KEY"; then
        error_msg="Backup encryption failed"
        log "$error_msg"
        notify "FAILED" "$error_msg"
        exit 1
    fi
    
    # Remove unencrypted backup
    rm "$BACKUP_FILE"
    BACKUP_FILE="$ENCRYPTED_FILE"
fi

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log "Backup created successfully: $BACKUP_FILE (Size: $BACKUP_SIZE)"

# Upload to S3 if configured
if [[ -n "$S3_BUCKET" ]]; then
    log "Uploading backup to S3..."
    if ! aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$S3_PREFIX/$(basename "$BACKUP_FILE")"; then
        error_msg="S3 upload failed"
        log "$error_msg"
        notify "FAILED" "$error_msg"
        exit 1
    fi
    log "S3 upload completed"
fi

# Clean up old backups
log "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "hollacrm_backup_*.sql*" -type f -mtime +$RETENTION_DAYS -delete || true

# Clean up old S3 backups if configured
if [[ -n "$S3_BUCKET" ]]; then
    log "Cleaning up old S3 backups..."
    aws s3 ls "s3://$S3_BUCKET/$S3_PREFIX/" --recursive | \
        awk '$1 < "'"$(date -d "$RETENTION_DAYS days ago" '+%Y-%m-%d')"'" {print $4}' | \
        xargs -I {} aws s3 rm "s3://$S3_BUCKET/{}" || true
fi

# Verify backup integrity
log "Verifying backup integrity..."
if [[ "$BACKUP_FILE" == *.enc ]]; then
    # Test encrypted backup
    if ! openssl enc -aes-256-cbc -d -in "$BACKUP_FILE" -k "$ENCRYPTION_KEY" | head -c 100 > /dev/null; then
        error_msg="Backup integrity check failed"
        log "$error_msg"
        notify "FAILED" "$error_msg"
        exit 1
    fi
else
    # Test unencrypted backup
    if ! pg_restore --list "$BACKUP_FILE" > /dev/null 2>&1; then
        error_msg="Backup integrity check failed"
        log "$error_msg"
        notify "FAILED" "$error_msg"
        exit 1
    fi
fi

# Backup completed successfully
success_msg="Backup completed successfully: $BACKUP_FILE (Size: $BACKUP_SIZE)"
log "$success_msg"
notify "SUCCESS" "$success_msg"

# Cleanup
rm -f "$BACKUP_FILE" 2>/dev/null || true

log "Backup process completed"
exit 0