FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional system packages needed for yaml-cpp
RUN apt-get update && apt-get install -y \
    cmake \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locales for testing (de_DE uses comma as decimal separator)
RUN locale-gen de_DE.UTF-8

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin 66c18d5ecf3094ab1730015f10f6c6ffce21e324 || git fetch --depth 1 origin "+refs/pull/582/head:refs/remotes/origin/pr/582") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

# Configure the build (but don't build yet - the code at HEAD has compilation issues)
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DYAML_BUILD_SHARED_LIBS=OFF

# Note: We skip building here because HEAD has the 'less' const bug that prevents compilation
# The bug.patch will remove depthguard files, which also breaks compilation
# The test.sh script will build after applying fix.patch (for oracle agent)

# Fix the 'less' const issue that prevents compilation
# This is needed because PR #582 was created before PR #846 was merged
RUN sed -i 's/bool operator ()(const node\* l, const node\* r) {/bool operator ()(const node* l, const node* r) const {/' include/yaml-cpp/node/detail/node.h

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN (patch -p1 < /tmp/bug.patch || true) && rm /tmp/bug.patch

# Note: We don't rebuild here because the buggy code has compilation errors (missing depthguard).
# The test.sh script will rebuild after applying fix.patch (for oracle agent).

RUN rm -rf /app/src/.git

WORKDIR /app/src
