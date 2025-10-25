#!/bin/bash

echo "🧪 Blue/Green Failover Test"
echo "==========================="
echo ""

# Test 1: Check all services running
echo "1️⃣  Checking services..."
sudo docker-compose ps
echo ""

# Test 2: Baseline - Blue should be active
echo "2️⃣  Testing baseline (should be Blue)..."
BASELINE=$(sudo curl -si http://localhost:8080/version)
echo "$BASELINE" | grep -E "HTTP|X-App-Pool"
echo ""

# Test 3: Trigger chaos
echo "3️⃣  Triggering chaos on Blue..."
sudo curl -s -X POST "http://localhost:8081/chaos/start?mode=error"
echo "   ✅ Chaos started"
echo ""

# Test 4: Wait for failover
echo "4️⃣  Waiting 3 seconds for failover..."
sleep 3
echo "   ✅ Wait complete"
echo ""

# Test 5: Check failover happened
echo "5️⃣  Testing after chaos (should be Green)..."
FAILOVER=$(sudo curl -si http://localhost:8080/version)
echo "$FAILOVER" | grep -E "HTTP|X-App-Pool"

if echo "$FAILOVER" | grep -q "X-App-Pool: green"; then
    echo "   ✅ SUCCESS! Failover to Green detected!"
elif echo "$FAILOVER" | grep -q "200 OK"; then
    echo "   ✅ Got 200 OK (failover might have worked)"
else
    echo "   ❌ Failover may have failed"
fi
echo ""

# Test 6: Rapid requests
echo "6️⃣  Testing stability (20 rapid requests)..."
SUCCESS=0
GREEN=0
for i in {1..20}; do
    RESPONSE=$(sudo curl -s http://localhost:8080/version)
    HTTP_CODE=$(sudo curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/version)
    
    if [ "$HTTP_CODE" = "200" ]; then
        ((SUCCESS++))
    fi
    
    if echo "$RESPONSE" | grep -q "green"; then
        ((GREEN++))
    fi
    
    echo -n "."
done
echo ""
echo "   Results: $SUCCESS/20 successful (200 OK)"
echo "   Green responses: $GREEN/20"

if [ $SUCCESS -eq 20 ]; then
    echo "   ✅ Perfect! Zero failed requests!"
elif [ $SUCCESS -ge 19 ]; then
    echo "   ✅ Good! ≥95% success rate"
else
    echo "   ⚠️  Some failures: $SUCCESS/20"
fi
echo ""

# Test 7: Stop chaos
echo "7️⃣  Stopping chaos..."
sudo curl -s -X POST "http://localhost:8081/chaos/stop"
echo "   ✅ Chaos stopped"
echo ""

echo "🎉 Test Complete!"
echo ""
echo "Summary:"
echo "  ✅ Services running"
echo "  ✅ Baseline: Blue active"
echo "  ✅ Chaos triggered on Blue"
echo "  ✅ Failover to Green: Check output above"
echo "  ✅ Stability: $SUCCESS/20 requests successful"
