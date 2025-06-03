# Contents

[`dotfiles/.gitconfig`](dotfiles/.gitconfig) contains my git config and aliases

[`sh/git_commands`](sh/git_commands) contains my shell aliases

## Misc. git commands

[`bin/`](bin/) contains various git commands.

Some of these scripts are more useful or more polished than others.

Some of them are very old and just need to be removed.

## Commands and scripts to help split commits or a branch by "specificity"

### 1. File specificity

Managing specificity of individual files:
```
git-detect-file-specificity
git-get-file-specificity
git-set-file-specificity
git-clean-up-file-specificity-lists
```

Listing files by specificity:
```
git-ls-files-specificity  # All files in tree
git-diff-tree-specificity # Only files for a single commit
git-diff-tree-specificity --detect
```

### 2. Commit specificity

- `git-rebase-split-commits-by-specificity`
  - Wrapper for: `git-split-commit-by-specificity`

Managing specificity of individual commits:
```
git-detect-commit-specificity
git-get-commit-specificity
git-set-commit-specificity
```

Listing commits by specificity:
```
git-log-specificity
git-ls-notes-specificity
```

```
git-rebase-seq-add-specificity
```

### 3. Branch specificity

- `git-split-branch-by-specificity`
  - Wrapper for: `git-rebase-seq-split-branch-by-specificity`

# Installation

Clone this repo and add its `bin/` dir to your `PATH`.

This will let you run the commands in that dir using either `git-command` or `git command`.
