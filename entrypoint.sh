#!/bin/bash

# コマンドが非ゼロステータスで終了した場合、直ちにスクリプトを終了
set -e

# テスト結果の出力先ディレクトリ (マウントされたボリュームのルート)
OUTPUT_DIR="/app"
CPP_BUILD_DIR="build/debug_shared" # ビルドディレクトリの指定
CPP_TEST_RESULTS_FILE="${OUTPUT_DIR}/cpp_test_results.txt"

echo "C++ ビルドとテストプロセスを開始します..."
echo "ソースコードは /app にマウントされていることを想定しています"

# (オプション) 以前のビルドアーティファクトが存在する場合にクリーンアップ
echo "以前のビルドディレクトリ (${CPP_BUILD_DIR}) をクリーンアップしています..."
rm -rf "${CPP_BUILD_DIR}" # 指定されたビルドディレクトリを削除

# C++ ビルド
echo "CMakeを使用してC++プロジェクトを設定しています..."
# ユーザー指定のCMakeオプションで設定
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
CPP_UNIT_TEST_EXECUTABLE="./${CPP_BUILD_DIR}/test/unit_test" # テスト実行ファイルのパスを更新
if [ -f "${CPP_UNIT_TEST_EXECUTABLE}" ]; then
    # テストを実行し、標準出力と標準エラー出力を結果ファイルにリダイレクト
    # テストが失敗した場合でもスクリプトを継続したい場合は '|| true' を追加できますが、
    # C++テストのみなので、失敗時はスクリプトが終了する方が適切かもしれません。
    # ここではひとまずエラーで終了するようにします。
    "${CPP_UNIT_TEST_EXECUTABLE}" > "${CPP_TEST_RESULTS_FILE}" 2>&1
    # 直前のコマンドの終了ステータスを確認
    if [ $? -eq 0 ]; then
        echo "C++ユニットテストが成功しました。結果は ${CPP_TEST_RESULTS_FILE} に保存されました。"
    else
        echo "C++ユニットテストが失敗したか、エラーが発生しました。結果は ${CPP_TEST_RESULTS_FILE} に保存されました。"
        # ユニットテスト失敗時にコンテナを終了させたくない場合は、以下のexitをコメントアウトし、
        # スクリプト末尾の tail -f /dev/null が実行されるようにする
        # exit 1 # 失敗を示す終了コード
    fi
else
    echo "${CPP_UNIT_TEST_EXECUTABLE} にC++ユニットテスト実行ファイルが見つかりませんでした。C++テストをスキップします。" > "${CPP_TEST_RESULTS_FILE}"
    # 実行ファイルが見つからない場合もエラーとして扱う場合は exit 1 を追加
    # exit 1
fi

echo "-----------------------------------------------------"
echo "C++ビルドとテストの実行が完了しました。"
echo "C++テスト結果: ${CPP_TEST_RESULTS_FILE} (コンテナ内、マウントされていればホスト上にも)"
echo "コンテナは起動し続けます。停止するには: docker stop <コンテナ名>"
echo "コンテナ内のシェルにアクセスするには: docker exec -it <コンテナ名> bash"
echo "-----------------------------------------------------"

# コンテナを無期限に起動し続ける
tail -f /dev/null
