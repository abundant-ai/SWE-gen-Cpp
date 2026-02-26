FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell Core for validating PowerShell script syntax
RUN wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeux/pugixml.git src && \
    cd src && \
    (git fetch --depth 1 origin 64de196ba9f250d734625b4ca3a6c2afd19ba2b6 || git fetch --depth 1 origin "+refs/pull/468/head:refs/remotes/origin/pr/468") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# No dependencies to install - pugixml is a header-only library
# PowerShell script validation is done in test.sh

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# Some Windows files (.vcxproj) may fail to patch due to line endings, which is OK for Linux testing
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --ignore-whitespace --reject-file=- < /tmp/bug.patch || true && rm /tmp/bug.patch

# No rebuild needed - we're validating PowerShell script syntax, not compiling

RUN rm -rf /app/src/.git

WORKDIR /app/src
