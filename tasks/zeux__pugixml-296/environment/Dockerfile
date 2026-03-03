FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# No additional language runtime needed - pugixml is a C++ header-only library

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/zeux/pugixml.git src && \
    cd src && \
    (git fetch --depth 1 origin 2af02a59d41fbce0e5afb448f6d417530c8d2087 || git fetch --depth 1 origin "+refs/pull/296/head:refs/remotes/origin/pr/296") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build the test suite using Makefile with C++17 and PUGIXML_STRING_VIEW to enable string_view support
# Disable some warnings as errors (newer gcc version issues)
RUN sed -i 's/CXXFLAGS=-g -Wall -Wextra -Werror/CXXFLAGS=-g -Wall -Wextra -Werror -Wno-error=implicit-fallthrough -Wno-error=expansion-to-defined -Wno-error=self-move/' Makefile && \
    make cxxstd=c++17 defines=PUGIXML_STRING_VIEW -j$(nproc)

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN git apply --whitespace=fix /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch since this is compiled C++
# Re-apply the compiler warning fixes and build with C++17 and PUGIXML_STRING_VIEW
RUN sed -i 's/CXXFLAGS=-g -Wall -Wextra -Werror/CXXFLAGS=-g -Wall -Wextra -Werror -Wno-error=implicit-fallthrough -Wno-error=expansion-to-defined -Wno-error=self-move/' Makefile && \
    make clean && make cxxstd=c++17 defines=PUGIXML_STRING_VIEW -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
