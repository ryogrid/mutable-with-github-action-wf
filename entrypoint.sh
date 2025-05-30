#!/bin/bash
# コマンドが非ゼロステータスで終了した場合、直ちにスクリプトを終了
set -e

export PATH=/usr/lib/llvm-18/bin:$PATH

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
    -DWITH_V8=OFF \
    -DTHIRD_PARTY_BOOST=OFF \
    -DENABLE_SANITIZERS=OFF \
    -DMUTABLE_ENABLE_TESTS=ON \
    -DBUILD_TESTING=ON \
    -DCMAKE_BUILD_TYPE=Debug

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
