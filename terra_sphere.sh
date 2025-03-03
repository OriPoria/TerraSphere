#!/bin/bash

# Set config path based on environment variable
CONFIG_PATH="${TFSCONFIGPATH:-$HOME/.terraform}"

# Configuration
GLOBAL_BACKEND_HCL="${CONFIG_PATH}/backend.hcl"
GLOBAL_PROVIDER_CONFIG="${CONFIG_PATH}/provider.tf"
GLOBAL_TAGS_CONFIG="${CONFIG_PATH}/tags.tf"



# Commands that need backend configuration
BACKEND_COMMANDS=(
    "init"
    "import"
    "state"
    "refresh"
    "force-unlock"
    "workspace"
    "plan"
    "apply"
    "destroy"
    "output"
)

# Function to check if command needs backend config
needs_backend() {
    local cmd="$1"
    for backend_cmd in "${BACKEND_COMMANDS[@]}"; do
        if [[ "$cmd" == "$backend_cmd"* ]]; then
            return 0
        fi
    done
    return 1
}
# Check if help is needed
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ -z "$1" ]; then
    show_usage
    exit 0
fi

# Store the terraform command
TF_COMMAND="$1"
shift  # Remove the command from the arguments

# Default to current directory
WORKING_DIR=$(pwd)

NEW_ARGS=()


for arg in "$@"; do
    if [[ "$arg" == -chdir=* ]]; then
        WORKING_DIR=$(realpath "${arg#-chdir=}")  # Extract value after -chdir=
        if [[ ! -d "$WORKING_DIR" ]]; then
            echo "Error: Specified -chdir directory '$WORKING_DIR' does not exist."
            exit 1
        fi
    else
        NEW_ARGS+=("$arg")  # Keep all other arguments
    fi
done
# Create temporary working directory for symlinks
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
project_name=$(basename $WORKING_DIR)
echo "Project name: $project_name"


# Find all files and directories under WORKING_DIR except 'backend.tf'
find "$WORKING_DIR" -mindepth 1 ! -name 'backend.tf' -print0 | while IFS= read -r -d '' file; do
    # Create symbolic link in TEMP_DIR, maintaining structure
    relative_path="${file#$WORKING_DIR/}"  # Get relative path
    target_path="$TEMP_DIR/$relative_path"

    if [[ -d "$file" ]]; then
        # If it's a directory, create it in TEMP_DIR
        mkdir -p "$target_path"
    else
        # If it's a file, create a symlink
        ln -s "$file" "$target_path"
    fi
done

# Link global configurations if they exist
if [ -f "$GLOBAL_PROVIDER_CONFIG" ]; then
    ln -s "$GLOBAL_PROVIDER_CONFIG" "$TEMP_DIR/_provider.tf"
fi

if [ -f "$GLOBAL_TAGS_CONFIG" ]; then
    ln -s "$GLOBAL_TAGS_CONFIG" "$TEMP_DIR/_tags.tf"
fi


# Always create a backend.tf in the temp directory
if [ -f "$GLOBAL_BACKEND_HCL" ]; then
    # Read the backend type from the HCL file (first line should contain type)
    BACKEND_TYPE=$(grep -m1 "bucket\|container\|storage_account" "$GLOBAL_BACKEND_HCL" | cut -d'=' -f1 | xargs)
    if [ "$BACKEND_TYPE" = "bucket" ]; then

        BACKEND_TYPE="s3"
        sed -i "s/PROJECT/${project_name}/g" "$GLOBAL_BACKEND_HCL"
    else
        BACKEND_TYPE="local"  # default to local if type cannot be determined
    fi

    # Create backend.tf with the detected type
    cat > "$TEMP_DIR/backend.tf" << EOF
terraform {
  backend "$BACKEND_TYPE" {
        key="$project_name/state/terraform.tfstate"
}
}
EOF
else
    # Create a default local backend if no HCL file exists
    cat > "$TEMP_DIR/backend.tf" << EOF
terraform {
  backend "local" {}
}
EOF
fi
# Change to temporary directory
cd "$TEMP_DIR" || exit 1
# Check if we need to add backend configuration
if needs_backend "$TF_COMMAND"; then
    if [ -f "$GLOBAL_BACKEND_HCL" ]; then
        case "$TF_COMMAND" in
            "init")
                terraform init -backend-config="$GLOBAL_BACKEND_HCL" "${NEW_ARGS[@]}"
                ;;
            "import"|"state"|"refresh"|"force-unlock"|"workspace")
                # Ensure backend is initialized first
                terraform init -backend-config="$GLOBAL_BACKEND_HCL" -input=false > /dev/null
                terraform "$TF_COMMAND" "${NEW_ARGS[@]}"
                ;;
            *)
                # For other commands that need backend but don't take backend-config directly
                terraform init -backend-config="$GLOBAL_BACKEND_HCL" -input=false > /dev/null
                terraform "$TF_COMMAND" "${NEW_ARGS[@]}"
                ;;
        esac
    else
        # No backend config, just use local backend
        terraform "$TF_COMMAND" "${NEW_ARGS[@]}"
    fi
else
    # For commands that don't need backend config, just pass through
    terraform "$TF_COMMAND" "${NEW_ARGS[@]}"
fi
