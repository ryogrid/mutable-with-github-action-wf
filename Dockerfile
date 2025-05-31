FROM ghcr.io/catthehacker/ubuntu:act-22.04

SHELL ["/bin/bash", "-c"]
WORKDIR /opt

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=clang
ENV CXX=clang++

RUN git clone -b docker-file2 https://github.com/ryogrid/mutable-with-github-action-wf.git mutable
RUN cd mutable
RUN wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 18
ENV PATH="/usr/lib/llvm-18/bin:$PATH"
RUN wget https://cmake.org/files/v3.21/cmake-3.21.0-linux-x86_64.sh
RUN /bin/bash cmake-3.21.0-linux-x86_64.sh --skip-license
RUN ln -s /opt/bin/* /usr/bin
RUN apt-get update && \
    apt-get install -y \
    ninja-build \
    libboost-dev \
    libtbb-dev \
    libfmt-dev \
    python3-pip \
    libssl-dev
RUN git clone https://github.com/pyenv/pyenv.git .pyenv
ENV PYENV_ROOT="/opt/.pyenv"
ENV PATH="/opt/.pyenv/bin:$PATH"
RUN eval "$(/opt/.pyenv/bin/pyenv init -)"
RUN cp -r /usr/include/openssl /usr/lib/ssl/
RUN CC=gcc /opt/.pyenv/bin/pyenv install -v 3.10.17

RUN /opt/.pyenv/bin/pyenv global 3.10.17
RUN pip install pipenv

# copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# make entrypoint.sh executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# set entrypoint of the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# docker build -t mutable-dev .
# docker run -it --rm --name mutable-container mutable-dev