FROM node:20-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # version control & hosting
        git \
        gh \
        # search & navigation
        ripgrep \
        fd-find \
        # data & network
        curl \
        wget \
        jq \
        # build toolchain (needed for native npm modules)
        make \
        build-essential \
        python3 \
        python3-pip \
        # archive handling
        unzip \
        zip \
        # shell utilities
        less \
        bash-completion \
        # process tools
        procps \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode CLI globally
RUN npm install -g opencode-ai

# Set a system-level git identity so git doesn't complain about missing config.
# Commits are blocked at the filesystem level (read-only .git mount) so this
# identity is never actually used.
RUN git config --system user.email "opencode@container.local" && \
    git config --system user.name "OpenCode Container"

# Create a non-root user matching the host user's UID/GID so bind-mounted
# files with restrictive permissions are readable.
ARG UID=1000
ARG GID=1000
RUN userdel -r node && \
    groupadd -g ${GID} opencode && \
    useradd -m -u ${UID} -g ${GID} -d /home/opencode opencode && \
    mkdir -p /workspace && chown opencode:opencode /workspace

USER opencode

WORKDIR /workspace
