FROM node:20-alpine

RUN apk add --no-cache git bash

# Install OpenCode CLI globally
RUN npm install -g opencode-ai

# Set a system-level git identity so git doesn't complain about missing config.
# Commits are blocked at the filesystem level (read-only .git mount) so this
# identity is never actually used.
RUN git config --system user.email "opencode@container.local" && \
    git config --system user.name "OpenCode Container"

# Allow OpenCode to perform any action within the container
ENV OPENCODE_PERMISSION='{"*":"allow"}'

# Create a non-root user matching the host user's UID/GID so bind-mounted
# files with restrictive permissions are readable.
ARG UID=1000
ARG GID=1000
RUN deluser node && \
    addgroup -g ${GID} opencode && \
    adduser -D -u ${UID} -G opencode -h /home/opencode opencode && \
    mkdir -p /workspace && chown opencode:opencode /workspace

USER opencode

WORKDIR /workspace
