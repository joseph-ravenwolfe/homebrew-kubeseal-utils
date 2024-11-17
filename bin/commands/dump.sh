#!/bin/bash

dump_usage() {
    echo
    echo "Dump Kubernetes sealed secrets into their unsealed form."
    echo
    echo "Usage:"
    echo "  $(basename "$0") dump <cluster-context> <secrets-path>"
    echo
    echo "Arguments:"
    echo "  cluster-context   The k8s cluster context to use (e.g. my-cluster)"
    echo "  secrets-path      Path to directory containing sealed secrets (relative or absolute)"
    echo
    echo "Examples:"
    echo "  # Dump secrets from config"
    echo "  $(basename "$0") dump my-cluster path/to/sealed/secrets"
    echo
    exit 1
}

# Show dump help if requested
if [ "$1" = "--help" ]; then
    dump_usage
fi

INTENDED_CONTEXT="$1"
SECRETS_PATH="$2"

if [ -z "$SECRETS_PATH" ]; then
    echo "Error: secrets path argument is required"
    dump_usage
fi

# Ensure secrets path exists and normalize it (remove trailing slash)
SECRETS_PATH="${SECRETS_PATH%/}"
if [ ! -d "$SECRETS_PATH" ]; then
    echo "Error: Secrets path $SECRETS_PATH does not exist or is not a directory"
    exit 1
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
echo "Using Secrets Path: $SECRETS_PATH"

mkdir -p .tmp

# Create the unsealed directory
UNSEALED_PATH="${SECRETS_PATH}-unsealed"
mkdir -p "$UNSEALED_PATH"

banner "Finding Sealed Secrets"
# Find all YAML files in the config folder
find "$SECRETS_PATH" -type f -name "*.yaml" | while read -r file; do
    # Get just the filename without path
    filename=$(basename "$file")

    # Check if file contains SealedSecret kind
    if ! yq eval '.kind == "SealedSecret"' "$file" >/dev/null 2>&1; then
        echo "⏭️ Skipping $filename - not a 'SealedSecret'"
        continue
    fi

    # Get the secret name and namespace from the file
    SECRET_NAME=$(yq eval '.metadata.name' "$file")
    SECRET_NAMESPACE=$(yq eval '.metadata.namespace' "$file")

    if [ -z "$SECRET_NAME" ]; then
        echo "⏭️ Skipping $filename - could not determine secret name"
        continue
    fi

    echo -n "🔑 Found Sealed Secret: $SECRET_NAME"

    # Get the current secret from the cluster and decode it
    TMP_FILE=".tmp/${SECRET_NAME}.yaml"
    if kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" -o yaml 2>/dev/null | ksd >"$TMP_FILE"; then
        # Check if secret is type Opaque
        SECRET_TYPE=$(yq eval '.type' "$TMP_FILE")

        # Keep only name and namespace in metadata, remove everything else
        yq eval -i '.metadata = {"name": .metadata.name, "namespace": .metadata.namespace}' "$TMP_FILE"

        # Sort the keys alphabetically in stringData if it exists
        if yq eval '.stringData' "$TMP_FILE" >/dev/null 2>&1; then
            yq eval -i '.stringData as $data | .stringData = ($data | to_entries | sort_by(.key) | from_entries)' "$TMP_FILE"
        fi

        # Save to unsealed folder with same relative path structure
        rel_path=${file#"$SECRETS_PATH/"}
        unsealed_path="$UNSEALED_PATH/$rel_path"
        mkdir -p "$(dirname "$unsealed_path")"
        cp "$TMP_FILE" "$unsealed_path"
        echo -e "\r✅ Unsealed Secret: $SECRET_NAME    "
    else
        echo -e "\r⚠️ Secret \`$SECRET_NAME\` not found, skipping"
    fi
done

rm -rf .tmp

banner "Unsealing Complete"
echo "Unsealed versions of secrets can be found in: $UNSEALED_PATH"
echo "⚠️ WARNING: These files contain sensitive data - do not commit them to git!"

# Add unsealed pattern to .gitignore if not already present
if ! grep -q "**/*-unsealed*" .gitignore 2>/dev/null; then
    echo -e "\n**/*-unsealed*" >> .gitignore
    echo "Added **/*-unsealed* pattern to .gitignore"
fi