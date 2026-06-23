#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================="
echo " Building Async-Profiler Image Pipeline"
echo "======================================="

echo "Building async-profiler..."
cd "$SCRIPT_DIR"
./build-async-profiler.sh

echo "Compiling Spring Boot Synthetic Workload App..."
cd "$ROOT_DIR/spring-boot-app"
./build.sh

echo "Building Spring Boot Docker Image with Async Profiler..."
cd "$ROOT_DIR"

docker build -f docker/Dockerfile -t spring-boot-perf-repo .

echo "======================================="
echo " Build Complete!                       "
echo "======================================="