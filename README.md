
# TerraSphere: Lightweight Terraform Wrapper

TerraSphere is a lightweight wrapper for Terraform commands designed to streamline the management of global configurations and backends across multiple small-scale Terraform projects. By centralizing backend and configuration handling, TerraSphere simplifies the use of shared resources and ensures consistency across all Terraform projects.

## Features

- **Global Backend Management**: Automatically handles backend configurations for your Terraform projects.
- **Centralized Provider and Tag Configurations**: Easily share provider and tagging configurations across projects.
- **Command-Specific Logic**: Ensures appropriate backend initialization and configuration based on the Terraform command.
- **Temporary Workspace**: Uses a temporary directory for all operations, ensuring that local project files remain untouched.
- **Customizable Paths**: Supports configurable paths for global settings and backend configurations.

## Why Use TerraSphere?

TerraSphere is designed for teams or individuals managing multiple small Terraform projects that share a common backend and provider configurations. It reduces duplication, enforces consistency, and provides a seamless experience for running Terraform commands.

## Requirements

- **Terraform**: Ensure Terraform is installed and accessible in your system's PATH.
- **Bash Shell**: TerraSphere is implemented as a Bash script and requires a Bash-compatible shell.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-repo/terra-sphere.git
   cd terra-sphere
   ```

2. Move the script to a directory in your PATH:

   ```bash
   mv terra_sphere.sh /usr/local/bin/tfs
   chmod +x /usr/local/bin/tfs
   ```

## Usage

### Basic Command Structure

Run Terraform commands using TerraSphere by replacing `terraform` with `tfs`:

```bash
tfs <command> [options]
```

### Example

```bash
tfs init
tfs plan -out=plan.out
tfs apply
```

### Help

To display usage information:

```bash
tfs --help
```

### Configuration

TerraSphere supports customizable paths for global configurations via the `TFCONFIGPATH` environment variable. If not set, the default path is `$HOME/.terraform`.

#### Global Configuration Files

- `backend.hcl`: Defines backend-specific settings.
- `provider.tf`: Shared provider configurations.
- `tags.tf`: Common tagging configurations.

#### Temporary Directory

TerraSphere creates a temporary directory for each command execution to isolate global and local configurations. The directory is automatically cleaned up after the command completes.

## How It Works

1. **Backend Handling**:
   - Detects the backend type (e.g., S3, local) from `backend.hcl`.
   - Creates a `backend.tf` file in the temporary workspace with the appropriate configuration.

2. **Command Detection**:
   - Identifies whether the command requires backend initialization.
   - Executes `terraform init` with `-backend-config` if needed.

3. **Temporary Workspace**:
   - Symlinks local project files (excluding `backend.tf`) to a temporary directory.
   - Adds global configurations (e.g., provider and tags) if available.

4. **Command Execution**:
   - Executes the Terraform command in the temporary directory with the appropriate settings.

## Commands Supported

TerraSphere supports the following Terraform commands with backend configurations:

- `init`
- `import`
- `state`
- `refresh`
- `force-unlock`
- `workspace`
- `plan`
- `apply`
- `destroy`

Other commands are passed through directly without additional processing.

## Contributing

We welcome contributions to improve TerraSphere! Feel free to submit issues, feature requests, or pull requests on [GitHub](https://github.com/your-repo/terra-sphere).

## License

TerraSphere is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgments

Special thanks to the Terraform community for providing robust tools and practices for infrastructure as code.
