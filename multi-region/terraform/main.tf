# Terraform configuration for multi-region MySQL deployment
# Supports AWS, GCP, and Azure with cross-region replication

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "mysql-business-schema-tfstate"
    key            = "multi-region/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# =====================================================
# Provider Configurations
# =====================================================

# AWS Provider - Multiple Regions
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"
}

# GCP Provider - Multiple Regions
provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
}

# Azure Provider
provider "azurerm" {
  features {}
}

# =====================================================
# Variables
# =====================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0"
}

variable "regions" {
  description = "List of regions for deployment"
  type = map(object({
    provider = string
    primary  = bool
    zone     = string
  }))
  default = {
    us-east-1 = {
      provider = "aws"
      primary  = true
      zone     = "us-east-1a"
    }
    us-west-2 = {
      provider = "aws"
      primary  = false
      zone     = "us-west-2a"
    }
    europe-west1 = {
      provider = "gcp"
      primary  = false
      zone     = "europe-west1-b"
    }
    asia-southeast1 = {
      provider = "aws"
      primary  = false
      zone     = "ap-southeast-1a"
    }
  }
}

# =====================================================
# Global Resources
# =====================================================

# Global DNS with Route53
resource "aws_route53_zone" "main" {
  name = "mysql-demo.global"

  tags = {
    Environment = var.environment
    Purpose     = "Global DNS for multi-region MySQL"
  }
}

# Global Traffic Manager
resource "aws_route53_record" "global_cname" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "db.mysql-demo.global"
  type    = "CNAME"
  ttl     = 60

  weighted_routing_policy {
    weight = 100
  }

  set_identifier = "primary"
  records        = [module.rds_us_east_1.endpoint]
}

# =====================================================
# AWS RDS Multi-Region Setup
# =====================================================

# Primary RDS Instance (US East 1)
module "rds_us_east_1" {
  source = "./modules/aws-rds"

  providers = {
    aws = aws.us_east_1
  }

  identifier_prefix = "mysql-primary"
  region            = "us-east-1"

  # Instance configuration
  engine         = "mysql"
  engine_version = var.mysql_version
  instance_class = "db.r6g.2xlarge"

  # Storage
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database configuration
  db_name  = "clinic_db"
  username = "admin"
  password = random_password.rds_password.result

  # Multi-AZ for high availability
  multi_az               = true
  availability_zone      = "us-east-1a"
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval = 60

  # Network
  vpc_id     = module.vpc_us_east_1.vpc_id
  subnet_ids = module.vpc_us_east_1.database_subnet_ids

  # Security
  deletion_protection = true
  skip_final_snapshot = false

  tags = {
    Environment = var.environment
    Region      = "us-east-1"
    Role        = "primary"
  }
}

# Read Replica - US West 2
module "rds_us_west_2" {
  source = "./modules/aws-rds-replica"

  providers = {
    aws = aws.us_west_2
  }

  identifier_prefix          = "mysql-replica-west"
  replicate_source_db       = module.rds_us_east_1.db_instance_id

  # Instance configuration
  instance_class = "db.r6g.xlarge"

  # Performance Insights
  performance_insights_enabled = true

  # Network
  vpc_id     = module.vpc_us_west_2.vpc_id
  subnet_ids = module.vpc_us_west_2.database_subnet_ids

  tags = {
    Environment = var.environment
    Region      = "us-west-2"
    Role        = "replica"
  }
}

# Read Replica - EU West 1
module "rds_eu_west_1" {
  source = "./modules/aws-rds-replica"

  providers = {
    aws = aws.eu_west_1
  }

  identifier_prefix          = "mysql-replica-eu"
  replicate_source_db       = module.rds_us_east_1.db_instance_id

  # Instance configuration
  instance_class = "db.r6g.xlarge"

  # Performance Insights
  performance_insights_enabled = true

  # Network
  vpc_id     = module.vpc_eu_west_1.vpc_id
  subnet_ids = module.vpc_eu_west_1.database_subnet_ids

  # Promote to standalone in case of disaster
  backup_retention_period = 7

  tags = {
    Environment = var.environment
    Region      = "eu-west-1"
    Role        = "replica"
  }
}

# =====================================================
# GCP Cloud SQL Multi-Region
# =====================================================

resource "google_sql_database_instance" "primary" {
  name             = "mysql-primary-${var.environment}"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier              = "db-n1-highmem-4"
    availability_type = "REGIONAL"
    disk_size         = 100
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      binary_log_enabled             = true
      transaction_log_retention_days = 7
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.self_link
      require_ssl     = true
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    database_flags {
      name  = "log_output"
      value = "FILE"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length    = 1024
      record_application_tags = true
      record_client_address  = true
    }
  }
}

# GCP Read Replica
resource "google_sql_database_instance" "replica" {
  name                 = "mysql-replica-europe-${var.environment}"
  database_version     = "MYSQL_8_0"
  region              = "europe-west1"
  master_instance_name = google_sql_database_instance.primary.name

  replica_configuration {
    failover_target = true
  }

  settings {
    tier              = "db-n1-highmem-2"
    availability_type = "ZONAL"
    disk_size         = 100
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.self_link
      require_ssl     = true
    }
  }
}

# =====================================================
# Azure Database for MySQL
# =====================================================

resource "azurerm_resource_group" "mysql" {
  name     = "mysql-${var.environment}-rg"
  location = "East US"
}

resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-azure-${var.environment}"
  resource_group_name    = azurerm_resource_group.mysql.name
  location              = azurerm_resource_group.mysql.location
  administrator_login    = "mysqladmin"
  administrator_password = random_password.azure_mysql_password.result
  sku_name              = "B_Standard_B2s"
  version               = "8.0.21"
  zone                  = "1"

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  storage {
    size_gb           = 100
    auto_grow_enabled = true
  }

  backup {
    backup_retention_days        = 30
    geo_redundant_backup_enabled = true
  }

  maintenance_window {
    customized_window = "Enabled"
    day_of_week      = 0
    start_hour       = 3
    start_minute     = 0
  }

  tags = {
    Environment = var.environment
    Provider    = "azure"
  }
}

# Azure Read Replica
resource "azurerm_mysql_flexible_server_replica" "replica" {
  name                = "mysql-azure-replica-${var.environment}"
  resource_group_name = azurerm_resource_group.mysql.name
  location           = "West Europe"
  source_server_id   = azurerm_mysql_flexible_server.main.id

  sku_name = "B_Standard_B2s"

  storage {
    size_gb           = 100
    auto_grow_enabled = true
  }

  tags = {
    Environment = var.environment
    Role        = "replica"
  }
}

# =====================================================
# Kubernetes Deployments for Each Region
# =====================================================

# EKS Cluster - US East 1
module "eks_us_east_1" {
  source = "./modules/aws-eks"

  providers = {
    aws = aws.us_east_1
  }

  cluster_name    = "mysql-eks-us-east-1"
  cluster_version = "1.28"
  region          = "us-east-1"

  vpc_id     = module.vpc_us_east_1.vpc_id
  subnet_ids = module.vpc_us_east_1.private_subnet_ids

  node_groups = {
    general = {
      desired_capacity = 3
      max_capacity     = 10
      min_capacity     = 3
      instance_types   = ["t3.large"]
    }

    database = {
      desired_capacity = 2
      max_capacity     = 5
      min_capacity     = 2
      instance_types   = ["r5.xlarge"]

      taints = [{
        key    = "workload"
        value  = "database"
        effect = "NO_SCHEDULE"
      }]

      labels = {
        workload = "database"
      }
    }
  }

  tags = {
    Environment = var.environment
    Region      = "us-east-1"
  }
}

# GKE Cluster - Europe
resource "google_container_cluster" "europe" {
  name     = "mysql-gke-europe"
  location = "europe-west1"

  initial_node_count = 3

  node_config {
    machine_type = "e2-standard-4"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
    }

    tags = ["mysql", "kubernetes"]
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }
  }
}

# AKS Cluster - Azure
resource "azurerm_kubernetes_cluster" "main" {
  name                = "mysql-aks-${var.environment}"
  location            = azurerm_resource_group.mysql.location
  resource_group_name = azurerm_resource_group.mysql.name
  dns_prefix         = "mysql-aks"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  tags = {
    Environment = var.environment
  }
}

# =====================================================
# Global Load Balancing
# =====================================================

# AWS Global Accelerator
resource "aws_globalaccelerator_accelerator" "main" {
  name            = "mysql-global-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = aws_s3_bucket.logs.id
    flow_logs_s3_prefix = "global-accelerator"
  }
}

resource "aws_globalaccelerator_listener" "mysql" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.arn
  protocol        = "TCP"

  port_range {
    from_port = 3306
    to_port   = 3306
  }
}

# Endpoint groups for each region
resource "aws_globalaccelerator_endpoint_group" "us_east_1" {
  listener_arn = aws_globalaccelerator_listener.mysql.arn

  endpoint_group_region = "us-east-1"
  traffic_dial_percentage = 40

  endpoint_configuration {
    endpoint_id = module.rds_us_east_1.endpoint
    weight      = 100
  }

  health_check_interval_seconds = 30
  health_check_path             = "/"
  health_check_port             = 3306
  health_check_protocol         = "TCP"
  threshold_count               = 3
}

resource "aws_globalaccelerator_endpoint_group" "us_west_2" {
  listener_arn = aws_globalaccelerator_listener.mysql.arn

  endpoint_group_region = "us-west-2"
  traffic_dial_percentage = 30

  endpoint_configuration {
    endpoint_id = module.rds_us_west_2.endpoint
    weight      = 100
  }

  health_check_interval_seconds = 30
  health_check_path             = "/"
  health_check_port             = 3306
  health_check_protocol         = "TCP"
  threshold_count               = 3
}

# =====================================================
# Disaster Recovery Configuration
# =====================================================

# AWS Backup for disaster recovery
resource "aws_backup_plan" "mysql" {
  name = "mysql-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.mysql.name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.mysql_dr.arn

      lifecycle {
        cold_storage_after = 30
        delete_after       = 365
      }
    }
  }

  rule {
    rule_name         = "hourly_backup"
    target_vault_name = aws_backup_vault.mysql.name
    schedule          = "cron(0 * * * ? *)"

    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_vault" "mysql" {
  name = "mysql-backup-vault"

  tags = {
    Environment = var.environment
    Purpose     = "MySQL Backups"
  }
}

resource "aws_backup_vault" "mysql_dr" {
  provider = aws.us_west_2
  name     = "mysql-backup-vault-dr"

  tags = {
    Environment = var.environment
    Purpose     = "MySQL DR Backups"
  }
}

# =====================================================
# Outputs
# =====================================================

output "primary_endpoint" {
  description = "Primary database endpoint"
  value       = module.rds_us_east_1.endpoint
}

output "replica_endpoints" {
  description = "Read replica endpoints"
  value = {
    us_west_2 = module.rds_us_west_2.endpoint
    eu_west_1 = module.rds_eu_west_1.endpoint
    gcp       = google_sql_database_instance.replica.connection_name
    azure     = azurerm_mysql_flexible_server_replica.replica.fqdn
  }
}

output "global_accelerator_dns" {
  description = "Global Accelerator DNS name"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "kubernetes_clusters" {
  description = "Kubernetes cluster endpoints"
  value = {
    eks_us_east_1 = module.eks_us_east_1.cluster_endpoint
    gke_europe    = google_container_cluster.europe.endpoint
    aks_azure     = azurerm_kubernetes_cluster.main.kube_config.0.host
  }
}

# Random passwords
resource "random_password" "rds_password" {
  length  = 32
  special = true
}

resource "random_password" "azure_mysql_password" {
  length  = 32
  special = true
}