# Design Document

## Overview

This design outlines the creation of a reusable GitHub Action workflow that transforms an existing CloudFormation CI pipeline into a shareable component. The workflow will exclude the "check-environments" and "check-branch-issue" jobs while maintaining all other functionality including change detection, service scanning, validation, linting, security scanning, building, and deployment operations.

## Architecture

### Workflow Structure
The reusable workflow will follow GitHub Actions' `workflow_call` pattern, allowing it to be invoked from other workflows. The architecture maintains the original job dependency graph with modifications to handle the removal of the two excluded jobs.

### Job Dependency Flow
```
detect-changes ──┐
                 ├── execution-path ──┐
detect-services ─┘                   │
                                     ├── cloudformation-validate
                                     ├── cloudformation-lint  
                                     └── checkov-scan
                                            │
                                            ├── build-lambda
                                            ├── build-lambda-layer
                                            ├── build-glue
                                            ├── build-state-machine
                                            │
                                            └── cloudformation-create
                                                   │
                                                   └── cloudformation-delete
                                                          │
                                                          └── create-release
```

## Components and Interfaces

### Input Interface
The workflow will accept the same inputs as the original:
- `environment` (required): Target deployment environment
- `cfn-directory` (required): CloudFormation templates directory (default: 'cfn')
- `ci-build` (optional): CI build flag (default: true)

### Secrets Interface
The workflow will require the same secrets:
- `aws-role-arn`: AWS IAM role for authentication
- `infracost-api-key`: Infracost service API key
- `infracost-gist-id`: Gist ID for Infracost output storage

### Output Interface
The workflow will provide:
- `template-path`: Path to the CloudFormation template file

### Job Components

#### Core Detection Jobs
- **detect-changes**: Identifies modified files in the repository
- **detect-services**: Scans for AWS services used in templates
- **execution-path**: Determines execution strategy based on changes and services

#### Validation and Quality Jobs
- **cloudformation-validate**: Validates CloudFormation templates
- **cloudformation-lint**: Lints CloudFormation templates using cfn-lint
- **checkov-scan**: Performs security and compliance scanning

#### Build Jobs
- **build-lambda**: Packages Lambda functions
- **build-lambda-layer**: Packages Lambda layers
- **build-glue**: Packages Glue scripts
- **build-state-machine**: Packages Step Functions state machines

#### Deployment Jobs
- **cloudformation-create**: Creates/updates CloudFormation stacks
- **cloudformation-delete**: Cleans up test stacks
- **create-release**: Generates release tags for successful deployments

## Data Models

### Workflow Inputs Schema
```yaml
inputs:
  environment:
    type: string
    required: true
    description: "Environment to deploy to (e.g., ci, devl, test, prod)."
  cfn-directory:
    type: string
    required: true
    default: 'cfn'
    description: "Directory containing CloudFormation template files."
  ci-build:
    type: boolean
    required: false
    default: true
    description: "Indicates if this is a CI build run."
```

### Secrets Schema
```yaml
secrets:
  aws-role-arn:
    required: true
    description: "AWS role ARN for assuming a role."
  infracost-api-key:
    required: true
    description: "API key for Infracost."
  infracost-gist-id:
    required: true
    description: "Gist ID for Infracost output."
```

### Job Outputs Schema
```yaml
outputs:
  template-path:
    description: "Path to the CloudFormation template file"
    value: ${{ jobs.execution-path.outputs.template-path }}
```

## Error Handling

### Missing Dependencies
- Jobs that previously depended on excluded jobs will have their `needs` arrays updated
- The `execution-path` job will only depend on `detect-services` and `detect-changes`
- Conditional logic referencing excluded jobs will be removed or updated

### Artifact Management
- All artifact upload/download operations will remain unchanged
- Job dependencies will ensure proper artifact availability
- Error handling for missing artifacts will be preserved

### AWS Authentication
- AWS credential configuration will remain identical to the original
- Role assumption and session naming will be preserved
- Regional configuration will be maintained

## Testing Strategy

### Validation Testing
- Verify workflow syntax using GitHub Actions validation
- Test workflow_call trigger functionality
- Validate input/output parameter passing

### Integration Testing
- Test with sample CloudFormation templates
- Verify job execution order and dependencies
- Test conditional job execution based on change detection

### Regression Testing
- Compare outputs with original workflow (excluding removed jobs)
- Verify all artifacts are created correctly
- Test error scenarios and failure handling

### End-to-End Testing
- Test complete workflow execution in a test repository
- Verify AWS integration and authentication
- Test with different input combinations and environments

## Implementation Considerations

### Job Dependency Updates
The `execution-path` job's `needs` array must be updated from:
```yaml
needs: [check-environments, check-branch-issue, detect-services, detect-changes]
```
to:
```yaml
needs: [detect-services, detect-changes]
```

### Conditional Logic Cleanup
Any conditional statements or references to the excluded jobs must be identified and removed to prevent workflow failures.

### Permissions Preservation
The workflow will maintain the same permissions as the original:
```yaml
permissions:
  id-token: write
  contents: write
```

### Environment Variables
All environment variable usage will be preserved, including:
- `ORG_SHORT_NAME`
- `AWS_REGION`
- Dynamic variables set during execution