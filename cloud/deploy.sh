#!/bin/bash

# ==============================================================================
# Cloud Deployment Script for MySQL Business-to-Schema
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="mysql-business-schema"
ENVIRONMENT="${ENVIRONMENT:-dev}"
DATABASE_EXAMPLE="${DATABASE_EXAMPLE:-ecommerce}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-aws}"
REGION="${REGION:-us-east-1}"

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "============================================================"
    echo "  MySQL Business-to-Schema Cloud Deployment"
    echo "============================================================"
    echo -e "${NC}"
}

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --provider PROVIDER    Cloud provider (aws|gcp|azure) [default: aws]"
    echo "  -e, --environment ENV      Environment (dev|staging|prod) [default: dev]"
    echo "  -d, --database EXAMPLE     Database example to deploy [default: ecommerce]"
    echo "  -r, --region REGION        Cloud region [default: us-east-1]"
    echo "  -a, --action ACTION        Action (deploy|destroy|status) [default: deploy]"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --provider aws --environment dev --database ecommerce"
    echo "  $0 -p gcp -e prod -d fintech -r us-central1"
    echo "  $0 -p azure -a destroy"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--provider)
                CLOUD_PROVIDER="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -d|--database)
                DATABASE_EXAMPLE="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -a|--action)
                ACTION="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    case $CLOUD_PROVIDER in
        aws)
            if ! command -v aws &> /dev/null; then
                echo -e "${RED}AWS CLI is not installed${NC}"
                echo "Install it from: https://aws.amazon.com/cli/"
                exit 1
            fi

            # Check AWS credentials
            if ! aws sts get-caller-identity &> /dev/null; then
                echo -e "${RED}AWS credentials not configured${NC}"
                echo "Run: aws configure"
                exit 1
            fi

            echo -e "${GREEN}✓ AWS CLI configured${NC}"
            ;;

        gcp)
            if ! command -v gcloud &> /dev/null; then
                echo -e "${RED}Google Cloud SDK is not installed${NC}"
                echo "Install it from: https://cloud.google.com/sdk/docs/install"
                exit 1
            fi

            if ! command -v terraform &> /dev/null; then
                echo -e "${RED}Terraform is not installed${NC}"
                echo "Install it from: https://www.terraform.io/downloads"
                exit 1
            fi

            # Check GCP authentication
            if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
                echo -e "${RED}GCP not authenticated${NC}"
                echo "Run: gcloud auth login"
                exit 1
            fi

            echo -e "${GREEN}✓ GCP SDK and Terraform configured${NC}"
            ;;

        azure)
            if ! command -v az &> /dev/null; then
                echo -e "${RED}Azure CLI is not installed${NC}"
                echo "Install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
                exit 1
            fi

            # Check Azure login
            if ! az account show &> /dev/null; then
                echo -e "${RED}Not logged in to Azure${NC}"
                echo "Run: az login"
                exit 1
            fi

            echo -e "${GREEN}✓ Azure CLI configured${NC}"
            ;;

        *)
            echo -e "${RED}Invalid cloud provider: $CLOUD_PROVIDER${NC}"
            exit 1
            ;;
    esac
}

# Deploy to AWS
deploy_aws() {
    echo -e "${BLUE}Deploying to AWS...${NC}"

    STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-stack"
    TEMPLATE_FILE="cloud/aws/cloudformation-mysql.yaml"

    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        echo -e "${YELLOW}Stack $STACK_NAME already exists. Updating...${NC}"
        ACTION="update-stack"
        WAIT_ACTION="stack-update-complete"
    else
        echo -e "${GREEN}Creating new stack: $STACK_NAME${NC}"
        ACTION="create-stack"
        WAIT_ACTION="stack-create-complete"
    fi

    # Generate secure password
    DB_PASSWORD=$(openssl rand -base64 32)

    # Deploy CloudFormation stack
    aws cloudformation $ACTION \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            ParameterKey=DatabaseExample,ParameterValue="$DATABASE_EXAMPLE" \
            ParameterKey=DBMasterPassword,ParameterValue="$DB_PASSWORD" \
            ParameterKey=EnableStreaming,ParameterValue=true \
        --capabilities CAPABILITY_IAM \
        --region "$REGION"

    echo -e "${YELLOW}Waiting for stack operation to complete...${NC}"
    aws cloudformation wait $WAIT_ACTION --stack-name "$STACK_NAME" --region "$REGION"

    echo -e "${GREEN}✓ AWS deployment complete!${NC}"

    # Get outputs
    echo -e "${BLUE}Stack Outputs:${NC}"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table

    # Save credentials
    echo -e "${YELLOW}Saving credentials to secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json${NC}"
    mkdir -p secrets
    cat > "secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json" << EOF
{
    "provider": "aws",
    "environment": "$ENVIRONMENT",
    "region": "$REGION",
    "stack_name": "$STACK_NAME",
    "database_password": "$DB_PASSWORD"
}
EOF
    chmod 600 "secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json"
}

# Deploy to GCP
deploy_gcp() {
    echo -e "${BLUE}Deploying to Google Cloud Platform...${NC}"

    cd cloud/gcp

    # Get project ID
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}No GCP project selected${NC}"
        echo "Run: gcloud config set project PROJECT_ID"
        exit 1
    fi

    # Initialize Terraform
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    terraform init

    # Generate secure password
    DB_PASSWORD=$(openssl rand -base64 32)

    # Create terraform.tfvars
    cat > terraform.tfvars << EOF
project_id       = "$PROJECT_ID"
region           = "$REGION"
environment      = "$ENVIRONMENT"
project_name     = "$PROJECT_NAME"
database_example = "$DATABASE_EXAMPLE"
db_password      = "$DB_PASSWORD"
enable_streaming = true
EOF

    # Plan deployment
    echo -e "${YELLOW}Planning Terraform deployment...${NC}"
    terraform plan -out=tfplan

    # Apply deployment
    echo -e "${GREEN}Applying Terraform configuration...${NC}"
    terraform apply tfplan

    echo -e "${GREEN}✓ GCP deployment complete!${NC}"

    # Get outputs
    echo -e "${BLUE}Terraform Outputs:${NC}"
    terraform output

    # Save credentials
    cd ../..
    echo -e "${YELLOW}Saving credentials to secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json${NC}"
    mkdir -p secrets
    cat > "secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json" << EOF
{
    "provider": "gcp",
    "environment": "$ENVIRONMENT",
    "region": "$REGION",
    "project_id": "$PROJECT_ID",
    "database_password": "$DB_PASSWORD"
}
EOF
    chmod 600 "secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json"
}

# Deploy to Azure
deploy_azure() {
    echo -e "${BLUE}Deploying to Azure...${NC}"

    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    RESOURCE_GROUP="${PROJECT_NAME}-${ENVIRONMENT}-rg"
    DEPLOYMENT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-deployment"
    TEMPLATE_FILE="cloud/azure/azuredeploy.json"

    # Create resource group if it doesn't exist
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        echo -e "${GREEN}Creating resource group: $RESOURCE_GROUP${NC}"
        az group create --name "$RESOURCE_GROUP" --location "$REGION"
    fi

    # Generate secure password
    DB_PASSWORD=$(openssl rand -base64 32)

    # Deploy ARM template
    echo -e "${YELLOW}Deploying ARM template...${NC}"
    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --parameters \
            projectName="$PROJECT_NAME" \
            environment="$ENVIRONMENT" \
            databaseExample="$DATABASE_EXAMPLE" \
            administratorLoginPassword="$DB_PASSWORD" \
            enableStreaming=true

    echo -e "${GREEN}✓ Azure deployment complete!${NC}"

    # Get outputs
    echo -e "${BLUE}Deployment Outputs:${NC}"
    az deployment group show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs \
        --output table

    # Save credentials
    echo -e "${YELLOW}Saving credentials to secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json${NC}"
    mkdir -p secrets
    cat > "secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json" << EOF
{
    "provider": "azure",
    "environment": "$ENVIRONMENT",
    "region": "$REGION",
    "subscription_id": "$SUBSCRIPTION_ID",
    "resource_group": "$RESOURCE_GROUP",
    "database_password": "$DB_PASSWORD"
}
EOF
    chmod 600 "secrets/${CLOUD_PROVIDER}-${ENVIRONMENT}.json"
}

# Destroy deployment
destroy_deployment() {
    echo -e "${RED}Destroying ${CLOUD_PROVIDER} deployment...${NC}"

    case $CLOUD_PROVIDER in
        aws)
            STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-stack"
            echo -e "${YELLOW}Deleting CloudFormation stack: $STACK_NAME${NC}"
            aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
            echo -e "${YELLOW}Waiting for stack deletion...${NC}"
            aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"
            echo -e "${GREEN}✓ AWS resources destroyed${NC}"
            ;;

        gcp)
            cd cloud/gcp
            echo -e "${YELLOW}Destroying Terraform resources...${NC}"
            terraform destroy -auto-approve
            cd ../..
            echo -e "${GREEN}✓ GCP resources destroyed${NC}"
            ;;

        azure)
            RESOURCE_GROUP="${PROJECT_NAME}-${ENVIRONMENT}-rg"
            echo -e "${YELLOW}Deleting resource group: $RESOURCE_GROUP${NC}"
            az group delete --name "$RESOURCE_GROUP" --yes --no-wait
            echo -e "${GREEN}✓ Azure resource deletion initiated${NC}"
            ;;
    esac
}

# Get deployment status
get_status() {
    echo -e "${BLUE}Checking ${CLOUD_PROVIDER} deployment status...${NC}"

    case $CLOUD_PROVIDER in
        aws)
            STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-stack"
            aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" \
                --region "$REGION" \
                --query 'Stacks[0].StackStatus' \
                --output text 2>/dev/null || echo "Stack not found"
            ;;

        gcp)
            cd cloud/gcp
            terraform show -no-color | head -20
            cd ../..
            ;;

        azure)
            RESOURCE_GROUP="${PROJECT_NAME}-${ENVIRONMENT}-rg"
            az group show --name "$RESOURCE_GROUP" --query properties.provisioningState -o tsv 2>/dev/null || echo "Resource group not found"
            ;;
    esac
}

# Main execution
main() {
    print_banner
    parse_args "$@"
    check_prerequisites

    ACTION="${ACTION:-deploy}"

    case $ACTION in
        deploy)
            echo -e "${GREEN}Starting deployment...${NC}"
            echo "Provider: $CLOUD_PROVIDER"
            echo "Environment: $ENVIRONMENT"
            echo "Database Example: $DATABASE_EXAMPLE"
            echo "Region: $REGION"
            echo ""

            case $CLOUD_PROVIDER in
                aws)
                    deploy_aws
                    ;;
                gcp)
                    deploy_gcp
                    ;;
                azure)
                    deploy_azure
                    ;;
            esac
            ;;

        destroy)
            read -p "Are you sure you want to destroy all resources? (yes/no): " -r
            if [[ $REPLY =~ ^[Yy]es$ ]]; then
                destroy_deployment
            else
                echo "Destruction cancelled"
            fi
            ;;

        status)
            get_status
            ;;

        *)
            echo -e "${RED}Invalid action: $ACTION${NC}"
            usage
            exit 1
            ;;
    esac

    echo -e "${GREEN}"
    echo "============================================================"
    echo "  Deployment Complete!"
    echo "============================================================"
    echo -e "${NC}"
}

# Run main function
main "$@"