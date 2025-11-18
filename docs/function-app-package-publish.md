# Publish Azure Python Function App Artifact

Packages Python-based Azure Functions into a zip file and publishes it to an Azure Storage Account blob container for use with `WEBSITE_RUN_FROM_PACKAGE` app setting.

**Template:** `.github/workflows/function-app-package-publish.yml`

## Features

- **Python Support**: Configurable Python version (default: 3.13)
- **Dependency Management**: Automatically installs dependencies from `requirements.txt`
- **Azure Functions Structure**: Packages dependencies in `.python_packages/lib/site-packages` format
- **Automatic Tagging**: Smart package tagging based on branch (latest for main/master, commit SHA for others)
- **Blob URL Output**: Generates blob URL for direct use in Function App settings

## Example Usage

Add this workflow to your repository by creating a workflow file (e.g., `.github/workflows/deploy-function-artifact.yml`):

```yaml
name: Build and Publish Function App Artifact

on:
  push:
    branches: [main, develop]

jobs:
  build-and-publish-function-artifact:
    permissions:
      actions: read
      contents: read
      id-token: write
    
    uses: brgsstm/pipeline-templates/.github/workflows/function-app-package-publish.yml@main
    with:
      function-app-name: my-function-app
      storage-account-name: mystorageaccount
      storage-container-name: function-packages
      storage-resource-group: my-resource-group
      python-version: "3.13"
    secrets:
      client-id: ${{ secrets.MI_CLIENT_ID }}
      tenant-id: ${{ secrets.ENTRA_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Input Parameters

### Required

- **`function-app-name`**: Name of the Azure Function App
- **`storage-account-name`**: Azure Storage Account name
- **`storage-container-name`**: Azure Storage blob container name
- **`storage-resource-group`**: Resource group containing the storage account

### Optional

- **`package-name`**: Name for the package/zip file (default: function-app-name)
- **`source-path`**: Path to the function app source code (default: `.`)
- **`requirements-path`**: Path to requirements.txt file (default: `./requirements.txt`)
- **`python-version`**: Python version to use (default: `3.13`)
- **`package-tag`**: Tag for the package (default: auto-determined from branch)
  - `main`/`master` branches → `latest`
  - Other branches → commit SHA

## Workflow Steps

1. **Checkout Repository**: Checks out the source code
2. **Set up Python**: Configures the specified Python version
3. **Determine Package Name**: Sets package name based on function app name or provided value
4. **Determine Package Tag**: Sets package tag based on branch or provided value
5. **Install Dependencies**: Installs Python packages from requirements.txt to `.python_packages/lib/site-packages`
6. **Create Deployment Package**: Creates zip file excluding unnecessary files (git, cache, etc.)
7. **Log in to Azure**: Authenticates to Azure using Managed Identity
8. **Upload Package to Azure Storage**: Uploads zip file to blob container
9. **Output Package Information**: Displays blob URL and usage instructions

## Package Structure

The workflow creates a zip file containing:

- Function code (all Python files and function.json files)
- Dependencies in `.python_packages/lib/site-packages` directory
- `host.json` and other configuration files

The zip file excludes:

- Git files and directories
- Python cache files (`__pycache__`, `*.pyc`)
- Development files (`.vscode`, `.idea`, etc.)
- Environment files (`.env`)
- Log files

## Using the Published Package

After the workflow completes, use the generated blob URL in your Function App's `WEBSITE_RUN_FROM_PACKAGE` app setting:

```bash
az functionapp config appsettings set \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --settings WEBSITE_RUN_FROM_PACKAGE="<blob-url>"
```

The blob URL is displayed in the workflow summary and can also be accessed via the `blob-url` output from the `upload-package` step.

## Authentication

This template uses **Entra Managed Identity** for authentication. Ensure your Managed Identity has:

1. [Federated credentials suitable for use with your repository](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
2. The `Storage Blob Data Contributor` IAM role on the Azure Storage Account

See the [main README](../README.md) for details on setting up authentication.
