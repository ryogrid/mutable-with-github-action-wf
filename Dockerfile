# ベースイメージとしてUbuntu 22.04 を使用
FROM ubuntu:22.04

# 環境変数を設定 (noninteractiveモードでのパッケージインストールのため)
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget lsb-release software-properties-common gnupg 
RUN wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 18
RUN export PATH=/usr/lib/llvm-18/bin:$PATH
RUN apt-get update && apt-get install -y ninja-build libboost-dev libgtest-dev libtbb-dev libfmt-dev cmake git

RUN export CMAKE_CXX_COMPILER=/usr/lib/llvm-18/bin/clang++
# Google Testのビルドとインストール
# libgtest-dev はソースファイルのみをインストールするため、コンパイルが必要
RUN cd /usr/src/googletest && \
    CXX=/usr/lib/llvm-18/bin/clang cmake CMakeLists.txt && \
    CXX=/usr/lib/llvm-18/bin/clang make && \
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
