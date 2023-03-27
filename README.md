# GitOps version

- Generate a version from git tags and commits
- Version is cached in a file to avoid expensive git operations
- Schema is based on [semver](https://semver.org/)
- Compatible with [gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- Portable, works on Linux and Windows

## In a nutshell

### Install to your repo

Linux:

```bash
# Add this repo as a submodule, from the root of your repo
> git submodule add -b master https://github.com/clemlesne/gitops-version .
```

### How to use

```bash
> sh ./version.sh -g .
0.2.11-44.630dcd2
```

```powershell
> .\version.ps1 -g .
0.2.11-44.630dcd2
```

Examples:

```bash
# Get short version from current commit
> ./version.sh -g .
0.2.11-44.630dcd2

# Get long version from current commit
> ./version.sh -g . -m
0.2.11-44.630dcd2+20230327090732

# Get the long cached version from commit
> ./version.sh -g . -m -c
0.2.11-44.630dcd2+20230327090732

# Get the version from a repo stored in another folder
> ./version.sh -g ./my_folder/
0.7.2
```

## [Authors](./AUTHORS.md)
