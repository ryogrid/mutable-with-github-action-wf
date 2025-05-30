# ベースイメージとしてUbuntu 22.04 を使用
FROM ubuntu:22.04

# 環境変数を設定 (noninteractiveモードでのパッケージインストールのため)
ENV DEBIAN_FRONTEND=noninteractive

# 依存パッケージのインストール (C++ビルドツール)
RUN apt-get update && \
    apt-get install -y \
    g++ \
    make \
    cmake \
    libgtest-dev \
    # ユーザー指定のビルド要件に対応するパッケージを追加
    clang \
    ninja-build \
    libnode-dev \  # Node.js開発ファイル (V8ヘッダ/ライブラリを含むことが多い)
    # aptキャッシュのクリーンアップ
    && rm -rf /var/lib/apt/lists/*

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
