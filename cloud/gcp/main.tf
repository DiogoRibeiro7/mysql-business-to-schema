# ==============================================================================
# Google Cloud Platform - Terraform Configuration for MySQL Business-to-Schema
# ==============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "mysql-business-schema-terraform-state"
    prefix = "terraform/state"
  }
}

# ------------------------------------------------------------------------------
# Provider Configuration
# ------------------------------------------------------------------------------
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mysql-business-schema"
}

variable "database_example" {
  description = "Database example to deploy"
  type        = string
  default     = "ecommerce"
}

variable "enable_streaming" {
  description = "Enable streaming infrastructure (Pub/Sub, Dataflow)"
  type        = bool
  default     = true
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-n1-standard-2"
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 100
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "gke_security_group" {
  description = "Google Group email for GKE RBAC"
  type        = string
  default     = "gke-security@example.com"
}

# ------------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------------
locals {
  common_labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
    example     = var.database_example
  }

  name_prefix = "${var.project_name}-${var.environment}"
}

# ------------------------------------------------------------------------------
# Enable APIs
# ------------------------------------------------------------------------------
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "cloudrun.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "monitoring.googleapis.com"
  ])

  service            = each.key
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460

  depends_on = [google_project_service.required_apis]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${local.name_prefix}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# ------------------------------------------------------------------
# KMS for CMEK-protected services
# ------------------------------------------------------------------
resource "google_kms_key_ring" "main" {
  name     = "${local.name_prefix}-kr"
  location = var.region

  depends_on = [google_project_service.required_apis]
}

resource "google_kms_crypto_key" "app" {
  name            = "${local.name_prefix}-key"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_subnetwork" "private" {
  name          = "${local.name_prefix}-private-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "public" {
  name          = "${local.name_prefix}-public-subnet"
  ip_cidr_range = "10.0.16.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT for private resources
resource "google_compute_router" "router" {
  name    = "${local.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ------------------------------------------------------------------------------
# Cloud SQL - MySQL
# ------------------------------------------------------------------------------
resource "google_sql_database_instance" "mysql" {
  name             = "${local.name_prefix}-mysql-${var.database_example}"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier              = var.db_tier
    disk_size         = var.db_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      binary_log_enabled             = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 7 : 3
      }
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    database_flags {
      name  = "general_log"
      value = var.environment == "dev" ? "on" : "off"
    }

    database_flags {
      name  = "log_bin_trust_function_creators"
      value = "on"
    }

    user_labels = local.common_labels
  }

  deletion_protection = var.environment == "prod"

  depends_on = [
    google_project_service.required_apis,
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "mysql_database" {
  name     = "${var.database_example}_db"
  instance = google_sql_database_instance.mysql.name
}

resource "google_sql_user" "mysql_user" {
  name     = "admin"
  instance = google_sql_database_instance.mysql.name
  password = var.db_password
}

# ------------------------------------------------------------------------------
# Cloud SQL - PostgreSQL
# ------------------------------------------------------------------------------
resource "google_sql_database_instance" "postgres" {
  name             = "${local.name_prefix}-postgres-${var.database_example}"
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    tier              = var.db_tier
    disk_size         = var.db_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = var.environment == "prod"
      transaction_log_retention_days = var.environment == "prod" ? 7 : 1

      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 7 : 3
      }
    }

    database_flags {
      name  = "log_statement"
      value = "ddl"
    }

    database_flags {
      name  = "log_duration"
      value = "on"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "log_hostname"
      value = "on"
    }

    database_flags {
      name  = "log_min_error_statement"
      value = "error"
    }

    database_flags {
      name  = "log_min_messages"
      value = "error"
    }

    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }

    user_labels = local.common_labels
  }

  deletion_protection = var.environment == "prod"

  depends_on = [
    google_project_service.required_apis,
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "postgres_database" {
  name     = "${var.database_example}_db"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "postgres_user" {
  name     = "admin"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

# ------------------------------------------------------------------------------
# Firestore (MongoDB Alternative)
# ------------------------------------------------------------------------------
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.required_apis]
}

# ------------------------------------------------------------------------------
# Private Service Connection for Cloud SQL
# ------------------------------------------------------------------------------
resource "google_compute_global_address" "private_ip_address" {
  name          = "${local.name_prefix}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id

  depends_on = [google_project_service.required_apis]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.required_apis]
}

# ------------------------------------------------------------------------------
# Memorystore (Redis)
# ------------------------------------------------------------------------------
resource "google_redis_instance" "cache" {
  name           = "${local.name_prefix}-redis"
  tier           = var.environment == "prod" ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.environment == "prod" ? 5 : 1
  region         = var.region

  authorized_network = google_compute_network.vpc.id

  redis_version = "REDIS_6_X"
  display_name  = "${local.name_prefix}-redis"

  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  labels = local.common_labels

  depends_on = [google_project_service.required_apis]
}

# ------------------------------------------------------------------------------
# Cloud Storage
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "data" {
  name          = "${local.name_prefix}-data-${data.google_project.project.number}"
  location      = var.region
  force_destroy = var.environment == "dev"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  labels = local.common_labels

  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = "access-logs"
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_storage_bucket" "logs" {
  name          = "${local.name_prefix}-logs-${data.google_project.project.number}"
  location      = var.region
  force_destroy = var.environment == "dev"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = "logs-bucket-access"
  }

  labels = local.common_labels

  depends_on = [google_project_service.required_apis]
}

# ------------------------------------------------------------------------------
# Pub/Sub for Streaming
# ------------------------------------------------------------------------------
resource "google_pubsub_topic" "cdc_events" {
  count = var.enable_streaming ? 1 : 0

  name = "${local.name_prefix}-cdc-events"

  message_retention_duration = "604800s" # 7 days

  kms_key_name = google_kms_crypto_key.app.id

  labels = local.common_labels

  depends_on = [google_project_service.required_apis]
}

resource "google_pubsub_subscription" "cdc_subscription" {
  count = var.enable_streaming ? 1 : 0

  name  = "${local.name_prefix}-cdc-subscription"
  topic = google_pubsub_topic.cdc_events[0].name

  message_retention_duration = "604800s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 60

  expiration_policy {
    ttl = "2678400s" # 31 days
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = local.common_labels
}

# ------------------------------------------------------------------------------
# BigQuery Dataset
# ------------------------------------------------------------------------------
resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "${replace(local.name_prefix, "-", "_")}_analytics"
  friendly_name               = "Analytics Dataset"
  description                 = "Analytics data for ${var.database_example}"
  location                    = var.region
  default_table_expiration_ms = var.environment == "prod" ? null : 2592000000 # 30 days for non-prod

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.app.id
  }

  labels = local.common_labels

  depends_on = [google_project_service.required_apis]
}

# ------------------------------------------------------------------------------
# GKE Cluster for Applications
# ------------------------------------------------------------------------------
resource "google_container_cluster" "primary" {
  #checkov:skip=CKV_GCP_69:Metadata server is enforced in google_container_node_pool.primary_nodes.
  name     = "${local.name_prefix}-gke"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.private.self_link

  enable_intranode_visibility = true

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "internal"
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  authenticator_groups_config {
    security_group = var.gke_security_group
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
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

  resource_labels = local.common_labels

  depends_on = [google_project_service.required_apis]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.environment == "prod" ? 3 : 1

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.environment == "prod" ? 3 : 1
    max_node_count = var.environment == "prod" ? 10 : 3
  }

  node_config {
    preemptible  = var.environment != "prod"
    machine_type = var.environment == "prod" ? "n2-standard-4" : "e2-medium"

    disk_size_gb = 100
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_node.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = local.common_labels

    tags = ["gke-node", "${local.name_prefix}-gke"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

# ------------------------------------------------------------------------------
# Service Accounts
# ------------------------------------------------------------------------------
resource "google_service_account" "gke_node" {
  account_id   = "${local.name_prefix}-gke-node"
  display_name = "GKE Node Service Account"

  depends_on = [google_project_service.required_apis]
}

resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_service_account" "application" {
  account_id   = "${local.name_prefix}-application"
  display_name = "Application Service Account"

  depends_on = [google_project_service.required_apis]
}

resource "google_project_iam_member" "application_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/storage.objectAdmin",
    "roles/pubsub.editor",
    "roles/bigquery.dataEditor",
    "roles/secretmanager.secretAccessor"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.application.email}"
}

# ------------------------------------------------------------------------------
# Secret Manager
# ------------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${local.name_prefix}-db-credentials"

  labels = local.common_labels

  replication {
    automatic = true
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id

  secret_data = jsonencode({
    mysql = {
      host     = google_sql_database_instance.mysql.private_ip_address
      port     = 3306
      username = "admin"
      password = var.db_password
      database = "${var.database_example}_db"
    }
    postgresql = {
      host     = google_sql_database_instance.postgres.private_ip_address
      port     = 5432
      username = "admin"
      password = var.db_password
      database = "${var.database_example}_db"
    }
    redis = {
      host = google_redis_instance.cache.host
      port = google_redis_instance.cache.port
    }
  })
}

# ------------------------------------------------------------------------------
# Data Source for Project
# ------------------------------------------------------------------------------
data "google_project" "project" {
  project_id = var.project_id
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "vpc_network" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "mysql_connection_name" {
  description = "MySQL connection name"
  value       = google_sql_database_instance.mysql.connection_name
  sensitive   = true
}

output "postgres_connection_name" {
  description = "PostgreSQL connection name"
  value       = google_sql_database_instance.postgres.connection_name
  sensitive   = true
}

output "redis_host" {
  description = "Redis instance host"
  value       = google_redis_instance.cache.host
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "data_bucket" {
  description = "Data storage bucket name"
  value       = google_storage_bucket.data.name
}

output "bigquery_dataset" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.analytics.dataset_id
}

output "secret_id" {
  description = "Secret Manager secret ID"
  value       = google_secret_manager_secret.db_credentials.secret_id
}
