# Implementation Guide: gh sub-issues add command (Issue #4)

## 📋 Overview
This document provides detailed instructions for implementing the `gh sub-issues add` command, which links existing GitHub issues as sub-issues to a parent issue using the GitHub GraphQL API's `addSubIssue` mutation.

## 🎯 Goal
Create a Go-based GitHub CLI extension that allows users to establish parent-child relationships between existing issues.

---

## 📁 Project Setup Tasks

### Task 1: Initialize Go Project Structure
```bash
# 1.1 Initialize Go module
go mod init github.com/yahsan2/gh-sub-issues

# 1.2 Create directory structure
mkdir -p cmd
touch main.go
touch cmd/root.go
touch cmd/add.go
touch .gitignore
touch .goreleaser.yml

# 1.3 Install dependencies
go get github.com/cli/go-gh@latest
go get github.com/cli/go-gh/v2/pkg/api@latest
go get github.com/spf13/cobra@latest
go get github.com/cli/safeexec@latest
```

### Task 2: Create Basic Project Files

#### 2.1 Create `.gitignore`
```gitignore
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
gh-sub-issues

# Test files
*.test
*.out
coverage.html

# Dependencies
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
```

#### 2.2 Create `main.go`
```go
package main

import (
    "os"
    "github.com/yahsan2/gh-sub-issues/cmd"
)

func main() {
    os.Exit(cmd.Execute())
}
```

---

## 🔧 Implementation Tasks

### Task 3: Implement Command Structure

#### 3.1 Create `cmd/root.go`
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
    Long:  `A GitHub CLI extension that adds sub-issue management capabilities to GitHub issues.`,
    Version: Version,
}

func Execute() int {
    // Add subcommands
    rootCmd.AddCommand(addCmd)
    
    if err := rootCmd.Execute(); err != nil {
        fmt.Fprintln(os.Stderr, err)
        return 1
    }
    return 0
}
```

### Task 4: Implement Core Add Command Logic

#### 4.1 Create `cmd/add.go` - Basic Structure
```go
package cmd

import (
    "context"
    "fmt"
    "strconv"
    "strings"
    
    "github.com/cli/go-gh/v2/pkg/api"
    "github.com/spf13/cobra"
)

var repoFlag string

var addCmd = &cobra.Command{
    Use:   "add <parent-issue> <sub-issue>",
    Short: "Add an existing issue as a sub-issue to a parent issue",
    Long:  `Link an existing issue to a parent issue using GitHub's issue hierarchy feature.`,
    Args:  cobra.ExactArgs(2),
    RunE:  runAdd,
}

func init() {
    addCmd.Flags().StringVarP(&repoFlag, "repo", "R", "", "Repository in OWNER/REPO format")
}
```

### Task 5: Implement Issue Parsing Functions

#### 5.1 Add URL/Number Parsing
```go
// IssueReference represents a parsed issue reference
type IssueReference struct {
    Owner  string
    Repo   string
    Number int
}

// parseIssueReference parses issue number or URL
func parseIssueReference(ref string, defaultOwner, defaultRepo string) (*IssueReference, error) {
    // Check if it's a URL
    if strings.HasPrefix(ref, "http://") || strings.HasPrefix(ref, "https://") {
        return parseIssueURL(ref)
    }
    
    // Otherwise, treat as issue number
    number, err := strconv.Atoi(ref)
    if err != nil {
        return nil, fmt.Errorf("invalid issue reference: %s", ref)
    }
    
    return &IssueReference{
        Owner:  defaultOwner,
        Repo:   defaultRepo,
        Number: number,
    }, nil
}

// parseIssueURL extracts owner, repo, and issue number from GitHub URL
func parseIssueURL(url string) (*IssueReference, error) {
    // Expected format: https://github.com/owner/repo/issues/123
    parts := strings.Split(url, "/")
    if len(parts) < 7 || parts[5] != "issues" {
        return nil, fmt.Errorf("invalid GitHub issue URL: %s", url)
    }
    
    number, err := strconv.Atoi(parts[6])
    if err != nil {
        return nil, fmt.Errorf("invalid issue number in URL: %s", parts[6])
    }
    
    return &IssueReference{
        Owner:  parts[3],
        Repo:   parts[4],
        Number: number,
    }, nil
}
```

### Task 6: Implement GraphQL Queries

#### 6.1 Add GraphQL Query Functions
```go
// getIssueNodeID gets the GraphQL node ID for an issue
func getIssueNodeID(client *api.GraphQLClient, owner, repo string, number int) (string, error) {
    query := `
        query($owner: String!, $repo: String!, $number: Int!) {
            repository(owner: $owner, name: $repo) {
                issue(number: $number) {
                    id
                }
            }
        }`
    
    variables := map[string]interface{}{
        "owner":  owner,
        "repo":   repo,
        "number": number,
    }
    
    var response struct {
        Repository struct {
            Issue struct {
                ID string `json:"id"`
            } `json:"issue"`
        } `json:"repository"`
    }
    
    err := client.Query(query, variables, &response)
    if err != nil {
        return "", fmt.Errorf("failed to get issue #%d: %w", number, err)
    }
    
    if response.Repository.Issue.ID == "" {
        return "", fmt.Errorf("issue #%d not found in %s/%s", number, owner, repo)
    }
    
    return response.Repository.Issue.ID, nil
}

// addSubIssue links a sub-issue to a parent issue
func addSubIssue(client *api.GraphQLClient, parentID, subIssueID string) error {
    mutation := `
        mutation($parentId: ID!, $subIssueId: ID!) {
            addSubIssue(input: {
                issueId: $parentId,
                subIssueId: $subIssueId
            }) {
                issue {
                    number
                    title
                }
                subIssue {
                    number
                    title
                }
            }
        }`
    
    variables := map[string]interface{}{
        "parentId":   parentID,
        "subIssueId": subIssueID,
    }
    
    var response struct {
        AddSubIssue struct {
            Issue struct {
                Number int    `json:"number"`
                Title  string `json:"title"`
            } `json:"issue"`
            SubIssue struct {
                Number int    `json:"number"`
                Title  string `json:"title"`
            } `json:"subIssue"`
        } `json:"addSubIssue"`
    }
    
    err := client.Mutate(mutation, variables, &response)
    if err != nil {
        return fmt.Errorf("failed to add sub-issue: %w", err)
    }
    
    fmt.Printf("✓ Added issue #%d as a sub-issue of #%d\n",
        response.AddSubIssue.SubIssue.Number,
        response.AddSubIssue.Issue.Number)
    
    return nil
}
```

### Task 7: Implement Main Command Logic

#### 7.1 Complete the runAdd Function
```go
func runAdd(cmd *cobra.Command, args []string) error {
    // Get default repository from current directory or --repo flag
    defaultOwner, defaultRepo, err := getDefaultRepo()
    if err != nil && repoFlag == "" {
        return fmt.Errorf("could not determine repository (use --repo flag): %w", err)
    }
    
    // Override with --repo flag if provided
    if repoFlag != "" {
        parts := strings.Split(repoFlag, "/")
        if len(parts) != 2 {
            return fmt.Errorf("invalid repository format: %s (expected OWNER/REPO)", repoFlag)
        }
        defaultOwner = parts[0]
        defaultRepo = parts[1]
    }
    
    // Parse parent and sub-issue references
    parentRef, err := parseIssueReference(args[0], defaultOwner, defaultRepo)
    if err != nil {
        return fmt.Errorf("invalid parent issue: %w", err)
    }
    
    subRef, err := parseIssueReference(args[1], defaultOwner, defaultRepo)
    if err != nil {
        return fmt.Errorf("invalid sub-issue: %w", err)
    }
    
    // Create GraphQL client
    client, err := api.NewGraphQLClient(api.ClientOptions{
        AuthToken: getAuthToken(),
    })
    if err != nil {
        return fmt.Errorf("failed to create GitHub client: %w", err)
    }
    
    // Get node IDs for both issues
    parentID, err := getIssueNodeID(client, parentRef.Owner, parentRef.Repo, parentRef.Number)
    if err != nil {
        return err
    }
    
    subID, err := getIssueNodeID(client, subRef.Owner, subRef.Repo, subRef.Number)
    if err != nil {
        return err
    }
    
    // Link the issues
    return addSubIssue(client, parentID, subID)
}
```

### Task 8: Add Helper Functions

#### 8.1 Add Repository Detection
```go
func getDefaultRepo() (string, string, error) {
    // Try to get from git remote
    cmd := exec.Command("gh", "repo", "view", "--json", "owner,name")
    output, err := cmd.Output()
    if err != nil {
        return "", "", err
    }
    
    var repo struct {
        Owner struct {
            Login string `json:"login"`
        } `json:"owner"`
        Name string `json:"name"`
    }
    
    if err := json.Unmarshal(output, &repo); err != nil {
        return "", "", err
    }
    
    return repo.Owner.Login, repo.Name, nil
}

func getAuthToken() string {
    // gh CLI handles authentication automatically
    return ""
}
```

---

## 🧪 Testing Tasks

### Task 9: Local Testing

#### 9.1 Build and Install Locally
```bash
# Build the extension
go build -o gh-sub-issues

# Install as gh extension
gh extension install .

# Test the command
gh sub-issues add 1 2
gh sub-issues add 1 2 --repo yahsan2/gh-sub-issues
```

#### 9.2 Test Cases to Verify
1. Link issues by numbers: `gh sub-issues add 1 2`
2. Link using parent URL: `gh sub-issues add https://github.com/owner/repo/issues/1 2`
3. Link using both URLs
4. Cross-repository linking with --repo flag
5. Error handling for non-existent issues
6. Error handling for permission errors

### Task 10: Create Unit Tests

#### 10.1 Create `cmd/add_test.go`
```go
package cmd

import (
    "testing"
)

func TestParseIssueReference(t *testing.T) {
    tests := []struct {
        name          string
        input         string
        defaultOwner  string
        defaultRepo   string
        expectedOwner string
        expectedRepo  string
        expectedNum   int
        expectError   bool
    }{
        {
            name:          "issue number",
            input:         "123",
            defaultOwner:  "owner",
            defaultRepo:   "repo",
            expectedOwner: "owner",
            expectedRepo:  "repo",
            expectedNum:   123,
        },
        {
            name:          "github url",
            input:         "https://github.com/owner/repo/issues/456",
            defaultOwner:  "default",
            defaultRepo:   "default",
            expectedOwner: "owner",
            expectedRepo:  "repo",
            expectedNum:   456,
        },
        {
            name:        "invalid url",
            input:       "https://example.com/123",
            expectError: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ref, err := parseIssueReference(tt.input, tt.defaultOwner, tt.defaultRepo)
            
            if tt.expectError {
                if err == nil {
                    t.Error("expected error but got none")
                }
                return
            }
            
            if err != nil {
                t.Errorf("unexpected error: %v", err)
                return
            }
            
            if ref.Owner != tt.expectedOwner {
                t.Errorf("owner: got %s, want %s", ref.Owner, tt.expectedOwner)
            }
            if ref.Repo != tt.expectedRepo {
                t.Errorf("repo: got %s, want %s", ref.Repo, tt.expectedRepo)
            }
            if ref.Number != tt.expectedNum {
                t.Errorf("number: got %d, want %d", ref.Number, tt.expectedNum)
            }
        })
    }
}
```

---

## 📝 Error Handling Requirements

### Task 11: Implement Comprehensive Error Handling

#### Error Cases to Handle:
1. **Non-existent parent issue**: "Error: Issue #X not found in owner/repo"
2. **Non-existent sub-issue**: "Error: Issue #Y not found in owner/repo"
3. **Permission denied**: "Error: Insufficient permissions to modify issues in owner/repo"
4. **Invalid URL format**: "Error: Invalid GitHub issue URL: [url]"
5. **Invalid issue number**: "Error: Invalid issue number: [input]"
6. **Network errors**: "Error: Failed to connect to GitHub API"
7. **Authentication errors**: "Error: Authentication required. Run 'gh auth login'"
8. **Circular dependency**: "Error: Cannot add issue as its own sub-issue"

---

## ✅ Completion Checklist

- [ ] Project structure created
- [ ] Go module initialized with dependencies
- [ ] Basic command structure implemented (root.go, add.go)
- [ ] Issue reference parsing (numbers and URLs)
- [ ] GraphQL queries for getting issue IDs
- [ ] AddSubIssue mutation implementation
- [ ] Repository detection from git or --repo flag
- [ ] Error handling for all edge cases
- [ ] Success message formatting
- [ ] Unit tests for parsing functions
- [ ] Local testing with real issues
- [ ] Command help text and documentation

---

## 🚀 Next Steps

After completing all tasks:
1. Test with the existing issues in yahsan2/gh-sub-issues repository
2. Update README.md with usage examples
3. Create a release with GoReleaser
4. Submit for code review
5. Close Issue #4

---

## 📚 References

- [GitHub CLI Extension Documentation](https://docs.github.com/en/github-cli/github-cli/creating-github-cli-extensions)
- [go-gh Library Documentation](https://github.com/cli/go-gh)
- [GitHub GraphQL API Documentation](https://docs.github.com/en/graphql)
- [Reference Implementation](https://github.com/yahsan2/gh-cli/commit/05f9f44ab)