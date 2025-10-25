#!/bin/sh
set -e

# Replace ${ACTIVE_POOL} with "blue" or "green"
envsubst '${ACTIVE_POOL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Test the config is valid
nginx -t

# Start Nginx
exec nginx -g 'daemon off;'
