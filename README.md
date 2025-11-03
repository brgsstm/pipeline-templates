# Pipeline Templates

Reusable GitHub Actions workflow templates for building, scanning, and publishing Docker container images to Azure Container Registry (ACR).

## Overview

This repository contains GitHub Actions workflow templates designed for secure container image workflows. The templates automate:

- **Docker Image Building**: Build container images using Docker Buildx
- **Security Scanning**: Scan images with Trivy vulnerability scanner before publication
- **Azure Container Registry Publishing**: Push scanned images to Azure Container Registry
- **Managed Identity Authentication**: Secure authentication using Azure Managed Identity

## Container Build, Scan & Publish

These workflow templates build Docker container images, scans them for vulnerabilities using Trivy, and publishes them to Azure Container Registry. The workflow uses Entra Managed Identity for secure authentication, eliminating the need for static credentials.

### Features

- **Security-First**: All images are scanned with Trivy before publication
- **Automatic Tagging**: Smart image tagging based on branch (latest for main/master, commit SHA for others)
- **Configurable Scanning**: Adjustable vulnerability severity thresholds (default: CRITICAL, HIGH)
- **Fail on Vulnerabilities**: Optional workflow failure when vulnerabilities exceed thresholds
- **Managed Identity**: Secure authentication via Entra Managed Identity (no static credentials)
- **Docker Buildx**: Uses Docker Buildx for advanced build features

### Example Usage

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

### Required Secrets

Configure the following secrets in your repository settings:

- **`MI_CLIENT_ID`**: Entra Managed Identity client ID
- **`ENTRA_TENANT_ID`**: Entra tenant ID
- **`AZURE_SUBSCRIPTION_ID`**: Azure subscription ID (containing the ACR)
  - ensure that the MI posesses the AcrPush IAM role

### Input Parameters

#### Required

- **`image-name`**: Name of the container image (e.g., `my-app`)
- **`acr-registry`**: Azure Container Registry name (e.g., `myregistry.azurecr.io`)

#### Optional

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

### Workflow Steps

1. **Checkout Repository**: Checks out the source code
2. **Set up Docker Buildx**: Configures Docker Buildx for builds
3. **Determine Image Tag**: Sets the image tag based on branch or provided value
4. **Build Container Image**: Builds the Docker image
5. **Run Trivy Scanner**: Scans the built image for vulnerabilities
6. **Fail if Vulnerabilities Found**: Stops workflow if vulnerabilities exceed threshold
7. **Log in to Azure**: Authenticates to Azure using Managed Identity
8. **Log in to ACR**: Authenticates to Azure Container Registry
9. **Publish to ACR**: Tags and pushes the image (only if scan passed or failures allowed)

### Image Tagging

The workflow automatically creates two tags:

- **Version tag**: Based on branch/commit (e.g., `abc123def` or `latest`)
- **`latest` tag**: Always updated when publishing from main/master branch

Example: An image built from main branch will be tagged as both `myregistry.azurecr.io/my-app:latest` and `myregistry.azurecr.io/my-app:latest`.

### Security Scanning

The workflow uses [Trivy](https://github.com/aquasecurity/trivy) to scan container images for:

- Known vulnerabilities in base images and dependencies
- Misconfigurations
- Security best practices

Scan results are displayed in the workflow logs. If `fail-on-vulnerabilities` is `true` and vulnerabilities exceed the severity threshold, the workflow will fail before publishing the image.

### Authentication

Authentication to Azure and Azure Container Registry is performed using **Entra Managed Identity**. This approach:

- Eliminates the need for static service principal credentials
- Uses workload identity federation for secure, credentialless authentication
- Automatically rotates credentials
- Follows security best practices

Ensure your Managed Identity has [federated credentials suitable for use with your repository](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)

### Examples

See the `examples/` directory for example Dockerfiles and usage patterns.
