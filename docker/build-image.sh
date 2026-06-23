#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================="
echo " Building Async-Profiler Image Pipeline"
echo "======================================="

echo "--> 1. Staging async-profiler tools..."
cd "$SCRIPT_DIR"
./build-async-profiler.sh

echo "--> 2. Compiling Spring Boot API..."
cd "$ROOT_DIR/spring-boot-app"
./build.sh

echo "--> 3. Building Docker Image (Context: Project Root)..."
# Move to the root of the repository
cd "$ROOT_DIR"

# -f tells Docker where the file is. The '.' at the end tells Docker to
# use the current directory ($ROOT_DIR) as the build context.
docker build -f docker/Dockerfile -t spring-boot-perf-repo .

echo "======================================="
echo " Build Complete!                       "
echo "======================================="