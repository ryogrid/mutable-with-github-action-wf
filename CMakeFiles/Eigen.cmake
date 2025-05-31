# Eigen - Template Library for Linear Algebra: Matrices, Vectors, Numerical Solvers, and related Algorithms
include(FetchContent)
set(EIGEN_VERSION 3.4.0)
set(EIGEN_URL "https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.gz")
set(EIGEN_SHA256 50948203f2ad7b0c3c3d218bd5af046ccb0fa879df6f3ae3d70092fb9fb2e3e8)

FetchContent_Declare(
  eigen
  URL       ${EIGEN_URL}
  URL_HASH  SHA256=${EIGEN_SHA256}
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third-party/eigen-${EIGEN_VERSION}"
  SYSTEM
  EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable(eigen)
include_directories(SYSTEM "${eigen_SOURCE_DIR}")
