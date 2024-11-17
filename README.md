# kubeseal-utils
Command line utility for working with Kubernetes sealed secrets in GitOps workflows

## Overview
kubeseal-utils provides a set of tools to help developers and operators work more effectively with Kubernetes sealed secrets in GitOps environments. It simplifies the process of inspecting and modifying sealed secrets that are stored in your Git repository and deployed to your clusters through GitOps automation.

## Workflow Example
1. Dump secrets from your cluster for inspection
2. Review and modify the unsealed secrets as needed
3. Restore the secrets back to their sealed form
4. Commit the sealed secrets to your repository

## Features

### Dump Command
Extract and decode sealed secrets from your cluster for local inspection and modification:
- Safely decode sealed secrets from your cluster into their unsealed form
- Automatically organize unsealed secrets in a parallel directory structure
- Preserve metadata and structure for easy restoration back to your Git repository
- Built-in safety features:
  - Kubernetes context verification
  - Automatic `.gitignore` updates

### Restore Command
Convert unsealed secrets back to their sealed form for committing to Git:
- Automatically seal secrets using the cluster's public key
- Maintain original directory structure for GitOps compatibility
- Safety features include:
  - Kubernetes context verification
  - Path validation
  - Automatic cleanup of unsealed secrets
- Flexible target path options

## Installation
```bash
# Install with Homebrew
brew tap joseph-ravenwolfe/kubeseal-utils
brew install kubeseal-utils
```

## Usage

### Dumping Secrets
Extract sealed secrets from your cluster for inspection:

```bash
kubeseal-utils dump <cluster-context> <secrets-path>
```

Example:
```bash
kubeseal-utils dump my-cluster path/to/secrets
```

### Restoring Secrets
Convert unsealed secrets back to their sealed form:
```bash
kubeseal-utils restore <cluster-context> <unsealed-path> [--target <target-path>]
```

Examples:
```bash
# Basic restore
kubeseal-utils restore my-cluster path/to/secrets-unsealed

# Restore with custom target location
kubeseal-utils restore my-cluster path/to/secrets-unsealed --target path/to/new/location
```

## Security Considerations
- The dump command creates files containing sensitive data
- Unsealed secrets are automatically added to `.gitignore` to prevent accidental commits
- Always handle unsealed secrets with appropriate security precautions
- Clean up unsealed secrets promptly after use

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
MIT
