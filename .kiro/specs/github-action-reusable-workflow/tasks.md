# Implementation Plan

- [x] 1. Create the reusable workflow file structure
  - Create the `.github/workflows/` directory if it doesn't exist
  - Create the main reusable workflow YAML file with proper naming convention
  - Set up the basic workflow_call trigger structure with metadata
  - _Requirements: 4.1, 4.3_

- [x] 2. Configure workflow inputs, secrets, and outputs
  - Define the inputs section with environment, cfn-directory, and ci-build parameters
  - Configure the secrets section for aws-role-arn, infracost-api-key, and infracost-gist-id
  - Set up the outputs section to expose template-path from execution-path job
  - Add proper descriptions and default values for all parameters
  - _Requirements: 1.2, 1.3, 1.4, 4.2_

- [x] 3. Set up workflow permissions and environment variables
  - Configure id-token: write and contents: write permissions
  - Preserve all environment variable definitions from the original workflow
  - Ensure proper permission inheritance for all jobs43
  - _Requirements: 1.1, 5.2_

- [x] 4. Implement the detect-changes job
  - Copy the detect-changes job exactly from the original workflow
  - Maintain all outputs: files-changed, json-output, has-changes
  - Preserve the conditional logic for non-main branch execution
  - Keep the subhamay-bhattacharyya-gha/list-updated-files-action integration
  - _Requirements: 1.1, 3.3_

- [x] 5. Implement the detect-services job
  - Copy the detect-services job from the original workflow
  - Maintain the services-used output and AWS service detection table
  - Preserve the checkout action and scan action integration
  - Keep all environment variable handling and JSON parsing logic
  - _Requirements: 1.1, 3.3_

- [x] 6. Implement the execution-path job with updated dependencies
  - Copy the execution-path job structure from the original workflow
  - Update the needs array to only include [detect-services, detect-changes]
  - Remove any references to check-environments and check-branch-issue jobs
  - Maintain all outputs: execution-path and template-path
  - Preserve all CloudFormation template configuration reading logic
  - _Requirements: 2.3, 3.1, 3.2_

- [x] 7. Implement CloudFormation validation and linting jobs
  - Copy cloudformation-validate job with proper conditional execution
  - Copy cloudformation-lint job with cfn-lint integration
  - Maintain all AWS credential configuration and parameter handling
  - Preserve artifact upload/download logic for deployment parameters
  - Keep all conditional logic based on execution-path outputs
  - _Requirements: 1.1, 3.3, 5.3_

- [x] 8. Implement security scanning job
  - Copy the checkov-scan job with all security scanning functionality
  - Maintain Checkov integration and SARIF file generation
  - Preserve the report summarization and snippet generation
  - Keep all AWS credential configuration and soft-fail settings
  - _Requirements: 1.1, 3.3_

- [x] 9. Implement build jobs for AWS services
  - Copy build-lambda job with conditional execution based on execution-path
  - Copy build-lambda-layer job with proper conditional logic
  - Copy build-glue job with Glue script packaging functionality
  - Copy build-state-machine job with Step Functions ASL handling
  - Maintain all dependencies on execution-path, detect-services, and detect-changes
  - _Requirements: 1.1, 3.3, 5.3_

- [x] 10. Implement CloudFormation deployment jobs
  - Copy cloudformation-create job with stack creation/update functionality
  - Copy cloudformation-delete job with cleanup functionality
  - Maintain all artifact handling for deployment parameters
  - Preserve AWS credential configuration and parameter reading logic
  - Keep all conditional execution based on previous job success
  - _Requirements: 1.1, 3.3, 5.3_

- [x] 11. Implement release creation job
  - Replace create-pull-request job with create-release job functionality
  - Use subhamay-bhattacharyya-gha/create-release-action@feature/GHA-0002-initial-release
  - Configure the job to use GITHUB_TOKEN secret for authentication
  - Update the conditional logic to exclude references to removed jobs
  - Maintain the always() condition with proper job result checking for all dependencies
  - _Requirements: 1.1, 3.2, 5.1_

- [x] 12. Validate and test the complete workflow
  - Review the entire workflow file for syntax errors and proper YAML formatting
  - Verify all job dependencies are correctly updated without excluded jobs
  - Check that all conditional logic works without references to removed jobs
  - Ensure all inputs, secrets, and outputs are properly configured
  - Test the workflow structure against GitHub Actions validation
  - _Requirements: 4.4, 5.1, 5.4_