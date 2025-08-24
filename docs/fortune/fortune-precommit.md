# Pre-Commit Hook Setup Guide for Automating Fortune File Updates

This document explains how to set up a pre-commit hook that automatically updates the local `*.fortune.dat` file when committing `*.fortune` files.

## Introduction to Pre-Commit Hooks

A pre-commit hook is a script that runs before Git performs a commit. This hook allows you to automatically execute specific tasks during the commit process. In this example, whenever a `*.fortune` file is modified, the corresponding .dat file will be automatically generated for the commit.

## Environment Setup

1. Setting Up the `.pre-commit-config.yaml` File
Here’s an example of the `.pre-commit-config.yaml` file where the necessary hooks are defined.

```yaml
repos:
  - repo: local
    hooks:
      - id: strfile-fortune
        name: Generate strfile for fortune files
        entry: bash
        language: system
        always_run: true
        pass_filenames: false
        stages: [commit]
        types: [file]
        description: |-
          This hook generates .dat files from .fortune files using the strfile command.
          It processes all .fortune files under the fortune/ directory.

        files: ^fortune/.*\.fortune$

        args:
          - '-c'
          - |
            for file in fortune/*.fortune; do
              strfile "$file"
            done
```

2. Installing strfile

This hook uses the strfile utility to create the `.fortune.dat` file. Ensure that strfile is installed on your system. You can install it on Linux or macOS using the following commands:

```bash
# For Ubuntu or Debian
sudo apt-get install fortune

# For macOS using Homebrew
brew install fortune
```

3. Activating the Pre-Commit Hook

Install the pre-commit package.

```
brew install pre-commit
pre-commit --version
```

Now, run the following command in your repository to activate the pre-commit hook:

```bash
pre-commit install
```

This command installs the hook in `.git/hooks/pre-commit`.

4. Usage

Now, after modifying a `*.fortune file`, when you perform a commit, the corresponding `.fortune.dat` file will be generated automatically. You can commit as follows:

```bash
git add *.fortune
git commit -m "style: Linting indent"
```

5. Checking the Result

After the commit, if the output message includes gitstrfile-fortune, the hook has been executed successfully. Here’s an example of a successful commit:

```bash
strfile-fortune..........................................................Passed
[main a30b41e] style: Linting indent
 1 file changed, 6 insertions(+), 6 deletions(-)
This output indicates that the hook has run successfully.
```

## Reference Links

- Pre-Commit Documentation: https://pre-commit.com/
- Git Hooks Documentation: https://git-scm.com/book/en/Customizing-Git-Git-Hooks
