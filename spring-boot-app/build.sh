#!/bin/bash

# Exit immediately if any command fails
set -e

echo "==========================================="
echo " Building Synthetic Load Spring Boot API   "
echo "==========================================="

# Ensure we are in the right directory
if [ ! -f "pom.xml" ]; then
    echo "Error: pom.xml not found."
    echo "Please run this script from the root of the project where pom.xml is located."
    exit 1
fi

# Strategy 1: Use local Maven if available
if command -v mvn >/dev/null 2>&1; then
    echo "Local Maven installation detected. Compiling..."
    mvn clean package -DskipTests

# Strategy 2: Fall back to a Dockerized Maven build
elif command -v docker >/dev/null 2>&1; then
    echo "Maven not found locally. Falling back to Docker..."
    echo "Pulling maven:3.9-eclipse-temurin-21 and compiling..."

    # Mounts the current directory into the container and runs the build
    docker run -it --rm \
        -v "$PWD":/usr/src/app \
        -w /usr/src/app \
        maven:3.9-eclipse-temurin-21 \
        mvn clean package -DskipTests

# Failure: Neither tool is available
else
    echo "Error: Neither 'mvn' (Maven) nor 'docker' is installed or in your PATH."
    echo "You need at least one of these tools to compile the application."
    exit 1
fi

echo "==========================================="
echo " Build Complete!                           "
echo " JAR location: target/synthetic-load-api-0.0.1-SNAPSHOT.jar"
echo "==========================================="