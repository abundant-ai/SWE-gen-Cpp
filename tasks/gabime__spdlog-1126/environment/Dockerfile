FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python (required by Meson build system)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and Meson build tools
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install Meson via pip
RUN pip3 install --break-system-packages meson

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin 2a2a34601c316f540b1dd21d7ca36f613e10c783 || git fetch --depth 1 origin "+refs/pull/1126/head:refs/remotes/origin/pr/1126") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Reset any changes from build steps before applying bug.patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --no-backup-if-mismatch --reject-file=- < /tmp/bug.patch || [ $? -eq 1 ] && rm /tmp/bug.patch

# Fix MINSIGSTKSZ compilation issue with Catch 2.8.0 on modern GCC
RUN sed -i '9041s/.*/    static constexpr std::size_t sigStackSize = 32768;/' tests/catch.hpp && \
    sed -i '9100s/.*/    char FatalConditionHandler::altStackMem[32768] = {};/' tests/catch.hpp

RUN rm -rf /app/src/.git

WORKDIR /app/src
