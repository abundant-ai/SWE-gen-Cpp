FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeux/pugixml.git src && \
    cd src && \
    (git fetch --depth 1 origin 1514a3d4c95133714d03241531469aeb7b07daa5 || git fetch --depth 1 origin "+refs/pull/633/head:refs/remotes/origin/pr/633") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# No dependencies to install - pugixml is a header-only library
# Tests are compiled on-demand in test.sh

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# Some Windows files (.vcxproj) may fail to patch due to line endings, which is OK for Linux testing
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --ignore-whitespace --reject-file=- < /tmp/bug.patch || true && rm /tmp/bug.patch

# No rebuild needed - tests are compiled in test.sh

RUN rm -rf /app/src/.git

WORKDIR /app/src
