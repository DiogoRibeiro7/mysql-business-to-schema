# Cloud Deployment Templates for MySQL Business-to-Schema

Production-ready infrastructure-as-code templates for deploying MySQL Business-to-Schema on AWS, Azure, and Google Cloud Platform.

## 🚀 Overview

Complete cloud infrastructure templates including:
- **Multi-database support**: MySQL, PostgreSQL, MongoDB/DocumentDB/Cosmos DB
- **Container orchestration**: EKS, AKS, GKE
- **Streaming infrastructure**: Kafka/MSK, Event Hubs, Pub/Sub
- **Caching**: Redis, ElastiCache, Memorystore
- **Storage**: S3, Azure Storage, Cloud Storage
- **Security**: IAM, Key Vault, Secret Manager
- **Monitoring**: CloudWatch, Azure Monitor, Cloud Monitoring

## 📦 Components by Cloud Provider

### AWS (CloudFormation)
- **RDS MySQL** - Managed MySQL 8.0
- **RDS PostgreSQL** - Managed PostgreSQL 15
- **DocumentDB** - MongoDB-compatible database
- **Amazon MSK** - Managed Kafka streaming
- **ElastiCache Redis** - In-memory caching
- **ECS Fargate** - Serverless container platform
- **S3** - Object storage with lifecycle policies
- **Secrets Manager** - Secure credential storage
- **VPC** - Isolated network with public/private subnets

### Google Cloud Platform (Terraform)
- **Cloud SQL MySQL** - Managed MySQL 8.0
- **Cloud SQL PostgreSQL** - Managed PostgreSQL 15
- **Firestore** - NoSQL document database
- **Pub/Sub** - Message streaming service
- **Memorystore Redis** - Managed Redis
- **GKE** - Kubernetes Engine
- **Cloud Storage** - Object storage with lifecycle
- **Secret Manager** - Secure secrets management
- **VPC** - Custom network with Cloud NAT

### Microsoft Azure (ARM Template)
- **Azure Database for MySQL** - Managed MySQL
- **Azure Database for PostgreSQL** - Managed PostgreSQL
- **Cosmos DB** - Multi-model database with MongoDB API
- **Event Hubs** - Streaming platform
- **Azure Cache for Redis** - Managed Redis cache
- **AKS** - Azure Kubernetes Service
- **Azure Storage** - Blob storage
- **Key Vault** - Secrets and key management
- **VNet** - Virtual network with subnets

## 🛠️ Quick Start

### Prerequisites

1. **Install CLI Tools**:
   ```bash
   # AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip && sudo ./aws/install

   # Google Cloud SDK
   curl https://sdk.cloud.google.com | bash

   # Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Terraform (for GCP)
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/
   ```

2. **Configure Authentication**:
   ```bash
   # AWS
   aws configure

   # GCP
   gcloud auth login
   gcloud config set project PROJECT_ID

   # Azure
   az login
   az account set --subscription SUBSCRIPTION_ID
   ```

### Deploy with One Command

```bash
# Deploy to AWS
./cloud/deploy.sh --provider aws --environment dev --database ecommerce --region us-east-1

# Deploy to GCP
./cloud/deploy.sh --provider gcp --environment dev --database fintech --region us-central1

# Deploy to Azure
./cloud/deploy.sh --provider azure --environment dev --database social_media --region eastus
```

## 📋 Deployment Options

### Environments
- **dev**: Development environment (minimal resources, cost-optimized)
- **staging**: Staging environment (production-like, reduced redundancy)
- **prod**: Production environment (high availability, full redundancy)

### Database Examples
- **ecommerce**: E-commerce platform schema
- **fintech**: Financial services schema
- **social_media**: Social networking schema
- **iot_bins**: IoT waste management
- **healthcare_iot**: Healthcare monitoring
- **streaming_ml**: Streaming with ML features

### Resource Sizing

#### Development
```yaml
Database: db.t3.micro / B_Gen5_1 / db-f1-micro
Kubernetes: 1-3 nodes, t3.medium / Standard_B2s / e2-medium
Storage: 20-100 GB
Backup: 1 day retention
```

#### Production
```yaml
Database: db.r5.xlarge / GP_Gen5_8 / db-n1-standard-8
Kubernetes: 3-10 nodes, m5.large / Standard_DS3_v2 / n2-standard-4
Storage: 500+ GB with auto-scaling
Backup: 7-30 day retention, geo-redundant
```

## 🔧 Manual Deployment

### AWS CloudFormation

```bash
# Create stack
aws cloudformation create-stack \
  --stack-name mysql-business-schema-dev \
  --template-body file://cloud/aws/cloudformation-mysql.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=DatabaseExample,ParameterValue=ecommerce \
    ParameterKey=DBMasterPassword,ParameterValue=SecurePassword123! \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# Monitor progress
aws cloudformation describe-stacks \
  --stack-name mysql-business-schema-dev \
  --query 'Stacks[0].StackStatus'
```

### Google Cloud Platform (Terraform)

```bash
cd cloud/gcp

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars << EOF
project_id = "my-project-id"
region = "us-central1"
environment = "dev"
database_example = "ecommerce"
db_password = "SecurePassword123!"
EOF

# Plan and apply
terraform plan
terraform apply
```

### Microsoft Azure (ARM)

```bash
# Create resource group
az group create \
  --name mysql-business-schema-dev-rg \
  --location eastus

# Deploy template
az deployment group create \
  --resource-group mysql-business-schema-dev-rg \
  --template-file cloud/azure/azuredeploy.json \
  --parameters \
    environment=dev \
    databaseExample=ecommerce \
    administratorLoginPassword=SecurePassword123!
```

## 🔐 Security Best Practices

### Secrets Management
```bash
# AWS - Secrets Manager
aws secretsmanager get-secret-value --secret-id mysql-business-schema-dev-db-credentials

# GCP - Secret Manager
gcloud secrets versions access latest --secret="mysql-business-schema-dev-db-credentials"

# Azure - Key Vault
az keyvault secret show --vault-name mysql-business-schema-dev-kv --name db-password
```

### Network Security
- Private subnets for databases
- NAT Gateway/Cloud NAT for outbound traffic
- Security groups/firewall rules restricting access
- VPN/Private endpoints for secure access

### Encryption
- Encryption at rest for all databases
- SSL/TLS for data in transit
- Encrypted storage buckets
- KMS/Key Vault integration

## 📊 Cost Optimization

### Estimated Monthly Costs

#### Development Environment
- **AWS**: ~$150-200/month
- **GCP**: ~$130-180/month
- **Azure**: ~$140-190/month

#### Production Environment
- **AWS**: ~$800-1200/month
- **GCP**: ~$750-1100/month
- **Azure**: ~$850-1250/month

### Cost Saving Tips
1. Use spot/preemptible instances for non-critical workloads
2. Enable auto-scaling with appropriate limits
3. Use lifecycle policies for storage
4. Schedule dev/staging environment shutdown
5. Use reserved instances for production

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
name: Deploy to Cloud

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy CloudFormation
        run: |
          ./cloud/deploy.sh --provider aws --environment dev --database ecommerce
```

## 🔍 Monitoring & Logging

### AWS
```bash
# View RDS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=mysql-instance \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

### GCP
```bash
# View Cloud SQL metrics
gcloud monitoring metrics-descriptors list --filter="metric.type:cloudsql.googleapis.com"
```

### Azure
```bash
# View database metrics
az monitor metrics list \
  --resource /subscriptions/{subscription}/resourceGroups/{rg}/providers/Microsoft.DBforMySQL/servers/{server} \
  --metric connections
```

## 🔥 Disaster Recovery

### Backup Strategy
- Automated daily backups
- Point-in-time recovery support
- Cross-region replication for production
- Backup retention: 7-30 days

### Recovery Procedures
```bash
# AWS - Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-instance \
  --db-snapshot-identifier snapshot-id

# GCP - Restore from backup
gcloud sql backups restore BACKUP_ID \
  --restore-instance=INSTANCE_NAME

# Azure - Restore to point in time
az mysql server restore \
  --resource-group myresourcegroup \
  --name mydemoserver-restored \
  --source-server mydemoserver \
  --restore-point-in-time "2024-01-01T00:00:00Z"
```

## 🧹 Cleanup

```bash
# Destroy all resources
./cloud/deploy.sh --provider aws --action destroy
./cloud/deploy.sh --provider gcp --action destroy
./cloud/deploy.sh --provider azure --action destroy
```

## 📝 Troubleshooting

### Common Issues

1. **Insufficient Quotas**
   ```bash
   # Check AWS service quotas
   aws service-quotas get-service-quota --service-code rds --quota-code L-7B6409FD

   # Request increase
   aws service-quotas request-service-quota-increase --service-code rds --quota-code L-7B6409FD --desired-value 20
   ```

2. **Network Connectivity**
   ```bash
   # Test database connection
   mysql -h endpoint.rds.amazonaws.com -u admin -p
   ```

3. **Permission Errors**
   ```bash
   # Verify IAM permissions
   aws iam simulate-principal-policy \
     --policy-source-arn arn:aws:iam::123456789012:user/username \
     --action-names rds:CreateDBInstance
   ```

## 🔄 Updates & Maintenance

### Update Infrastructure
```bash
# AWS - Update stack
aws cloudformation update-stack \
  --stack-name mysql-business-schema-dev \
  --template-body file://cloud/aws/cloudformation-mysql.yaml \
  --parameters file://parameters.json

# GCP - Update with Terraform
terraform plan
terraform apply

# Azure - Update deployment
az deployment group create \
  --resource-group mysql-business-schema-dev-rg \
  --template-file cloud/azure/azuredeploy.json \
  --mode Incremental
```

## 📚 Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.