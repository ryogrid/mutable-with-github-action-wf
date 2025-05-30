# ベースイメージとしてUbuntu 22.04 を使用
FROM ubuntu:22.04

# 環境変数を設定 (noninteractiveモードでのパッケージインストールのため)
ENV DEBIAN_FRONTEND=noninteractive

RUN wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 18
RUN export PATH=/usr/lib/llvm-18/bin:$PATH
RUN apt-get update && apt-get install -y ninja-build libboost-dev libgtest-dev libtbb-dev libfmt-dev

# Google Testのビルドとインストール
# libgtest-dev はソースファイルのみをインストールするため、コンパイルが必要
RUN cd /usr/src/googletest && \
    cmake CMakeLists.txt && \
    make && \
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
