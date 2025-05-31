# Catch2 - Unit Testing Framework
include(FetchContent)
set(CATCH2_VERSION v2.13.10)
FetchContent_Declare(
  Catch2
  URL       https://github.com/catchorg/Catch2/archive/${CATCH2_VERSION}.tar.gz
  URL_HASH  SHA256=3d77741c4172f1d1a4d19f13571f8856d2dd90f4c0a79df3a8bfda9e38d9e801
)
FetchContent_MakeAvailable(Catch2)
if(CMAKE_BUILD_TYPE MATCHES Debug)
    include_directories(SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/third-party/catch2-${CATCH2_VERSION}/include")
endif()
