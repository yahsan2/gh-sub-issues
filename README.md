# gh-sub-issues

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/yahsan2/gh-sub-issues)](https://github.com/yahsan2/gh-sub-issues/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Report Card](https://goreportcard.com/badge/github.com/yahsan2/gh-sub-issues)](https://goreportcard.com/report/github.com/yahsan2/gh-sub-issues)

A GitHub CLI extension for managing sub-issues (child issues). Create hierarchical task structures by linking issues as parent-child relationships.

## ✨ Features

- 🔗 **Link existing issues** - Connect existing issues as sub-issues to a parent issue
- ➕ **Create sub-issues** - Create new issues directly linked to a parent
- 📋 **List sub-issues** - View all sub-issues connected to a parent issue
- 🎨 **Multiple output formats** - Support for TTY (colored), plain text, and JSON output
- 🔄 **Cross-repository support** - Work with issues across different repositories

## 📦 Installation

```bash
gh extension install yahsan2/gh-sub-issues
```

### Requirements

- [GitHub CLI](https://cli.github.com/) 2.0.0 or later
- GitHub account with appropriate repository permissions

## 🚀 Usage

### Add existing issue as sub-issue

Link an existing issue to a parent issue:

```bash
# Using issue numbers
gh sub-issues add 123 456

# Using URLs
gh sub-issues add https://github.com/owner/repo/issues/123 456

# Cross-repository
gh sub-issues add 123 456 --repo owner/repo
```

### Create a new sub-issue

Create a new issue directly linked to a parent:

```bash
# Basic usage
gh sub-issues create --parent 123 --title "Implement user authentication"

# With description and labels
gh sub-issues create --parent 123 \
  --title "Add login endpoint" \
  --body "Implement POST /api/login endpoint" \
  --label "backend,api" \
  --assignee "@me"

# Using parent issue URL
gh sub-issues create \
  --parent https://github.com/owner/repo/issues/123 \
  --title "Write API tests"
```

### List sub-issues

View all sub-issues linked to a parent issue:

```bash
# Basic listing
gh sub-issues list 123

# Show all states (open, closed)
gh sub-issues list 123 --state all

# JSON output for scripting
gh sub-issues list 123 --json

# Using URL
gh sub-issues list https://github.com/owner/repo/issues/123
```

## 📋 Command Reference

### `gh sub-issues add`

Add an existing issue as a sub-issue to a parent issue.

```
Usage:
  gh sub-issues add <parent-issue> <sub-issue> [flags]

Arguments:
  parent-issue    Parent issue number or URL
  sub-issue       Sub-issue number or URL to be added

Flags:
  -R, --repo      Repository in OWNER/REPO format
  -h, --help      Show help for command
```

### `gh sub-issues create`

Create a new sub-issue linked to a parent issue.

```
Usage:
  gh sub-issues create [flags]

Flags:
  -P, --parent       Parent issue number or URL (required)
  -t, --title        Title for the new sub-issue (required)
  -b, --body         Body text for the sub-issue
  -l, --label        Comma-separated labels to add
  -a, --assignee     Comma-separated usernames to assign
  -m, --milestone    Milestone name or number
  -p, --project      Project name or number
  -R, --repo         Repository in OWNER/REPO format
  -h, --help         Show help for command
```

### `gh sub-issues list`

List all sub-issues for a parent issue.

```
Usage:
  gh sub-issues list <parent-issue> [flags]

Arguments:
  parent-issue    Parent issue number or URL

Flags:
  -s, --state     Filter by state: {open|closed|all} (default: open)
  -L, --limit     Maximum number of sub-issues to display (default: 30)
  --json          Output in JSON format
  -w, --web       Open in web browser
  -R, --repo      Repository in OWNER/REPO format
  -h, --help      Show help for command
```

## 🎯 Examples

### Real-world workflow

```bash
# 1. Create a parent issue for a feature
gh issue create --title "Feature: User Authentication System" --body "Implement complete auth system"
# Created issue #100

# 2. Create sub-issues for implementation tasks
gh sub-issues create --parent 100 --title "Design database schema" --label "database"
gh sub-issues create --parent 100 --title "Implement JWT tokens" --label "backend"
gh sub-issues create --parent 100 --title "Create login UI" --label "frontend"

# 3. Link an existing issue as a sub-issue
gh sub-issues add 100 95  # Add existing issue #95 as sub-issue

# 4. View progress
gh sub-issues list 100 --state all
```

### Output example

```
$ gh sub-issues list 100

Parent: #100 - Feature: User Authentication System

SUB-ISSUES (4 total, 2 open)
─────────────────────────────
✅ #101  Design database schema           [closed]
✅ #95   Security audit checklist         [closed]
🔵 #102  Implement JWT tokens             [open]   @alice
🔵 #103  Create login UI                  [open]   @bob
```

## 🔧 Configuration

The extension uses your existing GitHub CLI authentication and configuration:

```bash
# Check current authentication status
gh auth status

# Login if needed
gh auth login

# Set default repository
gh repo set-default owner/repo
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development

```bash
# Clone the repository
git clone https://github.com/yahsan2/gh-sub-issues.git
cd gh-sub-issues

# Install dependencies
go mod download

# Run tests
go test ./...

# Build locally
go build -o gh-sub-issues

# Install locally for testing
gh extension install .
```

## 🐛 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| `command not found` | Run `gh extension install yahsan2/gh-sub-issues` |
| `authentication required` | Run `gh auth login` |
| `parent issue not found` | Check issue number/URL and repository |
| `permission denied` | Ensure you have write access to the repository |
| `rate limit exceeded` | Wait for rate limit reset or authenticate with `gh auth login` |

### Debug Mode

Enable debug output for troubleshooting:

```bash
GH_DEBUG=1 gh sub-issues list 123
```

## 📝 Notes

- Sub-issues are managed using GitHub's native issue tracking features
- The parent-child relationship is maintained through GitHub's issue references
- All standard GitHub issue features (labels, assignees, milestones) are supported
- Works with both public and private repositories (with appropriate permissions)

## 🏗️ Architecture

This extension uses:
- GitHub GraphQL API for efficient data fetching
- Native GitHub issue relationships for parent-child linking
- GitHub CLI's built-in authentication and API client

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [GitHub CLI](https://cli.github.com/)
- Inspired by the need for better hierarchical task management in GitHub
- Thanks to all contributors and users

## 🔗 Related Projects

- [GitHub CLI](https://github.com/cli/cli) - The official GitHub command-line tool
- [gh-project](https://github.com/github/gh-project) - Work with GitHub Projects from the command line

## 📮 Support

- 🐛 [Report a bug](https://github.com/yahsan2/gh-sub-issues/issues/new?labels=bug)
- 💡 [Request a feature](https://github.com/yahsan2/gh-sub-issues/issues/new?labels=enhancement)
- 💬 [Ask a question](https://github.com/yahsan2/gh-sub-issues/discussions)

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yahsan2/gh-sub-issues&type=Date)](https://star-history.com/#yahsan2/gh-sub-issues&Date)

---

**Made with ❤️ by [@yahsan2](https://github.com/yahsan2)**