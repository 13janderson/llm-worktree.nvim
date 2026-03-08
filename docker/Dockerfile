FROM node:20-alpine

RUN apk add --no-cache git bash

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Set a system-level git identity so git doesn't complain about missing config.
# Commits are blocked at the filesystem level (read-only .git mount) so this
# identity is never actually used.
RUN git config --system user.email "claude@container.local" && \
    git config --system user.name "Claude Container"

# Create a non-root user matching the host user's UID/GID so bind-mounted
# files with restrictive permissions (e.g. ~/.claude.json) are readable.
ARG UID=1000
ARG GID=1000
RUN deluser node && \
    addgroup -g ${GID} claude && \
    adduser -D -u ${UID} -G claude -h /home/claude claude && \
    mkdir -p /workspace && chown claude:claude /workspace

USER claude

WORKDIR /workspace
