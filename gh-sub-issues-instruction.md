
# 🧠 AI Agent Coding Instruction: GitHub CLI Extension `gh-sub-issues`

## 🎯 目的

GitHub CLI にサブ課題（Sub-issue）を扱う機能を追加する `gh extension` を実装する。以下2機能を中心とする。

---

## 🛠 実装するコマンド

### 1. `gh sub-issues create`

**概要**:  
サブ課題（sub-issue）を親 issue に紐付けて作成する。

**仕様**:
- `--parent` または `-P` フラグで親 Issue を指定（URL or Issue番号）
- 他の `gh issue create` のフラグと互換性あり（例: `--title`, `--body`, `--label`, `--assignee` など）
- GraphQL API による `parentIssueId` 指定の issue 作成
- エラーハンドリング（存在しない issue、URL フォーマットミス等）

**使用例**:
```bash
gh sub-issues create --parent 123 --title "Sub-task title" --body "Description"
gh sub-issues create -P https://github.com/owner/repo/issues/123 --title "Sub-task"
```

---

### 2. `gh sub-issues list`

**概要**:  
指定された親 issue に紐づく sub-issues を表示する。

**仕様**:
- 引数として Issue番号 または URL を受け取る
- `--json` フラグ指定で JSON 形式出力をサポート
- TTY: カラー付き・ステータス表示付き
- 非TTY: タブ区切り出力（スクリプト向け）

**使用例**:
```bash
gh sub-issues list 123
gh sub-issues list https://github.com/owner/repo/issues/123
gh sub-issues list 123 --json
```

---

## 📁 ディレクトリ構成（推奨）

```
gh-sub-issues/
├── README.md
├── main.go
├── cmd/
│   ├── create.go
│   └── list.go
├── api/
│   ├── graphql.go
│   └── types.go
└── test/
    ├── create_test.go
    └── list_test.go
```

---

## 🔧 GraphQL関連処理

### 親 Issue ID を取得
```graphql
query($url: URI!) {
  resource(url: $url) {
    ... on Issue {
      id
    }
  }
}
```

### sub-issue 作成時の Mutation
```graphql
mutation($repositoryId: ID!, $title: String!, $body: String, $parentId: ID) {
  createIssue(input: {
    repositoryId: $repositoryId,
    title: $title,
    body: $body,
    parentIssueId: $parentId
  }) {
    issue {
      number
      url
    }
  }
}
```

### sub-issues 一覧取得
```graphql
query($issueId: ID!) {
  node(id: $issueId) {
    ... on Issue {
      id
      number
      title
      body
      timelineItems(first: 100, itemTypes: [CONNECTED_EVENT]) {
        nodes {
          ... on ConnectedEvent {
            subject {
              ... on Issue {
                id
                number
                title
                state
                url
              }
            }
          }
        }
      }
    }
  }
}
```

---

## ✅ 実装後のチェックリスト

- [ ] `gh extension install` で動作確認
- [ ] `gh sub-issues create` で親 issue に紐づく sub-issue が作成される
- [ ] `gh sub-issues list` で関連 sub-issues が表示される
- [ ] TTY / 非TTY 両方で出力確認
- [ ] JSON 出力形式も確認
- [ ] エラーハンドリング：URL不正、存在しないissueなど

---

## 🔗 参考

- GitHub CLI Extension Guide: https://cli.github.com/manual/gh_extension  
- 実装例: https://github.com/yahsan2/gh-cli
