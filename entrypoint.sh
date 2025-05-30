#!/bin/bash
# コマンドが非ゼロステータスで終了した場合、直ちにスクリプトを終了
set -e

# CMakeLists.txt の Catch2 FetchContent 設定をパッチする
echo "Patching CMakeLists.txt for Catch2 FetchContent..."
if [ -f CMakeLists.txt ]; then
    # 元のファイルのバックアップを作成
    if [ -f CMakeLists.txt.orig-entrypoint-backup ]; then
        cp CMakeLists.txt.orig-entrypoint-backup CMakeLists.txt
    else
        cp CMakeLists.txt CMakeLists.txt.orig-entrypoint-backup
    fi
    
    # より確実なパッチ方法：pythonまたはperlを使用
    # pythonが利用可能かチェック
    if command -v python3 >/dev/null 2>&1; then
        python3 << 'EOF'
import re

with open('CMakeLists.txt', 'r') as f:
    content = f.read()

# FetchContent_Declare(catch2 のブロックを見つけて置換
pattern = r'(FetchContent_Declare\s*\(\s*catch2\s+)(GIT_REPOSITORY\s+https://github\.com/catchorg/Catch2\.git\s+)(GIT_TAG\s+v3\.4\.0[^\n]*\s+)?(GIT_SHALLOW\s+TRUE\s+)?'
replacement = r'\1URL https://github.com/catchorg/Catch2/archive/refs/tags/v3.4.0.tar.gz\n    URL_HASH MD5=0e9367cfe53621c8669af73e34a8c556\n    '

content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

with open('CMakeLists.txt', 'w') as f:
    f.write(content)
EOF
        echo "Python使用でCMakeLists.txtをパッチしました。"
    else
        # pythonが使用できない場合はawkを使用
        awk '
        BEGIN { in_catch2_block = 0; block_closed = 0 }
        /FetchContent_Declare\s*\(\s*catch2/ { 
            print $0
            print "    URL https://github.com/catchorg/Catch2/archive/refs/tags/v3.4.0.tar.gz"
            print "    URL_HASH MD5=0e9367cfe53621c8669af73e34a8c556"
            in_catch2_block = 1
            next
        }
        in_catch2_block && /^\s*\)/ {
            print $0
            in_catch2_block = 0
            block_closed = 1
            next
        }
        in_catch2_block && /GIT_REPOSITORY|GIT_TAG|GIT_SHALLOW/ {
            # これらの行をスキップ
            next
        }
        { print $0 }
        ' CMakeLists.txt > CMakeLists.txt.tmp && mv CMakeLists.txt.tmp CMakeLists.txt
        echo "AWK使用でCMakeLists.txtをパッチしました。"
    fi
    
    echo "パッチ後の内容を確認中..."
    echo "--- Catch2 FetchContent セクション ---"
    grep -A 10 -B 2 "FetchContent_Declare.*catch2" CMakeLists.txt || echo "FetchContent_Declare(catch2) が見つかりませんでした"
    echo "--- パッチ確認終了 ---"
else
    echo "WARNING: CMakeLists.txt not found in /app. Skipping patch for Catch2."
fi

# 以下は元のスクリプトと同じ...
OUTPUT_DIR="/app"
CPP_BUILD_DIR="build/debug_shared"
CPP_TEST_RESULTS_FILE="${OUTPUT_DIR}/cpp_test_results.txt"

echo "C++ ビルドとテストプロセスを開始します..."
echo "ソースコードは /app にマウントされていることを想定しています"

echo "以前のビルドディレクトリ (${CPP_BUILD_DIR}) をクリーンアップしています..."
rm -rf "${CPP_BUILD_DIR}"

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
