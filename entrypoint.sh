#!/bin/bash

# コマンドが非ゼロステータスで終了した場合、直ちにスクリプトを終了
set -e

# CMakeLists.txt の Catch2 FetchContent 設定をパッチする
echo "Patching CMakeLists.txt for Catch2 FetchContent..."
if [ -f CMakeLists.txt ]; then
    # 元のファイルのバックアップを作成 (コンテナ内でのみ有効)
    # コンテナが再実行されるたびに元の状態からパッチできるように、
    # .orig-entrypoint-backup が存在する場合はそれをリストアする
    if [ -f CMakeLists.txt.orig-entrypoint-backup ]; then
        cp CMakeLists.txt.orig-entrypoint-backup CMakeLists.txt
    else
        cp CMakeLists.txt CMakeLists.txt.orig-entrypoint-backup
    fi

    # sed を使用して FetchContent_Declare(catch2 ...) の内容を書き換える
    # 各コマンドを個別の -e オプションで指定し、正規表現内のドットをエスケープする
    # CMakeLists.txt 内のインデント（スペースの数）に正確に一致させること
    sed -i \
        -e 's|^    GIT_REPOSITORY https://github\.com/catchorg/Catch2\.git$|    URL https://github.com/catchorg/Catch2/archive/refs/tags/v3.4.0.tar.gz|g' \
        -e 's|^    GIT_TAG        v3\.4\.0.*$|    URL_HASH MD5=0e9367cfe53621c8669af73e34a8c556|g' \
        -e '/^    GIT_SHALLOW    TRUE$/d' \
        CMakeLists.txt

    echo "CMakeLists.txt patched for Catch2."
else
    echo "WARNING: CMakeLists.txt not found in /app. Skipping patch for Catch2."
fi

# テスト結果の出力先ディレクトリ (マウントされたボリュームのルート)
OUTPUT_DIR="/app"
CPP_BUILD_DIR="build/debug_shared" # ビルドディレクトリの指定
CPP_TEST_RESULTS_FILE="${OUTPUT_DIR}/cpp_test_results.txt"

echo "C++ ビルドとテストプロセスを開始します..."
echo "ソースコードは /app にマウントされていることを想定しています"

# 以前のビルドディレクトリをクリーンアップ
echo "以前のビルドディレクトリ (${CPP_BUILD_DIR}) をクリーンアップしています..."
rm -rf "${CPP_BUILD_DIR}"

# C++ ビルド
echo "CMakeを使用してC++プロジェクトを設定しています..."
cmake -S . -B "${CPP_BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_SANITIZERS=OFF \
    -DENABLE_SANITY_FIELDS=OFF \
    -DWITH_V8=OFF \
    -DTHIRD_PARTY_BOOST=OFF

echo "Ninja (cmake --build経由) を使用してC++プロジェクトをビルドしています..."
cmake --build "${CPP_BUILD_DIR}"

# C++ ユニットテスト
echo "C++ユニットテストを実行しています..."
CPP_UNIT_TEST_EXECUTABLE="./${CPP_BUILD_DIR}/test/unit_test"
if [ -f "${CPP_UNIT_TEST_EXECUTABLE}" ]; then
    "${CPP_UNIT_TEST_EXECUTABLE}" > "${CPP_TEST_RESULTS_FILE}" 2>&1
    if [ $? -eq 0 ]; then
        echo "C++ユニットテストが成功しました。結果は ${CPP_TEST_RESULTS_FILE} に保存されました。"
    else
        echo "C++ユニットテストが失敗したか、エラーが発生しました。結果は ${CPP_TEST_RESULTS_FILE} に保存されました。"
    fi
else
    echo "${CPP_UNIT_TEST_EXECUTABLE} にC++ユニットテスト実行ファイルが見つかりませんでした。C++テストをスキップします。" > "${CPP_TEST_RESULTS_FILE}"
fi

echo "-----------------------------------------------------"
echo "C++ビルドとテストの実行が完了しました。"
echo "C++テスト結果: ${CPP_TEST_RESULTS_FILE} (コンテナ内、マウントされていればホスト上にも)"
echo "コンテナは起動し続けます。Ctrl+C で停止してください。"
echo "コンテナ内のシェルにアクセスするには (別のターミナルから): docker exec -it <コンテナ名> bash"
echo "-----------------------------------------------------"

tail -f /dev/null
