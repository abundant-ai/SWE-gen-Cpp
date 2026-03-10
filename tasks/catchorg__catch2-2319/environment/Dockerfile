FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ compiler (Clang), CMake, and Python (needed for tests)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/catchorg/Catch2.git src && \
    cd src && \
    (git fetch --depth 1 origin 96630f0cb0f261c5da768aed7756758ef4acd2db || git fetch --depth 1 origin "+refs/pull/2319/head:refs/remotes/origin/pr/2319") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Use Clang as the C++ compiler
ENV CC=clang
ENV CXX=clang++
ENV CXXFLAGS="-Wno-error=deprecated-literal-operator -Wno-error=unused-but-set-variable"

# Fix missing cstdint includes - add to all relevant source/header files
RUN find src/catch2 -type f \( -name "*.cpp" -o -name "*.hpp" \) \
    -exec grep -l "uint\(8\|16\|32\|64\)_t" {} \; | \
    xargs -I {} sh -c 'grep -q "#include <cstdint>" {} || sed -i "7i #include <cstdint>" {}'

# Configure and build Catch2 with CMake
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-literal-operator -Wno-error=unused-but-set-variable" \
    -G Ninja

# Fix MINSIGSTKSZ constexpr issue with newer glibc - hardcode a safe value
RUN find . \( -name "*.cpp" -o -name "*.hpp" \) -type f -exec grep -l "sigStackSize.*MINSIGSTKSZ" {} \; | \
    xargs sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static constexpr std::size_t sigStackSize = 131072;/g' || true

# Build Catch2
RUN cmake --build build

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Fix missing cstdint includes again (undone by git reset and patch)
RUN find src/catch2 -type f \( -name "*.cpp" -o -name "*.hpp" \) \
    -exec grep -l "uint\(8\|16\|32\|64\)_t" {} \; | \
    xargs -I {} sh -c 'grep -q "#include <cstdint>" {} || sed -i "7i #include <cstdint>" {}'

# Fix MINSIGSTKSZ constexpr issue again (undone by git reset)
RUN find . \( -name "*.cpp" -o -name "*.hpp" \) -type f -exec grep -l "sigStackSize.*MINSIGSTKSZ" {} \; | \
    xargs sed -i 's/static constexpr std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/static constexpr std::size_t sigStackSize = 131072;/g' || true

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build

RUN rm -rf /app/src/.git

WORKDIR /app/src
