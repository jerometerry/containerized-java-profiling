#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

trap 'echo "--> Cleaning up container..."; docker rm -f spring-perf-test >/dev/null 2>&1' EXIT

echo "==========================================="
echo " Local Async-Profiler Execution Sandbox    "
echo "==========================================="

echo "--> Starting container 'spring-perf-test'..."
docker run -d --name spring-perf-test -p 8080:8080 spring-boot-perf-repo >/dev/null

echo "--> Waiting for JVM and Spring Boot to start (10s)..."
sleep 10

echo "--> Running CPU Profile (15s)..."
docker exec -d spring-perf-test /opt/async-profiler/bin/asprof -e itimer -d 15 -f /app/profiles/cpu-flame.html 1
curl -s "http://localhost:8080/api/load/cpu?seconds=15" >/dev/null

echo "--> Giving JVM a moment to write the CPU Flame Graph..."
sleep 2

echo "--> Running Memory Profile (15s)..."
docker exec -d spring-perf-test /opt/async-profiler/bin/asprof -e alloc -d 15 -f /app/profiles/alloc-flame.html 1
curl -s "http://localhost:8080/api/load/memory?seconds=15" >/dev/null

echo "--> Giving JVM a moment to write the Memory Flame Graph..."
sleep 2

echo "--> Extracting profiles to the observability/ directory..."
docker cp spring-perf-test:/app/profiles/cpu-flame.html "$SCRIPT_DIR/cpu-flame.html"
docker cp spring-perf-test:/app/profiles/alloc-flame.html "$SCRIPT_DIR/alloc-flame.html"

echo "==========================================="
echo " Success! Output files saved to:           "
echo " - observability/cpu-flame.html            "
echo " - observability/alloc-flame.html          "
echo "==========================================="