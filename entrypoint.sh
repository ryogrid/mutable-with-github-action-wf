#!/bin/bash
# コマンドが非ゼロステータスで終了した場合、直ちにスクリプトを終了
set -e

# CMakeFiles/Catch2.cmake の設定をパッチする
echo "Patching CMakeFiles/Catch2.cmake for Catch2 FetchContent..."
if [ -f "CMakeFiles/Catch2.cmake" ]; then
    # 元のファイルのバックアップを作成 (コンテナ内でのみ有効)
    # コンテナが再実行されるたびに元の状態からパッチできるように、
    # .orig-entrypoint-backup が存在する場合はそれをリストアする
    if [ -f "CMakeFiles/Catch2.cmake.orig-entrypoint-backup" ]; then
        cp "CMakeFiles/Catch2.cmake.orig-entrypoint-backup" "CMakeFiles/Catch2.cmake"
    else
        cp "CMakeFiles/Catch2.cmake" "CMakeFiles/Catch2.cmake.orig-entrypoint-backup"
    fi
    
    # Python を使用して正確にパッチを適用
    python3 << 'EOF'
import re

# ファイルを読み込み
with open('CMakeFiles/Catch2.cmake', 'r') as f:
    content = f.read()

# FetchContent_Populate のブロックを見つけて修正
# SYSTEM パラメータを削除して、URL_HASH が正しく設定されるようにする
pattern = r'(FetchContent_Populate\s*\(\s*Catch2\s+URL\s+"[^"]+"\s+URL_HASH\s+MD5=[a-f0-9]+\s+SOURCE_DIR\s+"[^"]+"\s+DOWNLOAD_NO_EXTRACT\s+TRUE\s+)SYSTEM(\s+EXCLUDE_FROM_ALL\s*\))'

replacement = r'\1\2'

# パターンマッチングと置換
new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)

# もし上記のパターンが機能しない場合の代替方法
if new_content == content:
    # より簡単な方法：SYSTEM 行を削除
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        # SYSTEM だけの行をスキップ
        if line.strip() == 'SYSTEM':
            continue
        new_lines.append(line)
    new_content = '\n'.join(new_lines)

# ファイルに書き戻し
with open('CMakeFiles/Catch2.cmake', 'w') as f:
    f.write(new_content)

print("Catch2.cmake の SYSTEM パラメータを削除しました。")
EOF
    
    echo "CMakeFiles/Catch2.cmake patched for Catch2."
    echo "パッチ後の内容を確認中..."
    echo "--- CMakeFiles/Catch2.cmake パッチ後の内容 ---"
    cat "CMakeFiles/Catch2.cmake"
    echo "--- パッチ確認終了 ---"
else
    echo "WARNING: CMakeFiles/Catch2.cmake not found in /app. Skipping patch for Catch2."
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
