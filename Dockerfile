FROM wholerengroup/gitlab-runner:11.10.1

SHELL ["/bin/bash", "-c"]
WORKDIR /build

ENV DEBIAN_FRONTEND=noninteractive
ENV CC=clang
ENV CXX=clang++

RUN git clone -b docker-file https://github.com/ryogrid/mutable-with-github-action-wf.git mutable
RUN cd mutable
RUN apt-get update && \
    apt-get install -y \
    lsb_release
RUN wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 18
RUN export PATH="/usr/lib/llvm-18/bin:$PATH"
RUN apt-get update && \
    apt-get install -y \
    ninja-build \
    libboost-dev \
    libtbb-dev \
    libfmt-dev \
    python3-pip \    
    libssl-dev
RUN git clone https://github.com/pyenv/pyenv.git .pyenv
ENV PYENV_ROOT="/build/.pyenv"
ENV PATH="/build/.pyenv/bin:$PATH"
RUN eval "$(/build/.pyenv/bin/pyenv init -)"
RUN cp -r /usr/include/openssl /usr/lib/ssl/
RUN CC=gcc /build/.pyenv/bin/pyenv install -v 3.10.17

RUN /build/.pyenv/bin/pyenv global 3.10.17
RUN pip install pipenv

# copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# make entrypoint.sh executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# set entrypoint of the container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# docker build -t mutable-dev .
# docker run -it --rm --name mutable-container mutable-dev