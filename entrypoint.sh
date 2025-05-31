#!/bin/bash

cd mutable

export CC=clang
export CXX=clang++
export PYENV_ROOT="$(pwd)/.pyenv"
export PATH="/usr/lib/llvm-18/bin:/usr/lib/x86_64-linux-gnu:$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

cat > include/mutable/gitversion.tbl <<'EOF'
constexpr const char GIT_REV[]      = "${REV}";
constexpr const char GIT_BRANCH[]   = "${BRANCH}";
constexpr const char SEM_VERSION[]  = "${TAG}";
EOF

cmake -S . -B build -G Ninja -LAH \
    -DWITH_V8=OFF \
    -DTHIRD_PARTY_BOOST=OFF \
    -DENABLE_SANITIZERS=OFF \
    -DMUTABLE_ENABLE_TESTS=ON \
    -DBUILD_TESTING=ON \
    -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j 4

echo "start testing..."
cmake --build build --target check-unit
cmake --build build --target check-integration

echo "-----------------------------------------------------"
echo "container stop: docker stop mutable-container"
echo "access container internal environment: docker exec -it mutable-container bash"
echo "-----------------------------------------------------"

# container will keep running
tail -f /dev/null