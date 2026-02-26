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
    (git fetch --depth 1 origin b789bb009cf54fd68b7776187f4f9fa7a5a024e6 || git fetch --depth 1 origin "+refs/pull/893/head:refs/remotes/origin/pr/893") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

ENV LANG=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8

WORKDIR /app/src

# Configure and build the project with tests enabled
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DYAML_BUILD_SHARED_LIBS=OFF

# Fix GoogleTest 1.10.0 compilation with modern GCC
# Remove -Werror flags from GoogleTest CMake cache
RUN sed -i 's/-Werror[^ ]*//g' build/test/prefix/googletest/CMakeFiles/gtest.dir/flags.make || true && \
    sed -i 's/-Werror[^ ]*//g' build/test/prefix/googletest/CMakeFiles/gtest_main.dir/flags.make || true

RUN cmake --build build --config Debug --parallel

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN (patch -p1 < /tmp/bug.patch || true) && rm /tmp/bug.patch

# Note: We don't rebuild here because the buggy code has compilation errors.
# The test.sh script will rebuild after applying fix.patch (for oracle agent).

RUN rm -rf /app/src/.git

WORKDIR /app/src
