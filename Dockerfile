# ベースイメージとしてUbuntu 22.04 を使用
FROM ubuntu:22.04

# 環境変数を設定 (noninteractiveモードでのパッケージインストールのため)
ENV DEBIAN_FRONTEND=noninteractive

# 依存パッケージのインストール (C++ビルドツール)
# cmake は Kitware のリポジトリから最新版をインストールするため、ここでは一旦除外
RUN apt-get update && \
    apt-get install -y \
    g++ \
    make \
    libgtest-dev \
    clang \
    ninja-build \
    libnode-dev \
    git \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Install latest CMake from Kitware APT Repository
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    apt-get install -y cmake && \
    rm -rf /var/lib/apt/lists/*

# Google Testのビルドとインストール
# libgtest-dev はソースファイルのみをインストールするため、コンパイルが必要
RUN cd /usr/src/googletest && \
    cmake CMakeLists.txt && \
    make && \
    # コンパイルされたライブラリを標準的な場所にコピー
    cp lib/libgtest.a /usr/lib/ && \
    cp lib/libgtest_main.a /usr/lib/

# コンテナ内の作業ディレクトリを設定
WORKDIR /app

# entrypointスクリプトをコンテナにコピー
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# entrypointスクリプトに実行権限を付与
RUN chmod +x /usr/local/bin/entrypoint.sh

# コンテナのentrypointを設定
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
