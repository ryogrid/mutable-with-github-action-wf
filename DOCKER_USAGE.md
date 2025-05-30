# mutable-with-github-action-wf ビルド・テスト用Dockerイメージ利用ガイド

このドキュメントは、提供された `Dockerfile` によって作成されるDockerイメージを使用して、`mutable-with-github-action-wf` プロジェクトのビルドとユニットテストを実行する方法について説明します。

## 前提条件

-   Dockerがシステムにインストールされていること。
-   `mutable-with-github-action-wf` リポジトリがローカルマシンにクローンされていること。

    ```bash
    git clone https://github.com/ryogrid/mutable-with-github-action-wf.git
    cd mutable-with-github-action-wf
    ```

## 提供されるファイル

リポジトリのルートに以下のファイルを配置してください:
-   `Dockerfile`: Dockerイメージを定義します。
-   `entrypoint.sh`: コンテナ起動時に実行されるスクリプトです。C++およびRubyコンポーネントのビルド、ユニットテストの実行、結果の出力を処理します。
-   `USAGE.md`: この利用ガイドファイルです。

## Dockerイメージのビルド

クローンしたリポジトリのルートディレクトリ（`Dockerfile` がある場所）に移動し、以下のコマンドを実行します:

```bash
docker build -t mutable-dev .```

これによりDockerイメージがビルドされ、`mutable-dev` というタグが付けられます。

## コンテナの実行

イメージがビルドされたら、それからコンテナを実行できます。以下のコマンドは次の処理を行います:
-   現在のディレクトリ（プロジェクトのソースコード）をコンテナ内の `/app` にマウントします。
-   コンテナをデタッチモード (`-d`) で実行します。
-   コンテナに `mutable-container` という名前を付け、参照しやすくします。

```bash
docker run -d -v "$(pwd):/app" --name mutable-container mutable-dev
