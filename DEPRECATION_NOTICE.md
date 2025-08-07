# ⚠️ DEPRECATION NOTICE

## This repository has been renamed to `gh-sub-issue`

### 📦 New Repository
**https://github.com/yahsan2/gh-sub-issue**

### Why the rename?
To maintain consistency with GitHub CLI naming conventions:
- GitHub CLI uses singular forms: `gh issue`, `gh pr`
- Extensions should follow the same pattern: `gh sub-issue` (not `gh sub-issues`)

### 🔄 Migration Instructions

1. **Uninstall the old extension:**
   ```bash
   gh extension remove sub-issues
   ```

2. **Install the new extension:**
   ```bash
   gh extension install yahsan2/gh-sub-issue
   ```

3. **Update your commands:**
   - Old: `gh sub-issues add 1 2`
   - New: `gh sub-issue add 1 2`

### 📝 What changed?
- Repository name: `gh-sub-issues` → `gh-sub-issue`
- Command name: `gh sub-issues` → `gh sub-issue`
- All functionality remains the same

### 🗓️ Deprecation Timeline
- **Now**: This repository is deprecated
- **Future**: This repository will be archived (no new updates)
- **Recommendation**: Please migrate to the new repository immediately

### 🤝 Support
If you have any issues with the migration, please open an issue in the new repository:
https://github.com/yahsan2/gh-sub-issue/issues

---

**Thank you for using gh-sub-issues! Please continue with gh-sub-issue.**