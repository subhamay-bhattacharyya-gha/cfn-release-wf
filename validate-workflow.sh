#!/bin/bash

# Workflow Validation Script
# This script validates the CloudFormation CI Reusable Workflow

echo "=== CloudFormation CI Reusable Workflow Validation ==="
echo ""

WORKFLOW_FILE=".github/workflows/merge-pr.yaml"
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Function to log errors
log_error() {
    echo "❌ ERROR: $1"
    ((VALIDATION_ERRORS++))
}

# Function to log warnings
log_warning() {
    echo "⚠️  WARNING: $1"
    ((VALIDATION_WARNINGS++))
}

# Function to log success
log_success() {
    echo "✅ $1"
}

echo "1. Checking workflow file existence and basic structure..."
if [ ! -f "$WORKFLOW_FILE" ]; then
    log_error "Workflow file $WORKFLOW_FILE does not exist"
    exit 1
else
    log_success "Workflow file exists"
fi

echo ""
echo "2. Validating YAML syntax..."
if command -v yq >/dev/null 2>&1; then
    if yq eval '.' "$WORKFLOW_FILE" >/dev/null 2>&1; then
        log_success "YAML syntax is valid"
    else
        log_error "YAML syntax is invalid"
    fi
else
    if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>/dev/null; then
        log_success "YAML syntax is valid (verified with Python)"
    else
        log_error "YAML syntax is invalid"
    fi
fi

echo ""
echo "3. Checking workflow_call trigger configuration..."
if grep -q "workflow_call:" "$WORKFLOW_FILE"; then
    log_success "workflow_call trigger is configured"
else
    log_error "workflow_call trigger is missing"
fi

echo ""
echo "4. Validating inputs configuration..."
# Check required inputs
if grep -A 20 "inputs:" "$WORKFLOW_FILE" | grep -q "environment:"; then
    log_success "environment input is defined"
else
    log_error "environment input is missing"
fi

if grep -A 20 "inputs:" "$WORKFLOW_FILE" | grep -q "cfn-directory:"; then
    log_success "cfn-directory input is defined"
else
    log_error "cfn-directory input is missing"
fi

if grep -A 20 "inputs:" "$WORKFLOW_FILE" | grep -q "ci-build:"; then
    log_success "ci-build input is defined"
else
    log_error "ci-build input is missing"
fi

echo ""
echo "5. Validating secrets configuration..."
# Check required secrets
if grep -A 15 "secrets:" "$WORKFLOW_FILE" | grep -q "aws-role-arn:"; then
    log_success "aws-role-arn secret is defined"
else
    log_error "aws-role-arn secret is missing"
fi

# Infracost secrets removed as per requirements

echo ""
echo "6. Validating outputs configuration..."
if grep -A 10 "outputs:" "$WORKFLOW_FILE" | grep -q "template-path:"; then
    log_success "template-path output is defined"
else
    log_error "template-path output is missing"
fi

echo ""
echo "7. Checking permissions configuration..."
if grep -q "id-token: write" "$WORKFLOW_FILE"; then
    log_success "id-token: write permission is set"
else
    log_error "id-token: write permission is missing"
fi

if grep -q "contents: write" "$WORKFLOW_FILE"; then
    log_success "contents: write permission is set"
else
    log_error "contents: write permission is missing"
fi

echo ""
echo "8. Validating job dependencies (excluding removed jobs)..."

# Check that execution-path job only depends on detect-services and detect-changes
if grep -A 5 "execution-path:" "$WORKFLOW_FILE" | grep -A 3 "needs:" | grep -q "detect-services"; then
    log_success "execution-path depends on detect-services"
else
    log_error "execution-path missing dependency on detect-services"
fi

if grep -A 5 "execution-path:" "$WORKFLOW_FILE" | grep -A 3 "needs:" | grep -q "detect-changes"; then
    log_success "execution-path depends on detect-changes"
else
    log_error "execution-path missing dependency on detect-changes"
fi

# Check that excluded jobs are NOT referenced
if grep -q "check-environments" "$WORKFLOW_FILE"; then
    log_error "Excluded job 'check-environments' is still referenced in the workflow"
else
    log_success "Excluded job 'check-environments' is not referenced"
fi

if grep -q "check-branch-issue" "$WORKFLOW_FILE"; then
    log_error "Excluded job 'check-branch-issue' is still referenced in the workflow"
else
    log_success "Excluded job 'check-branch-issue' is not referenced"
fi

echo ""
echo "9. Checking required jobs are present..."
REQUIRED_JOBS=("detect-changes" "detect-services" "execution-path" "cloudformation-validate" "cloudformation-lint" "checkov-scan" "build-lambda" "build-lambda-layer" "build-glue" "build-state-machine" "cloudformation-create" "cloudformation-delete" "create-release")

for job in "${REQUIRED_JOBS[@]}"; do
    if grep -q "^  $job:" "$WORKFLOW_FILE"; then
        log_success "Job '$job' is present"
    else
        log_error "Required job '$job' is missing"
    fi
done

echo ""
echo "10. Validating conditional logic..."
# Check that conditional statements don't reference excluded jobs
if grep -E "(check-environments|check-branch-issue)" "$WORKFLOW_FILE" | grep -q "needs\."; then
    log_error "Conditional logic still references excluded jobs"
else
    log_success "No conditional logic references excluded jobs"
fi

echo ""
echo "11. Checking environment variables..."
if grep -q "ORG_SHORT_NAME:" "$WORKFLOW_FILE"; then
    log_success "ORG_SHORT_NAME environment variable is defined"
else
    log_error "ORG_SHORT_NAME environment variable is missing"
fi

if grep -q "AWS_REGION:" "$WORKFLOW_FILE"; then
    log_success "AWS_REGION environment variable is defined"
else
    log_error "AWS_REGION environment variable is missing"
fi

echo ""
echo "12. Validating create-release job configuration..."
if grep -A 10 "create-release:" "$WORKFLOW_FILE" | grep -q "subhamay-bhattacharyya-gha/create-release-action"; then
    log_success "create-release job uses correct action"
else
    log_error "create-release job action is incorrect or missing"
fi

# Check that create-release job has proper dependencies
if grep -A 5 "create-release:" "$WORKFLOW_FILE" | grep -A 3 "needs:" | grep -q "cloudformation-create"; then
    log_success "create-release depends on cloudformation-create"
else
    log_warning "create-release may be missing dependency on cloudformation-create"
fi

echo ""
echo "=== Validation Summary ==="
echo "Errors: $VALIDATION_ERRORS"
echo "Warnings: $VALIDATION_WARNINGS"

if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo ""
    echo "🎉 Workflow validation completed successfully!"
    echo "The reusable workflow is properly configured and ready for use."
    exit 0
else
    echo ""
    echo "💥 Workflow validation failed with $VALIDATION_ERRORS errors."
    echo "Please fix the errors before using the workflow."
    exit 1
fi