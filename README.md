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

### 1. [Container Build, Scan & Publish](docs/container-build-scan-publish.md)

Builds Docker container images, scans them for vulnerabilities using Trivy, and publishes them to Azure Container Registry.

**Template:** `.github/workflows/container-build-scan-publish.yml`

### 2. [Publish Azure Python Function App Artifact](docs/function-app-package-publish.md)

Packages Python-based Azure Functions into a zip file and publishes it to an Azure Storage Account blob container for use with `WEBSITE_RUN_FROM_PACKAGE` app setting.

**Template:** `.github/workflows/function-app-package-publish.yml`

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

## Examples

See the `examples/` directory for example Dockerfiles and usage patterns.
