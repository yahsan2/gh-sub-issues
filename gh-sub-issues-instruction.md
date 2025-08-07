# 🧠 GitHub CLI Extension `gh-sub-issues` 開発・公開ガイド

## 🎯 概要

GitHub CLI にサブ課題（Sub-issue）管理機能を追加する拡張機能。親子関係を持つIssueの階層的な管理を可能にし、プロジェクトのタスク管理を効率化する。

## ✨ 主要機能

- **サブ課題の作成**: 親Issueに紐づくサブ課題を簡単に作成
- **既存Issueのリンク**: 既存のIssueを親Issueのサブ課題として追加
- **サブ課題の一覧表示**: 親Issueに関連するすべてのサブ課題を階層的に表示
- **柔軟な出力形式**: TTY、非TTY、JSON形式に対応

---

## 🛠 コマンド仕様

### 1. `gh sub-issues create`

#### 概要
親Issueに紐づくサブ課題を作成する。

#### オプション

| フラグ | エイリアス | 説明 | 必須 |
|-------|----------|------|------|
| `--parent` | `-P` | 親IssueのURL または 番号 | ✅ |
| `--title` | `-t` | サブ課題のタイトル | ✅ |
| `--body` | `-b` | サブ課題の本文 | ❌ |
| `--label` | `-l` | ラベル（複数指定可） | ❌ |
| `--assignee` | `-a` | アサイン先（複数指定可） | ❌ |
| `--milestone` | `-m` | マイルストーン | ❌ |
| `--project` | `-p` | プロジェクト | ❌ |

#### 使用例

```bash
# Issue番号で親を指定
gh sub-issues create --parent 123 --title "APIエンドポイントの実装" --body "REST APIの/users エンドポイントを実装"

# URLで親を指定
gh sub-issues create -P https://github.com/owner/repo/issues/123 -t "テストケースの追加"

# 複数のラベルとアサイン
gh sub-issues create --parent 456 --title "ドキュメント更新" --label documentation,good-first-issue --assignee user1,user2
```

### 2. `gh sub-issues add` (または `gh issue add-sub`)

#### 概要
既存のIssueを親Issueのサブ課題として追加する。GitHub GraphQL API の `addSubIssue` mutation を使用。

#### 構文
```bash
gh sub-issues add <parent-issue> <sub-issue> [flags]
# または
gh issue add-sub <parent-issue> <sub-issue> [flags]
```

#### オプション

| フラグ | エイリアス | 説明 | デフォルト |
|-------|----------|------|----------|
| `--repo` | `-R` | リポジトリを指定 (OWNER/REPO形式) | 現在のリポジトリ |

#### 使用例

```bash
# 基本的な使用（Issue番号を指定）
gh sub-issues add 123 456
gh issue add-sub 123 456

# URLで親Issueを指定
gh sub-issues add https://github.com/owner/repo/issues/123 456

# 両方URLで指定
gh sub-issues add https://github.com/owner/repo/issues/123 https://github.com/owner/repo/issues/456

# 別のリポジトリを指定
gh sub-issues add 123 456 --repo owner/repo

# 実際の使用例（yahsan2/gh-cliでのテスト済み）
gh issue add-sub 1 2 --repo yahsan2/gh-cli
# 結果: ✓ Added issue #2 as a sub-issue of #1
```

#### 実装参考

既存の実装例（yahsan2/gh-cli フォーク）:
- コミット: [yahsan2@05f9f44ab](https://github.com/yahsan2/gh-cli/commit/05f9f44ab)
- 実装ファイル:
  - `pkg/cmd/issue/addsub/addsub.go` - メインコマンド実装
  - `pkg/cmd/issue/addsub/addsub_test.go` - ユニットテスト
  - `pkg/cmd/issue/issue.go` - 既存issueコマンドとの統合

### 3. `gh sub-issues list`

#### 概要
指定された親Issueに紐づくすべてのサブ課題を表示。

#### オプション

| フラグ | エイリアス | 説明 | デフォルト |
|-------|----------|------|----------|
| `--json` | | JSON形式で出力 | false |
| `--state` | `-s` | 状態でフィルタ (open/closed/all) | open |
| `--limit` | `-L` | 表示する最大件数 | 30 |
| `--web` | `-w` | ブラウザで開く | false |

#### 使用例

```bash
# 基本的な使用
gh sub-issues list 123

# URLで指定
gh sub-issues list https://github.com/owner/repo/issues/123

# JSON形式で出力（CI/CD向け）
gh sub-issues list 123 --json

# すべての状態のサブ課題を表示
gh sub-issues list 123 --state all --limit 50
```

#### 出力形式

**TTY環境（カラー付き）:**
```
Parent: #123 - Feature: User Authentication System

SUB-ISSUES (5 total, 3 open)
─────────────────────────────
✅ #124  Implement login API endpoint           [closed]
✅ #125  Add password hashing                   [closed]
🔵 #126  Create user session management         [open]   @john
🔵 #127  Add OAuth2 integration                 [open]   @jane
🔵 #128  Write authentication tests             [open]
```

**非TTY環境（タブ区切り）:**
```
124	closed	Implement login API endpoint
125	closed	Add password hashing
126	open	Create user session management	john
127	open	Add OAuth2 integration	jane
128	open	Write authentication tests
```

---

## 📁 プロジェクト構成

```
gh-sub-issues/
├── .github/
│   ├── workflows/
│   │   ├── test.yml          # テスト自動化
│   │   └── release.yml       # GoReleaserによるリリース自動化
│   └── ISSUE_TEMPLATE/
├── .goreleaser.yml            # GoReleaser設定ファイル（重要）
├── .gitignore                 # Git除外設定
├── README.md                  # ユーザー向けドキュメント
├── LICENSE                    # MITライセンス
├── go.mod                     # Go依存関係
├── go.sum                     # 依存関係のチェックサム
├── main.go                    # シンプルなエントリーポイント
├── cmd/
│   ├── root.go               # ルートコマンドとCobra設定
│   ├── create.go             # createサブコマンド実装
│   ├── add.go                # addサブコマンド実装
│   ├── list.go               # listサブコマンド実装
│   ├── version.go            # バージョン情報表示
│   ├── api_client.go         # GitHub API クライアント
│   ├── graphql.go            # GraphQL クエリと実行
│   ├── formatter.go          # 出力フォーマッター
│   ├── parser.go             # URL/Issue番号パーサー
│   └── utils.go              # 共通ユーティリティ
└── testdata/                  # テスト用フィクスチャ
    └── fixtures/              # テストデータ
```

---

## 🔧 実装詳細

### GraphQL クエリ仕様

#### 親Issue IDの取得
```graphql
query GetIssueId($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      id
      title
      state
    }
  }
}
```

#### サブ課題の作成
```graphql
mutation CreateSubIssue($repositoryId: ID!, $title: String!, $body: String, $parentId: ID!, $labelIds: [ID!], $assigneeIds: [ID!]) {
  createIssue(input: {
    repositoryId: $repositoryId,
    title: $title,
    body: $body,
    parentIssueId: $parentId,
    labelIds: $labelIds,
    assigneeIds: $assigneeIds
  }) {
    issue {
      id
      number
      url
      title
      state
    }
  }
}
```

#### 既存Issueをサブ課題として追加（addSubIssue mutation）
```graphql
mutation AddSubIssue($parentId: ID!, $subIssueId: ID!) {
  addSubIssue(input: {
    issueId: $parentId,
    subIssueId: $subIssueId
  }) {
    issue {
      id
      number
      title
    }
    subIssue {
      id
      number
      title
    }
  }
}
```

#### サブ課題の一覧取得
```graphql
query GetSubIssues($issueId: ID!, $first: Int = 30) {
  node(id: $issueId) {
    ... on Issue {
      id
      number
      title
      body
      state
      childIssues: timelineItems(first: $first, itemTypes: [CONNECTED_EVENT]) {
        nodes {
          ... on ConnectedEvent {
            subject {
              ... on Issue {
                id
                number
                title
                state
                url
                assignees(first: 10) {
                  nodes {
                    login
                  }
                }
                labels(first: 10) {
                  nodes {
                    name
                    color
                  }
                }
                createdAt
                updatedAt
                closedAt
              }
            }
          }
        }
      }
    }
  }
}
```

### エラーハンドリング

| エラー種別 | メッセージ例 | 終了コード |
|-----------|------------|-----------|
| 親Issue不存在 | `Error: Issue #123 not found in owner/repo` | 1 |
| 権限不足 | `Error: Insufficient permissions to create issues` | 2 |
| ネットワークエラー | `Error: Failed to connect to GitHub API` | 3 |
| 不正な入力 | `Error: Invalid issue URL format` | 4 |
| API制限 | `Error: GitHub API rate limit exceeded` | 5 |

---

## 🚀 公開までの詳細ステップ

### Phase 1: 開発環境セットアップ（Day 1）

1. **リポジトリの作成**
   ```bash
   # GitHubで新規リポジトリ作成
   gh repo create gh-sub-issues --public --description "GitHub CLI extension for managing sub-issues"
   
   # ローカルにクローン
   git clone https://github.com/YOUR_USERNAME/gh-sub-issues.git
   cd gh-sub-issues
   ```

2. **Go プロジェクトの初期化**
   ```bash
   go mod init github.com/YOUR_USERNAME/gh-sub-issues
   
   # 必要な依存関係をインストール
   go get github.com/cli/go-gh@latest
   go get github.com/cli/go-gh/pkg/api
   go get github.com/spf13/cobra@latest
   go get github.com/cli/safeexec@latest
   ```

3. **基本構造の作成**
   ```bash
   mkdir -p cmd testdata/fixtures .github/workflows
   touch main.go cmd/{root,create,add,list,version}.go
   touch .goreleaser.yml .gitignore
   ```

### Phase 2: コア機能の実装（Day 2-5）

4. **main.go の実装（シンプルなエントリーポイント）**
   ```go
   package main
   
   import (
       "os"
       "github.com/YOUR_USERNAME/gh-sub-issues/cmd"
   )
   
   func main() {
       os.Exit(cmd.Execute())
   }
   ```

5. **.goreleaser.yml の作成（重要）**
   ```yaml
   project_name: gh-sub-issues
   
   before:
     hooks:
       - go mod tidy
   
   builds:
     - id: gh-sub-issues
       main: ./main.go
       binary: gh-sub-issues
       env:
         - CGO_ENABLED=0
       ldflags:
         - -s -w -X github.com/YOUR_USERNAME/gh-sub-issues/cmd.Version={{.Tag}}
       goos:
         - linux
         - darwin
         - windows
       goarch:
         - amd64
         - arm64
       ignore:
         - goos: windows
           goarch: arm64
   
   archives:
     - format: binary
       name_template: "{{ .ProjectName }}_{{ .Tag }}_{{ .Os }}_{{ .Arch }}"
   
   checksum:
     name_template: 'checksums.txt'
   
   release:
     github:
       owner: YOUR_USERNAME
       name: gh-sub-issues
   ```

6. **コマンド構造の実装**
   
   **cmd/root.go の実装例:**
   ```go
   package cmd
   
   import (
       "fmt"
       "os"
       "github.com/spf13/cobra"
   )
   
   var Version = "dev"
   
   var rootCmd = &cobra.Command{
       Use:   "gh-sub-issues",
       Short: "GitHub CLI extension for managing sub-issues",
       Long:  `A GitHub CLI extension that adds sub-issue management capabilities.`,
       Version: Version,
   }
   
   func Execute() int {
       rootCmd.AddCommand(createCmd)
       rootCmd.AddCommand(addCmd)
       rootCmd.AddCommand(listCmd)
       
       if err := rootCmd.Execute(); err != nil {
           fmt.Fprintln(os.Stderr, err)
           return 1
       }
       return 0
   }
   ```
   
   - `cmd/create.go`: createサブコマンドの実装
   - `cmd/add.go`: addサブコマンドの実装（既存Issueのリンク）
   - `cmd/list.go`: listサブコマンドの実装

7. **API クライアントの実装**
   - GraphQLクライアントの作成
   - 認証処理の実装
   - エラーハンドリングの追加

   **cmd/add.go の実装例（参考）:**
   ```go
   package cmd

   import (
       "fmt"
       "github.com/cli/go-gh"
       "github.com/cli/go-gh/pkg/api"
       "github.com/spf13/cobra"
   )

   var addCmd = &cobra.Command{
       Use:   "add <parent-issue> <sub-issue>",
       Short: "Add an existing issue as a sub-issue",
       Args:  cobra.ExactArgs(2),
       RunE: func(cmd *cobra.Command, args []string) error {
           parentIssue := args[0]
           subIssue := args[1]
           
           // GitHub APIクライアントの初期化
           client, err := gh.RESTClient(nil)
           if err != nil {
               return fmt.Errorf("failed to create client: %w", err)
           }
           
           // GraphQL mutationの実行
           var mutation struct {
               AddSubIssue struct {
                   Issue struct {
                       Number int
                       Title  string
                   }
                   SubIssue struct {
                       Number int
                       Title  string
                   }
               } `graphql:"addSubIssue(input: $input)"`
           }
           
           variables := map[string]interface{}{
               "input": map[string]interface{}{
                   "issueId":    parentIssueID,
                   "subIssueId": subIssueID,
               },
           }
           
           err = client.Mutate("AddSubIssue", &mutation, variables)
           if err != nil {
               return fmt.Errorf("failed to add sub-issue: %w", err)
           }
           
           fmt.Printf("✓ Added issue #%d as a sub-issue of #%d\n", 
               mutation.AddSubIssue.SubIssue.Number,
               mutation.AddSubIssue.Issue.Number)
           
           return nil
       },
   }
   ```

### Phase 3: テストとドキュメント（Day 6-7）

7. **テストの作成**
   ```bash
   # ユニットテストの実行
   go test ./...
   
   # カバレッジレポート
   go test -coverprofile=coverage.out ./...
   go tool cover -html=coverage.out
   ```

8. **README.md の作成**
   ```markdown
   # gh-sub-issues
   
   A GitHub CLI extension for managing sub-issues (child issues).
   
   ## Installation
   
   ```bash
   gh extension install YOUR_USERNAME/gh-sub-issues
   ```
   
   ## Usage
   
   ### Create a sub-issue
   ```bash
   gh sub-issues create --parent 123 --title "Sub-task"
   ```
   
   ### Add existing issue as sub-issue
   ```bash
   gh sub-issues add 123 456
   ```
   
   ### List sub-issues
   ```bash
   gh sub-issues list 123
   ```
   ```

9. **ライセンスと.gitignoreファイルの追加**
   ```bash
   # MITライセンスを追加
   curl -o LICENSE https://raw.githubusercontent.com/github/choosealicense.com/gh-pages/_licenses/mit.txt
   
   # .gitignoreファイルの作成
   cat > .gitignore << 'EOF'
   # Binaries for programs and plugins
   *.exe
   *.exe~
   *.dll
   *.so
   *.dylib
   gh-sub-issues
   
   # Test binary, built with `go test -c`
   *.test
   
   # Output of the go coverage tool
   *.out
   coverage.html
   
   # Dependency directories
   vendor/
   
   # GoReleaser
   dist/
   
   # IDE
   .idea/
   .vscode/
   *.swp
   *.swo
   *~
   
   # OS
   .DS_Store
   Thumbs.db
   EOF
   ```

### Phase 4: CI/CD設定（Day 8）

10. **GitHub Actions ワークフローの作成**

    `.github/workflows/test.yml`:
    ```yaml
    name: Test
    
    on:
      push:
        branches: [ main ]
      pull_request:
        branches: [ main ]
    
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v3
        - uses: actions/setup-go@v4
          with:
            go-version: '1.21'
        - run: go test -v ./...
        - run: go build -v ./...
    ```

    `.github/workflows/release.yml` (GoReleaserを使用):
    ```yaml
    name: Release
    
    on:
      push:
        tags:
          - 'v*'
    
    jobs:
      release:
        runs-on: ubuntu-latest
        steps:
        - name: Checkout
          uses: actions/checkout@v3
          with:
            fetch-depth: 0
        
        - name: Setup Go
          uses: actions/setup-go@v4
          with:
            go-version: '1.21'
        
        - name: Run GoReleaser
          uses: goreleaser/goreleaser-action@v4
          with:
            distribution: goreleaser
            version: latest
            args: release --clean
          env:
            GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    ```

### Phase 5: ローカルテスト（Day 9）

11. **ローカルインストールとテスト**
    ```bash
    # 通常のビルド
    go build -o gh-sub-issues
    
    # GoReleaserでのローカルビルド（リリース前の確認）
    goreleaser build --snapshot --clean
    
    # 拡張機能としてインストール
    gh extension install .
    
    # 動作確認
    gh sub-issues --help
    gh sub-issues --version
    gh sub-issues create --parent 1 --title "Test sub-issue"
    gh sub-issues add 1 2
    gh sub-issues list 1
    ```

12. **エッジケースのテスト**
    - 存在しないIssue番号
    - 不正なURL形式
    - 権限のないリポジトリ
    - API制限への対応

### Phase 6: 公開準備（Day 10）

13. **バージョンタグの作成**
    ```bash
    git tag -a v1.0.0 -m "Initial release"
    git push origin v1.0.0
    ```

14. **リリースノートの作成**
    ```markdown
    ## v1.0.0 - Initial Release
    
    ### Features
    - Create sub-issues linked to parent issues
    - List all sub-issues for a parent issue
    - Support for multiple output formats (TTY, non-TTY, JSON)
    - Full compatibility with gh issue create flags
    
    ### Installation
    ```bash
    gh extension install YOUR_USERNAME/gh-sub-issues
    ```
    ```

### Phase 7: 公開と配布（Day 11）

15. **GitHub Marketplace への登録（オプション）**
    - GitHub Marketplace の申請フォームを提出
    - スクリーンショットとデモ動画の準備
    - 価格設定（無料）

16. **公式gh-extensionsリストへの追加**
    ```bash
    # github/gh-extensions リポジトリにPRを作成
    # extensions.json に以下を追加:
    {
      "owner": "YOUR_USERNAME",
      "name": "gh-sub-issues",
      "description": "Manage sub-issues (child issues) in GitHub"
    }
    ```

17. **アナウンスと宣伝**
    - Twitterでリリースを告知
    - dev.to やQiitaに使用方法の記事を投稿
    - GitHub Discussionsでフィードバックを募集

---

## 📝 実装ノート

### addSubIssue mutation の利用について

GitHub GraphQL API に `addSubIssue` mutation が追加されたことで、既存のIssueを親Issueのサブ課題として追加することが可能になりました。これにより以下のワークフローが実現できます：

1. **既存Issueの階層化**: すでに作成済みのIssueを後から親子関係で整理
2. **柔軟なプロジェクト管理**: Issueの関係性を動的に変更可能
3. **クロスリポジトリ対応**: 異なるリポジトリ間でのIssue関連付け（権限があれば）

### 実装の参考リソース

- **動作確認済みの実装**: [yahsan2/gh-cli](https://github.com/yahsan2/gh-cli)
  - コミット: [05f9f44ab](https://github.com/yahsan2/gh-cli/commit/05f9f44ab)
  - 実際の動作例:
    - 親Issue作成: "Test Parent Issue" (#1)
    - サブIssue作成: "Test Sub Issue" (#2)
    - リンク実行: `gh issue add-sub 1 2 --repo yahsan2/gh-cli`
    - 結果: ✓ Added issue #2 as a sub-issue of #1

### 既存のgh CLIとの統合パターン

`gh issue add-sub` として実装することで、既存の `gh issue` コマンド群との一貫性を保つことができます。これは以下の利点があります：

- ユーザーが直感的に理解しやすい
- 既存のgh CLIのパターンに従うため、保守性が高い
- `--repo` フラグなど、既存のオプションとの互換性

### エラーハンドリングのベストプラクティス

1. **Issue番号/URLの検証**: 入力値が正しい形式か確認
2. **権限チェック**: リポジトリへの書き込み権限を事前に確認
3. **親子関係の循環チェック**: 親が子の子にならないよう検証
4. **API応答の詳細なエラーメッセージ**: ユーザーにわかりやすいエラー表示

---

## ✅ リリースチェックリスト

### 開発完了確認
- [ ] すべての主要機能が実装済み
- [ ] ユニットテストのカバレッジ80%以上
- [ ] 統合テストが通過
- [ ] エラーハンドリングの実装
- [ ] ログ出力の適切な設定

### ドキュメント
- [ ] README.mdの完成
- [ ] LICENSEファイルの追加
- [ ] CONTRIBUTINGガイドラインの作成
- [ ] CHANGELOG.mdの作成
- [ ] インラインコメントの追加

### 品質保証
- [ ] golintでの警告なし
- [ ] go vetでのエラーなし
- [ ] セキュリティスキャン通過
- [ ] 依存関係の脆弱性チェック

### CI/CD
- [ ] GitHub Actionsワークフロー設定
- [ ] 自動テストの設定
- [ ] 自動リリースの設定
- [ ] バイナリビルドの自動化

### 公開準備
- [ ] バージョンタグの作成
- [ ] リリースノートの作成
- [ ] デモGIFやスクリーンショットの準備
- [ ] インストール手順の文書化

### 公開後
- [ ] gh extension install でのインストール確認
- [ ] 各コマンドの動作確認
- [ ] ユーザーフィードバックの収集体制
- [ ] Issue/PRテンプレートの設定

---

## 🔍 トラブルシューティング

### よくある問題と解決方法

| 問題 | 原因 | 解決方法 |
|-----|------|---------|
| `command not found` | 拡張機能が正しくインストールされていない | `gh extension install YOUR_USERNAME/gh-sub-issues` を再実行 |
| `authentication required` | GitHub CLIの認証が必要 | `gh auth login` を実行 |
| `parent issue not found` | Issue番号またはURLが間違っている | 正しいIssue番号/URLを確認 |
| `permission denied` | リポジトリへの書き込み権限がない | リポジトリの権限を確認 |
| `rate limit exceeded` | API呼び出し制限に到達 | 1時間待つか、認証を使用 |

---

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/AmazingFeature`)
3. 変更をコミット (`git commit -m 'Add some AmazingFeature'`)
4. ブランチをプッシュ (`git push origin feature/AmazingFeature`)
5. Pull Requestを作成

### 開発者向けコマンド

```bash
# 依存関係のインストール
go mod download

# テストの実行
go test -v ./...

# ビルド
go build -o gh-sub-issues

# フォーマット
go fmt ./...

# Lintチェック
golangci-lint run
```

---

## 📚 参考資料

- [GitHub CLI Extension開発ガイド](https://cli.github.com/manual/gh_extension)
- [GitHub GraphQL API](https://docs.github.com/en/graphql)
- [Go GitHub CLI SDK](https://github.com/cli/go-gh)
- [Cobra CLIフレームワーク](https://github.com/spf13/cobra)
- [実装例: gh-cli extensions](https://github.com/topics/gh-extension)

---

## 📄 ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照してください。

---

## 👤 作者

- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
- Twitter: [@YOUR_TWITTER](https://twitter.com/YOUR_TWITTER)

---

## ⭐ サポート

このプロジェクトが役に立った場合は、⭐️を付けてください！

## 🔮 今後の機能追加予定

- [ ] サブ課題の一括作成（CSVインポート）
- [ ] サブ課題のツリー表示
- [ ] 進捗状況のビジュアル表示
- [ ] Webhookによる自動化対応
- [ ] プロジェクトボードとの連携
- [ ] サブ課題テンプレート機能
- [ ] 再帰的なサブ課題の対応（孫課題）