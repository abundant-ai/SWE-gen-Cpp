FROM ubuntu:24.04

# Base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    wget \
    && rm -rf /var/lib/apt/lists/*

# No additional language runtime needed - pugixml is a C++ header-only library

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeux/pugixml.git src && \
    cd src && \
    (git fetch --depth 1 origin 3860b5076fd650e8cb0e7378675b241ec96b2e41 || git fetch --depth 1 origin "+refs/pull/170/head:refs/remotes/origin/pr/170") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Disable post-build test auto-run to prevent build failures from test issues
COPY disable_autotest.patch /tmp/disable_autotest.patch
RUN git apply /tmp/disable_autotest.patch && rm /tmp/disable_autotest.patch

# Remove flaky document_load_file_special_folder test that fails in Docker environment
RUN sed -i '/^TEST(document_load_file_special_folder)/,/^}/d' tests/test_document.cpp

# Build the test suite using cmake
RUN cmake . -DBUILD_TESTS=ON && \
    make -j$(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN git apply --whitespace=fix /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch since this is compiled C++
# First, disable post-build test auto-run again (CMakeLists.txt was restored by git reset)
COPY disable_autotest.patch /tmp/disable_autotest.patch
RUN git apply /tmp/disable_autotest.patch && rm /tmp/disable_autotest.patch

# Remove flaky test again (it was restored by git reset)
RUN sed -i '/^TEST(document_load_file_special_folder)/,/^}/d' tests/test_document.cpp

RUN rm -rf CMakeCache.txt CMakeFiles check && \
    cmake . -DBUILD_TESTS=ON && \
    make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
