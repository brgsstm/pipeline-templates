# Pipeline Templates

Reusable GitHub Actions workflow templates for building, scanning, and publishing artifacts to Azure services. These templates provide secure, automated workflows using Entra Managed Identity for authentication.

## Overview

This repository contains GitHub Actions workflow templates designed for secure Azure deployment workflows. All templates use Entra Managed Identity for authentication, eliminating the need for static credentials.

### Common Features

- **Managed Identity Authentication**: Secure authentication via Entra Managed Identity (no static credentials)
- **Automatic Tagging**: Smart versioning based on branch (latest for main/master, commit SHA for others)
- **Security-First**: Built-in security scanning and best practices
- **Configurable**: Flexible inputs for different use cases

## Available Templates

### 1. Container Build, Scan & Publish

Builds Docker container images, scans them for vulnerabilities using Trivy, and publishes them to Azure Container Registry.

**Template:** `.github/workflows/container-build-scan-publish.yml`

#### Container Template: Features

- **Security-First**: All images are scanned with Trivy before publication
- **Automatic Tagging**: Smart image tagging based on branch (latest for main/master, commit SHA for others)
- **Configurable Scanning**: Adjustable vulnerability severity thresholds (default: CRITICAL, HIGH)
- **Fail on Vulnerabilities**: Optional workflow failure when vulnerabilities exceed thresholds
- **Docker Buildx**: Uses Docker Buildx for advanced build features

#### Container Template: Example Usage

Add this workflow to your repository by creating a workflow file (e.g., `.github/workflows/build.yml`):

```yaml
name: Build and Publish Container

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-publish:
    permissions:
      actions: read
      contents: read
      id-token: write
      security-events: write
      
    uses: brgsstm/pipeline-templates/.github/workflows/container-build-scan-publish.yml@main
    with:
      image-name: my-app
      dockerfile-path: "./Dockerfile"
      build-context: "."
      acr-registry: "myregistry.azurecr.io"
      trivy-severity: "CRITICAL,HIGH"
      fail-on-vulnerabilities: true
      build-args: '{"NODE_ENV":"production"}'
    secrets:
      client-id: ${{ secrets.MI_CLIENT_ID }}
      tenant-id: ${{ secrets.ENTRA_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

#### Container Template: Input Parameters

**Required:**

- **`image-name`**: Name of the container image (e.g., `my-app`)
- **`acr-registry`**: Azure Container Registry name (e.g., `myregistry.azurecr.io`)

**Optional:**

- **`dockerfile-path`**: Path to Dockerfile (default: `./Dockerfile`)
- **`build-context`**: Build context path (default: `.`)
- **`image-tag`**: Specific tag for the image (default: auto-determined from branch)
  - `main`/`master` branches → `latest`
  - Other branches → commit SHA
- **`trivy-severity`**: Comma-separated severity levels to check (default: `CRITICAL,HIGH`)
  - Options: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `UNKNOWN`
- **`fail-on-vulnerabilities`**: Fail workflow if vulnerabilities found (default: `true`)
- **`build-args`**: Docker build arguments as JSON object (default: `{}`)
  - Example: `'{"NODE_ENV":"production","VERSION":"1.0.0"}'`

#### Container Template: Workflow Steps

1. **Checkout Repository**: Checks out the source code
2. **Set up Docker Buildx**: Configures Docker Buildx for builds
3. **Determine Image Tag**: Sets the image tag based on branch or provided value
4. **Build Container Image**: Builds the Docker image
5. **Run Trivy Scanner**: Scans the built image for vulnerabilities
6. **Fail if Vulnerabilities Found**: Stops workflow if vulnerabilities exceed threshold
7. **Log in to Azure**: Authenticates to Azure using Managed Identity
8. **Log in to ACR**: Authenticates to Azure Container Registry
9. **Publish to ACR**: Tags and pushes the image (only if scan passed or failures allowed)

#### Container Template: Security Scanning

The workflow uses [Trivy](https://github.com/aquasecurity/trivy) to scan container images for:

- Known vulnerabilities in base images and dependencies
- Misconfigurations
- Security best practices

Scan results are displayed in the workflow logs. If `fail-on-vulnerabilities` is `true` and vulnerabilities exceed the severity threshold, the workflow will fail before publishing the image.

---

### 2. Function App Package & Publish

Packages Python-based Azure Functions into a zip file and publishes it to an Azure Storage Account blob container for use with `WEBSITE_RUN_FROM_PACKAGE` app setting.

**Template:** `.github/workflows/function-app-package-publish.yml`

#### Function App Template: Features

- **Python Support**: Configurable Python version (default: 3.13)
- **Dependency Management**: Automatically installs dependencies from `requirements.txt`
- **Azure Functions Structure**: Packages dependencies in `.python_packages/lib/site-packages` format
- **Automatic Tagging**: Smart package tagging based on branch (latest for main/master, commit SHA for others)
- **Blob URL Output**: Generates blob URL for direct use in Function App settings

#### Function App Template: Example Usage

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

#### Function App Template: Input Parameters

**Required:**

- **`function-app-name`**: Name of the Azure Function App
- **`storage-account-name`**: Azure Storage Account name
- **`storage-container-name`**: Azure Storage blob container name
- **`storage-resource-group`**: Resource group containing the storage account

**Optional:**

- **`package-name`**: Name for the package/zip file (default: function-app-name)
- **`source-path`**: Path to the function app source code (default: `.`)
- **`requirements-path`**: Path to requirements.txt file (default: `./requirements.txt`)
- **`python-version`**: Python version to use (default: `3.13`)
- **`package-tag`**: Tag for the package (default: auto-determined from branch)
  - `main`/`master` branches → `latest`
  - Other branches → commit SHA

#### Function App Template: Workflow Steps

1. **Checkout Repository**: Checks out the source code
2. **Set up Python**: Configures the specified Python version
3. **Determine Package Name**: Sets package name based on function app name or provided value
4. **Determine Package Tag**: Sets package tag based on branch or provided value
5. **Install Dependencies**: Installs Python packages from requirements.txt to `.python_packages/lib/site-packages`
6. **Create Deployment Package**: Creates zip file excluding unnecessary files (git, cache, etc.)
7. **Log in to Azure**: Authenticates to Azure using Managed Identity
8. **Upload Package to Azure Storage**: Uploads zip file to blob container
9. **Output Package Information**: Displays blob URL and usage instructions

#### Function App Template: Package Structure

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

#### Function App Template: Using the Published Package

After the workflow completes, use the generated blob URL in your Function App's `WEBSITE_RUN_FROM_PACKAGE` app setting:

```bash
az functionapp config appsettings set \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --settings WEBSITE_RUN_FROM_PACKAGE="<blob-url>"
```

The blob URL is displayed in the workflow summary and can also be accessed via the `blob-url` output from the `upload-package` step.

---

## Authentication

All templates use **Entra Managed Identity** for authentication. This approach:

- Eliminates the need for static service principal credentials
- Uses workload identity federation for secure, credentialless authentication
- Automatically rotates credentials
- Follows security best practices

### Required Secrets

Configure the following secrets in your repository settings:

- **`MI_CLIENT_ID`**: Entra Managed Identity client ID
- **`ENTRA_TENANT_ID`**: Entra tenant ID
- **`AZURE_SUBSCRIPTION_ID`**: Azure subscription ID

### Managed Identity Setup

Ensure your Managed Identity has:

1. [Federated credentials suitable for use with your repository](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
2. Appropriate IAM roles:
   - **Container templates**: `AcrPush` role on the Azure Container Registry
   - **Function App templates**: `Storage Blob Data Contributor` role on the Azure Storage Account

---

## Examples

See the `examples/` directory for example Dockerfiles and usage patterns.
