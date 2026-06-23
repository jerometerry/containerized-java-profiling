#!/bin/bash
set -e

ASYNC_PROFILER_VERSION="3.0"

TARGETARCH=${1:-arm64}

if [ "$TARGETARCH" = "amd64" ] || [ "$TARGETARCH" = "x86_64" ]; then
    ARCH="x64"
elif [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    echo "Error: Unsupported architecture: $TARGETARCH"
    exit 1
fi

echo "Staging async-profiler v${ASYNC_PROFILER_VERSION} for ${ARCH}..."

ARTIFACT_DIR="$PWD/profiler-artifacts"
mkdir -p "$ARTIFACT_DIR"

# Capture the host user's UID/GID to fix ownership after the Docker run
HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker run --rm \
    -v "$ARTIFACT_DIR:/output" \
    alpine:latest \
    sh -c "
        echo 'Installing wget and tar in temporary container...' && \
        apk add --no-cache wget tar >/dev/null 2>&1 && \

        echo 'Downloading binary...' && \
        wget -qO /tmp/profiler.tar.gz \"https://github.com/async-profiler/async-profiler/releases/download/v${ASYNC_PROFILER_VERSION}/async-profiler-${ASYNC_PROFILER_VERSION}-linux-${ARCH}.tar.gz\" && \

        echo 'Extracting to mounted volume...' && \
        mkdir -p /output/async-profiler && \
        tar -xzf /tmp/profiler.tar.gz -C /output/async-profiler --strip-components=1 && \

        echo 'Fixing file ownership for the host machine...' && \
        chown -R ${HOST_UID}:${HOST_GID} /output/async-profiler
    "

echo "Success! async-profiler staged locally at ./profiler-artifacts/async-profiler"
