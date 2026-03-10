FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (required for building spdlog tests)
RUN apt-get update && apt-get install -y \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin d5aa8db36f977b6ba90003c13a9475eccdc80033 || git fetch --depth 1 origin "+refs/pull/1580/head:refs/remotes/origin/pr/1580") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --no-backup-if-mismatch --reject-file=- < /tmp/bug.patch || [ $? -eq 1 ] && rm /tmp/bug.patch

# Fix MINSIGSTKSZ compilation issue with Catch 2.8.0 on modern GCC
RUN sed -i '9041s/.*/    static constexpr std::size_t sigStackSize = 32768;/' tests/catch.hpp && \
    sed -i '9100s/.*/    char FatalConditionHandler::altStackMem[32768] = {};/' tests/catch.hpp

RUN rm -rf /app/src/.git

WORKDIR /app/src
