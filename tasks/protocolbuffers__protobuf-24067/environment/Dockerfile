FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install PHP 8.1+ (required by composer.json)
RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-xml \
    php-mbstring \
    php-bcmath \
    php-curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3 (required for Bazel)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Java 11 (required by Bazel)
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk (manages Bazel versions automatically)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.24.1/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# Install Composer (PHP package manager)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/protocolbuffers/protobuf.git src && \
    cd src && \
    (git fetch --depth 1 origin 69efbc67c5a7aac7b2d66d88796895319af799d3 || git fetch --depth 1 origin "+refs/pull/24067/head:refs/remotes/origin/pr/24067") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Pin Bazel version to 7.6.1 (version used by protobuf CI)
RUN echo "7.6.1" > .bazelversion

# Bazel needs these env vars for reproducible builds
ENV CI=true

# Install PHP dependencies via Composer (ignore security advisories for old PHPUnit versions)
RUN cd php && composer config audit.ignore PKSA-z3gr-8qht-p93v PKSA-w57n-mhp6-c9sd && composer update && composer install

# Generate test protos (required for tests)
RUN cd php && ./generate_test_protos.sh

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Regenerate test protos after applying bug.patch
RUN cd php && ./generate_test_protos.sh

RUN rm -rf /app/src/.git

WORKDIR /app/src
