# Blue/Green Deployment with Nginx

## Quick Start

1. Start: `docker-compose up -d`
2. Test: `curl http://localhost:8080/version`
3. Trigger failure: `curl -X POST http://localhost:8081/chaos/start?mode=error`
4. Verify switch: `curl http://localhost:8080/version`

## Ports

- 8080: Main entry (Nginx)
- 8081: Blue direct access
- 8082: Green direct access
Blue/Green Deployment with Nginx Auto-Failover
This project implements a Blue/Green deployment strategy for Node.js services using Nginx as a reverse proxy with automatic failover capabilities.
🎯 Features

Automatic Failover: Nginx automatically switches to the backup instance when the primary fails
Zero Downtime: Failed requests are retried on the backup instance within the same client request
Health Monitoring: Built-in health checks for both instances
Chaos Testing: Endpoints to simulate downtime and test failover
Configurable: Fully parameterized via environment variables

📋 Prerequisites

Docker & Docker Compose installed
Ports 8080, 8081, 8082 available on your machine

🚀 Quick Start
1. Clone the repository
bashgit clone <your-repo-url>
cd <your-repo-name>
2. Configure environment variables
Copy the example environment file:
bashcp .env.example .env
Edit .env to customize your deployment (optional):
envBLUE_IMAGE=ghcr.io/hngprojects/coolkeedsfrontend-stg2:blue
GREEN_IMAGE=ghcr.io/hngprojects/coolkeedsfrontend-stg2:green
ACTIVE_POOL=blue
RELEASE_ID_BLUE=blue-v1.0.0
RELEASE_ID_GREEN=green-v1.0.0
PORT=3000
3. Start the services
bashdocker-compose up -d
4. Verify the deployment
Check that all services are running:
bashdocker-compose ps
Test the main endpoint:
bashcurl -i http://localhost:8080/version
Expected response headers:
X-App-Pool: blue
X-Release-Id: blue-v1.0.0
🧪 Testing Failover
Test Automatic Failover

Trigger chaos on Blue instance:

bashcurl -X POST http://localhost:8081/chaos/start?mode=error

Send requests through Nginx:

bash# This should return 200 with green headers
curl -i http://localhost:8080/version
Expected response headers after failover:
X-App-Pool: green
X-Release-Id: green-v1.0.0

Stop chaos:

bashcurl -X POST http://localhost:8081/chaos/stop
Test with Timeout Mode
bash# Trigger timeout simulation
curl -X POST http://localhost:8081/chaos/start?mode=timeout

# Test through Nginx
curl -i http://localhost:8080/version

# Stop chaos
curl -X POST http://localhost:8081/chaos/stop
🔄 Switching Active Pool
To manually switch the active pool:

Update .env:

envACTIVE_POOL=green

Restart nginx:

bashdocker-compose restart nginx
📊 Available Endpoints
Through Nginx (Port 8080)

GET http://localhost:8080/version - Get version info with pool and release headers
All other app endpoints are proxied through Nginx

Direct Instance Access

Blue Instance (Port 8081):

GET http://localhost:8081/version
GET http://localhost:8081/healthz
POST http://localhost:8081/chaos/start?mode=error|timeout
POST http://localhost:8081/chaos/stop


Green Instance (Port 8082):

Same endpoints as Blue, but on port 8082



🏗️ Architecture
Client Request
      ↓
[Nginx :8080]
      ↓
   Upstream
      ↓
   ┌──────────────┐
   │ Primary      │  (ACTIVE_POOL)
   │ app_blue     │  max_fails=1, fail_timeout=5s
   │ :8081        │
   └──────────────┘
   ┌──────────────┐
   │ Backup       │
   │ app_green    │  (marked as backup)
   │ :8082        │
   └──────────────┘
⚙️ Configuration Details
Nginx Failover Settings

Timeout: 2s for connect, send, and read operations
Max Fails: 1 failure marks the server as down
Fail Timeout: 5s before retrying a failed server
Retry Policy: Retries on error, timeout, and HTTP 5xx responses
Next Upstream Tries: 2 attempts maximum
Next Upstream Timeout: 5s maximum for all retry attempts

Health Check Settings
Both instances have health checks configured:

Interval: 5s
Timeout: 2s
Retries: 3
Start Period: 10s

🛑 Stopping the Services
bashdocker-compose down
To remove volumes as well:
bashdocker-compose down -v
🐛 Troubleshooting
Services not starting
bash# Check logs
docker-compose logs

# Check specific service
docker-compose logs nginx
docker-compose logs app_blue
Ports already in use
Edit .env or docker-compose.yml to use different ports.
Failover not working

Verify Nginx configuration: docker-compose exec nginx nginx -t
Check Nginx logs: docker-compose logs nginx
Ensure both instances are healthy: docker-compose ps

📝 Environment Variables
VariableDescriptionDefaultRequiredBLUE_IMAGEDocker image for Blue instance-YesGREEN_IMAGEDocker image for Green instance-YesACTIVE_POOLActive pool (blue or green)blueYesRELEASE_ID_BLUERelease ID for Blue instance-YesRELEASE_ID_GREENRelease ID for Green instance-YesPORTApplication port3000No
🎯 Success Criteria
✅ Normal state: all traffic goes to Blue
✅ On Blue failure: automatic switch to Green with zero failed requests
✅ Headers forwarded unchanged from application
✅ Failover happens within tight timeouts (<5s)
✅ No non-200 responses during failover window
✅ ≥95% responses from Green after Blue fails
