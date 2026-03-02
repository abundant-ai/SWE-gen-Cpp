FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake and ninja-build for building C++ tests
# Install GCC 12 to avoid compilation issues with GCC 13.3
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    gcc-12 \
    g++-12 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-12 100 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 200015cb0e764dabb75922ff7ddb0ddd466439dd || git fetch --depth 1 origin "+refs/pull/2963/head:refs/remotes/origin/pr/2963") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure the project and tests using CMake with C++17 (std::filesystem::path requires C++17)
RUN cmake -S . -B build -G Ninja -DJSON_BuildTests=ON -DCMAKE_CXX_STANDARD=17

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
