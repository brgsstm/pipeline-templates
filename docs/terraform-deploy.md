# Terraform Deploy Infrastructure

Deploys infrastructure using Terraform with support for plan and apply operations, backend configuration, and variable management.

**Template:** `.github/workflows/terraform-deploy.yml`

## Features

- **Plan and Apply**: Supports both plan-only mode and full apply operations
- **Azure Backend**: Native support for Azure Storage backend with Entra Managed Identity
- **Variable Management**: Support for variable files and inline variables
- **Validation**: Automatic format checking and validation
- **Plan Summary**: Detailed plan summary in workflow output

## Example Usage

Add this workflow to your repository by creating a workflow file (e.g., `.github/workflows/deploy-infrastructure.yml`):

### Basic Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-infrastructure:
    permissions:
      actions: read
      contents: read
      id-token: write
    
    uses: brgsstm/pipeline-templates/.github/workflows/terraform-deploy.yml@main
    with:
      working-directory: "./infrastructure"
      terraform-version: "1.6.0"
      azure-resource-group: "rg-terraform-state"
      azure-storage-account: "stterraformstate"
      azure-container-name: "tfstate"
      azure-key: "prod/terraform.tfstate"
      var-files: "terraform.tfvars,prod.tfvars"
      plan-only: false
      auto-approve: false
    secrets:
      client-id: ${{ secrets.MI_CLIENT_ID }}
      tenant-id: ${{ secrets.ENTRA_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Plan-Only Example (for Pull Requests)

```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]

jobs:
  terraform-plan:
    permissions:
      actions: read
      contents: read
      id-token: write
    
    uses: brgsstm/pipeline-templates/.github/workflows/terraform-deploy.yml@main
    with:
      working-directory: "./infrastructure"
      azure-resource-group: "rg-terraform-state"
      azure-storage-account: "stterraformstate"
      azure-container-name: "tfstate"
      azure-key: "prod/terraform.tfstate"
      var-files: "terraform.tfvars"
      plan-only: true
    secrets:
      client-id: ${{ secrets.MI_CLIENT_ID }}
      tenant-id: ${{ secrets.ENTRA_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Input Parameters

### Required

- **`azure-resource-group`**: Azure resource group for Terraform state backend
- **`azure-storage-account`**: Azure storage account for Terraform state backend
- **`azure-container-name`**: Azure storage container for Terraform state backend

### Optional

#### General Settings

- **`working-directory`**: Path to Terraform working directory (default: `.`)
- **`terraform-version`**: Terraform version to use (default: `latest`)

#### Backend Configuration

- **`azure-key`**: State file key in Azure storage (default: `terraform.tfstate`)

#### Variables

- **`var-files`**: Comma-separated list of variable files (e.g., `terraform.tfvars,prod.tfvars`)
- **`variables`**: Terraform variables as JSON object
  - Example: `'{"environment":"prod","region":"eastus","instance_count":3}'`

#### Execution Mode

- **`plan-only`**: Only run `terraform plan`, do not apply (default: `false`)
  - Useful for pull requests or validation workflows
- **`auto-approve`**: Auto-approve `terraform apply` (default: `false`)
  - Use with caution - only enable for trusted environments

## Workflow Steps

1. **Checkout Repository**: Checks out the source code
2. **Setup Terraform**: Installs the specified Terraform version
3. **Log in to Azure**: Authenticates to Azure using Managed Identity
4. **Terraform Init**: Initializes Terraform with backend configuration
5. **Terraform Format Check**: Validates code formatting (non-blocking)
6. **Terraform Validate**: Validates Terraform configuration
7. **Terraform Plan**: Creates an execution plan
8. **Terraform Apply**: Applies the plan (if `plan-only` is `false`)
9. **Terraform Output**: Displays Terraform outputs (if apply was successful)

## Backend Configuration

This template supports **Azure Storage** backend only. The backend type should be defined in your Terraform code's `backend` block. The template provides configuration values via `-backend-config` flags.

### Azure Backend Setup

In your `main.tf` or `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    # Configuration provided via -backend-config flags
  }
}
```

Then provide configuration via workflow inputs:

```yaml
azure-resource-group: "rg-terraform-state"
azure-storage-account: "stterraformstate"
azure-container-name: "tfstate"
azure-key: "prod/terraform.tfstate"
```

The `azure-key` parameter allows you to use different state files for different environments (e.g., `prod/terraform.tfstate`, `dev/terraform.tfstate`).

## Variable Files and Variables

You can provide variables in two ways:

1. **Variable Files**: Use the `var-files` input for `.tfvars` files
   ```yaml
   var-files: "terraform.tfvars,prod.tfvars"
   ```

2. **Inline Variables**: Use the `variables` input for JSON-formatted variables
   ```yaml
   variables: '{"environment":"prod","region":"eastus","instance_count":3}'
   ```

Both methods can be used together - variable files are processed first, then inline variables override any conflicts.

## Plan-Only Mode

Set `plan-only: true` to run only `terraform plan` without applying changes. This is useful for:

- Pull request validation
- Previewing changes before deployment
- CI/CD pipelines where approval is required

When `plan-only` is `true`, the workflow will:
- Run `terraform init`
- Run `terraform validate`
- Run `terraform plan`
- **Skip** `terraform apply`
- **Skip** `terraform output`

## Auto-Approve

When `auto-approve: true`, the `terraform apply` step will automatically approve the plan without requiring manual confirmation. Use this with caution and only in trusted environments.

## Plan Summary

The workflow automatically generates a summary of the Terraform plan showing:
- Number of resources to add
- Number of resources to change
- Number of resources to destroy

This summary is displayed in the GitHub Actions workflow summary.

## Authentication

This template uses **Entra Managed Identity** for authentication. Ensure your Managed Identity has:

1. [Federated credentials suitable for use with your repository](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
2. Appropriate IAM roles for the resources you're deploying:
   - For Azure backends: `Storage Blob Data Contributor` role on the storage account
   - For deploying resources: Appropriate roles for the resources being created (e.g., `Contributor` on the target resource group)

See the [main README](../README.md) for details on setting up authentication.

## Best Practices

1. **Use Plan-Only for PRs**: Run `plan-only: true` on pull requests to preview changes
2. **Separate Environments**: Use different state file keys for different environments
3. **Variable Files**: Store environment-specific variables in `.tfvars` files
4. **Auto-Approve Carefully**: Only enable `auto-approve` in trusted environments
5. **Version Pinning**: Pin Terraform version for consistency across deployments
6. **Backend Security**: Ensure your backend storage has proper access controls

