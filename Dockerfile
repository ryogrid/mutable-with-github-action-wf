FROM ghcr.io/catthehacker/ubuntu:act-22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=clang
ENV CXX=clang++

RUN git clone -b docker-file https://github.com/ryogrid/mutable-with-github-action-wf.git mutable
RUN cd mutable
RUN wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 18
RUN export PATH=/usr/lib/llvm-18/bin:$PATH
RUN apt-get update && \
    apt-get install -y \
    ninja-build \
    libboost-dev \
    libtbb-dev \
    libfmt-dev \
    python3-pip \
    libssl-dev
RUN git clone 
RUN git clone https://github.com/pyenv/pyenv.git .pyenv
RUN export PYENV_ROOT="$(pwd)/.pyenv"
RUN export PATH="$PYENV_ROOT/bin:$PATH"
RUN eval "$(pyenv init -)"
RUN cp -r /usr/include/openssl /usr/lib/ssl/
RUN export PATH=/usr/lib/x86_64-linux-gnu:$PATH
RUN pyenv install -v 3.10.17

RUN REV=$(git rev-parse --short HEAD)
RUN BRANCH=$(git rev-parse --abbrev-ref HEAD)
RUN TAG=$(git describe --tags --always --dirty)
RUN cat > include/mutable/gitversion.tbl <<'EOF'
    constexpr const char GIT_REV[]      = "${REV}";
    constexpr const char GIT_BRANCH[]   = "${BRANCH}";
    constexpr const char SEM_VERSION[]  = "${TAG}";
    EOF
RUN pyenv global 3.10.17
RUN pip install pipenv

# copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# make entrypoint.sh executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# コンテナのentrypointを設定
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# docker build -t mutable-dev .
# docker run -it --rm --name mutable-container mutable-dev