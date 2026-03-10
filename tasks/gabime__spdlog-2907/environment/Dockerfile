FROM ubuntu:24.04

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

RUN git clone https://github.com/gabime/spdlog.git src && \
    cd src && \
    (git fetch --depth 1 origin bb4fa46ac10dd30b221661f2db2884fc11bfe13e || git fetch --depth 1 origin "+refs/pull/2907/head:refs/remotes/origin/pr/2907") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN git reset --hard

COPY bug.patch /tmp/bug.patch
RUN patch -p1 --no-backup-if-mismatch --reject-file=- < /tmp/bug.patch || [ $? -eq 1 ] && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
