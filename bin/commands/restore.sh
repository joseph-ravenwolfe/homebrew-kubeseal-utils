#!/bin/bash

restore_usage() {
    echo
    echo "Restore unsealed secrets back to their sealed form."
    echo
    echo "Usage:"
    echo "  $(basename "$0") restore <cluster-context> <unsealed-path> [--target <target-path>]"
    echo
    echo "Arguments:"
    echo "  cluster-context   The k8s cluster context to use (e.g. my-cluster)"
    echo "  unsealed-path     Path to directory containing unsealed secrets (relative or absolute)"
    echo "  --target          Optional target directory for sealed secrets (defaults to unsealed-path without -unsealed suffix)"
    echo
    echo "Examples:"
    echo "  # Restore secrets for config"
    echo "  $(basename "$0") restore my-cluster path/to/unsealed/secrets"
    echo
    echo "  # Restore secrets with custom target directory"
    echo "  $(basename "$0") restore my-cluster path/to/unsealed/secrets --target path/to/new/secrets"
    echo
    exit 1
}

# Show restore help if requested
if [ "$1" = "--help" ]; then
    restore_usage
fi

INTENDED_CONTEXT="$1"
UNSEALED_PATH="$2"
TARGET_PATH=""

# Parse optional target argument
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET_PATH="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option $1"
            restore_usage
            ;;
    esac
done

if [ -z "$UNSEALED_PATH" ]; then
    echo "Error: unsealed path argument is required"
    restore_usage
fi

# Check if path contains 'unsealed'
if [[ ! "$UNSEALED_PATH" =~ "unsealed" ]]; then
    echo "Warning: The provided path does not contain 'unsealed'. This may not be an unsealed secrets directory."
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 1
    fi
fi

# Ensure unsealed path exists and normalize it (remove trailing slash)
UNSEALED_PATH="${UNSEALED_PATH%/}"
if [ ! -d "$UNSEALED_PATH" ]; then
    echo "Error: Unsealed path $UNSEALED_PATH does not exist or is not a directory"
    exit 1
fi

# If no target path specified, create one by removing -unsealed suffix
if [ -z "$TARGET_PATH" ]; then
    TARGET_PATH="${UNSEALED_PATH%-unsealed}"
fi

# Get current kubectl context
banner "Checking K8s context"
CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$CURRENT_CONTEXT" != "$INTENDED_CONTEXT" ]; then
    echo "Error: Current kubectl context ($CURRENT_CONTEXT) does not match intended context ($INTENDED_CONTEXT)"
    echo "Please set your Kubernetes context to your intended cluster before continuing."
    exit 1
fi

echo "Using Cluster Context: $INTENDED_CONTEXT"
echo "Using Unsealed Path: $UNSEALED_PATH"
echo "Using Target Path: $TARGET_PATH"

# Create temporary directory for work
mkdir -p .tmp

banner "Fetching Cluster Certificate"
# Fetch the public key from the cluster
if ! kubeseal --fetch-cert \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=flux-system \
    > .tmp/pub-sealed-secrets.pem; then
    echo "Error: Failed to fetch public key from cluster"
    rm -rf .tmp
    exit 1
fi
echo "✅ Successfully retrieved public key"

banner "Sealing Secrets"
# Create the target directory
mkdir -p "$TARGET_PATH"

# Find all YAML files in the unsealed directory
SEAL_SUCCESS=true
find "$UNSEALED_PATH" -type f -name "*.yaml" | while read -r file; do
    # Get relative path to maintain directory structure
    rel_path=${file#"$UNSEALED_PATH/"}
    target_file="$TARGET_PATH/$rel_path"

    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target_file")"

    # Get just the filename without path
    filename=$(basename "$file")

    echo -n "🔒 Sealing secret: $filename"

    if kubeseal --format=yaml --cert=.tmp/pub-sealed-secrets.pem < "$file" > "$target_file" 2>/dev/null; then
        echo -e "\r✅ Sealed secret: $filename    "
    else
        echo -e "\r❌ Failed to seal secret: $filename"
        SEAL_SUCCESS=false
        continue
    fi
done

# Cleanup
rm -rf .tmp

banner "Sealing Complete"
echo "Sealed versions of secrets can be found in: $TARGET_PATH"

if [ "$SEAL_SUCCESS" = true ]; then
    rm -rf "$UNSEALED_PATH"
    echo "✨ Cleaned up unsealed secrets directory: $UNSEALED_PATH"
fi