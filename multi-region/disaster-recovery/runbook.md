# Multi-Region Disaster Recovery Runbook

## Overview

This runbook provides step-by-step procedures for disaster recovery scenarios in our multi-region MySQL deployment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Global Load Balancer                       │
│                  (AWS Global Accelerator)                     │
└─────────────┬────────────┬────────────┬────────────┬────────┘
              │            │            │            │
      ┌───────▼──────┐ ┌──▼──────┐ ┌──▼──────┐ ┌──▼──────┐
      │   US-EAST-1  │ │US-WEST-2│ │EU-WEST-1│ │   APAC   │
      │   (Primary)  │ │(Replica)│ │(Replica)│ │(Replica) │
      └──────────────┘ └─────────┘ └─────────┘ └──────────┘
```

## Failure Scenarios

### 1. Primary Region Failure (US-EAST-1)

**Detection:**
- CloudWatch alarms trigger for RDS availability
- Global Accelerator health checks fail
- Application monitoring shows connection failures

**Recovery Steps:**

```bash
# 1. Verify primary failure
./scripts/check_primary_health.sh

# 2. Promote US-WEST-2 replica to primary
aws rds promote-read-replica \
  --db-instance-identifier mysql-replica-west-production \
  --region us-west-2

# 3. Wait for promotion to complete (typically 5-10 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier mysql-replica-west-production \
  --region us-west-2

# 4. Update DNS to point to new primary
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch file://dns-failover.json

# 5. Update application configuration
kubectl set env deployment/web-demo \
  DB_HOST=mysql-replica-west-production.us-west-2.rds.amazonaws.com \
  -n mysql-business-schema

# 6. Verify application connectivity
./scripts/verify_connectivity.sh us-west-2

# 7. Create new read replicas
aws rds create-db-instance-read-replica \
  --db-instance-identifier mysql-replica-east-new \
  --source-db-instance-identifier mysql-replica-west-production \
  --region us-east-1
```

**Rollback Steps:**
```bash
# If original primary recovers
./scripts/failback_to_primary.sh us-east-1
```

### 2. Network Partition Between Regions

**Detection:**
- Increased replication lag alerts
- Network monitoring shows packet loss
- Cross-region latency spikes

**Recovery Steps:**

```bash
# 1. Identify affected network paths
./scripts/network_diagnostics.sh

# 2. Reroute traffic through alternate paths
aws ec2 modify-vpc-peering-connection-options \
  --vpc-peering-connection-id pcx-12345678 \
  --requester-peering-connection-options AllowDnsResolutionFromRemoteVpc=true

# 3. Enable traffic through backup network provider
terraform apply -target=module.backup_network_routes

# 4. Monitor replication lag
mysql -h replica.us-west-2.rds.amazonaws.com \
  -e "SHOW SLAVE STATUS\G" | grep Seconds_Behind_Master
```

### 3. Data Corruption in Primary

**Detection:**
- Application errors indicating data inconsistency
- MySQL error logs show corruption
- Backup validation failures

**Recovery Steps:**

```bash
# 1. Stop write traffic immediately
kubectl scale deployment web-demo --replicas=0 -n mysql-business-schema

# 2. Identify corruption extent
mysqlcheck --all-databases --check --extended \
  -h primary.us-east-1.rds.amazonaws.com

# 3. Point-in-time recovery to before corruption
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier mysql-primary-production \
  --target-db-instance-identifier mysql-primary-restored \
  --restore-time 2024-01-15T03:00:00.000Z

# 4. Validate restored data
./scripts/validate_data_integrity.sh mysql-primary-restored

# 5. Promote restored instance
aws rds modify-db-instance \
  --db-instance-identifier mysql-primary-restored \
  --new-db-instance-identifier mysql-primary-production \
  --apply-immediately

# 6. Resume traffic
kubectl scale deployment web-demo --replicas=3 -n mysql-business-schema
```

### 4. Complete Cloud Provider Outage (AWS)

**Detection:**
- AWS Service Health Dashboard shows major outage
- All AWS regions unavailable
- Need to failover to GCP/Azure

**Recovery Steps:**

```bash
# 1. Activate multi-cloud failover
./scripts/activate_multi_cloud_failover.sh

# 2. Promote GCP Cloud SQL instance
gcloud sql instances promote-replica mysql-replica-europe-production

# 3. Update global DNS to GCP endpoints
gcloud dns record-sets transaction start --zone=mysql-global
gcloud dns record-sets transaction add \
  --name=db.mysql-demo.global. \
  --ttl=60 \
  --type=CNAME \
  --zone=mysql-global \
  mysql-primary-production.europe-west1.cloudsql.gcp.com.
gcloud dns record-sets transaction execute --zone=mysql-global

# 4. Scale up GKE cluster
gcloud container clusters resize mysql-gke-europe \
  --node-pool=default-pool \
  --num-nodes=10 \
  --region=europe-west1

# 5. Deploy application to GKE
kubectl apply -f kubernetes/multi-cloud/gke-deployment.yaml

# 6. Verify service availability
curl https://mysql-demo.global/health
```

## Monitoring During DR

### Key Metrics to Watch

1. **Replication Lag**
```sql
SHOW SLAVE STATUS\G
SELECT * FROM mysql.slave_master_info;
SELECT * FROM performance_schema.replication_connection_status;
```

2. **Application Metrics**
```bash
# Prometheus queries
sum(rate(http_requests_total{status=~"5.."}[5m]))
histogram_quantile(0.99, http_request_duration_seconds_bucket)
```

3. **Database Performance**
```sql
SELECT * FROM performance_schema.events_statements_summary_by_digest
ORDER BY sum_timer_wait DESC LIMIT 10;
```

## Communication Plan

### Incident Levels

| Level | Description | Notification | Response Time |
|-------|------------|--------------|---------------|
| P1 | Complete primary failure | PagerDuty, Slack, Email | < 5 minutes |
| P2 | Replica failure | Slack, Email | < 15 minutes |
| P3 | Performance degradation | Email | < 1 hour |
| P4 | Planned maintenance | Email | Scheduled |

### Stakeholder Communication

```bash
# Send incident notification
./scripts/send_incident_notification.sh \
  --level P1 \
  --title "Primary Database Failure" \
  --description "Failing over to US-WEST-2" \
  --eta "30 minutes"
```

### Status Page Updates

```bash
# Update status page
curl -X POST https://api.statuspage.io/v1/pages/{page_id}/incidents \
  -H "Authorization: OAuth YOUR-API-KEY" \
  -d '{
    "incident": {
      "name": "Database Failover in Progress",
      "status": "investigating",
      "impact": "major",
      "body": "We are currently failing over to our secondary region."
    }
  }'
```

## Testing Procedures

### Monthly DR Drills

```bash
# 1. Scheduled failover test (off-peak hours)
./scripts/dr_drill.sh --type planned --target us-west-2

# 2. Chaos engineering test
./scripts/chaos_test.sh --scenario network-partition --duration 5m

# 3. Backup restoration test
./scripts/test_backup_restore.sh --backup-id backup-20240115

# 4. Multi-cloud failover test
./scripts/test_multi_cloud.sh --provider gcp --duration 1h
```

### Validation Checklist

- [ ] All replicas in sync (lag < 1s)
- [ ] Application health checks passing
- [ ] Customer-facing APIs responding
- [ ] Monitoring dashboards showing normal metrics
- [ ] Backup jobs completing successfully
- [ ] No data loss confirmed
- [ ] Performance within SLA

## Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO)

| Scenario | RTO | RPO | Automation Level |
|----------|-----|-----|------------------|
| Primary region failure | 15 minutes | < 1 minute | Fully automated |
| Network partition | 5 minutes | 0 (no data loss) | Semi-automated |
| Data corruption | 30 minutes | Point-in-time | Manual approval required |
| Cloud provider outage | 30 minutes | < 5 minutes | Semi-automated |

## Post-Incident Activities

### 1. Root Cause Analysis

```bash
# Collect logs and metrics
./scripts/collect_incident_data.sh --incident-id INC-2024-001

# Generate RCA report
./scripts/generate_rca.sh --incident-id INC-2024-001 \
  --output-format markdown > rca_report.md
```

### 2. Restore Original Configuration

```bash
# After incident resolution, restore primary
./scripts/restore_primary_configuration.sh

# Rebuild read replicas
./scripts/rebuild_replicas.sh --regions us-west-2,eu-west-1,ap-southeast-1

# Verify replication
./scripts/verify_replication_status.sh --all-regions
```

### 3. Update Documentation

- Update this runbook with lessons learned
- Update architecture diagrams if changed
- Update contact lists
- Review and update automation scripts

## Automation Scripts Location

All DR automation scripts are located in:
```
multi-region/
├── scripts/
│   ├── check_primary_health.sh
│   ├── failover_to_replica.sh
│   ├── failback_to_primary.sh
│   ├── network_diagnostics.sh
│   ├── validate_data_integrity.sh
│   ├── activate_multi_cloud_failover.sh
│   ├── dr_drill.sh
│   ├── chaos_test.sh
│   ├── collect_incident_data.sh
│   └── generate_rca.sh
├── terraform/
│   └── disaster-recovery/
└── kubernetes/
    └── dr-manifests/
```

## Emergency Contacts

| Role | Name | Phone | Email | Slack |
|------|------|-------|-------|-------|
| DBA On-Call | Rotation | +1-xxx-xxx-xxxx | dba-oncall@company.com | @dba-oncall |
| SRE Lead | John Doe | +1-xxx-xxx-xxxx | john.doe@company.com | @johndoe |
| VP Engineering | Jane Smith | +1-xxx-xxx-xxxx | jane.smith@company.com | @janesmith |

## Appendix

### A. Common MySQL Commands for DR

```sql
-- Check replication status
SHOW MASTER STATUS;
SHOW SLAVE STATUS\G
SHOW REPLICA STATUS\G  -- MySQL 8.0.22+

-- Skip replication errors
SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
START SLAVE;

-- Reset replication
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO ...;
START SLAVE;

-- Check for blocking queries
SELECT * FROM information_schema.PROCESSLIST WHERE Command != 'Sleep';

-- Kill long-running queries
SELECT CONCAT('KILL ', id, ';') FROM information_schema.PROCESSLIST
WHERE Command != 'Sleep' AND Time > 300;
```

### B. Terraform Commands for DR

```bash
# Plan infrastructure changes
terraform plan -target=module.dr_infrastructure

# Apply DR configuration
terraform apply -auto-approve -target=module.dr_infrastructure

# Destroy temporary DR resources
terraform destroy -target=module.temp_dr_resources
```

### C. Kubernetes Commands for DR

```bash
# Cordon nodes in affected region
kubectl cordon -l region=us-east-1

# Drain pods from affected nodes
kubectl drain -l region=us-east-1 --ignore-daemonsets --delete-emptydir-data

# Update deployment region affinity
kubectl patch deployment web-demo -n mysql-business-schema \
  --type json -p='[{"op": "replace", "path": "/spec/template/spec/affinity", "value": {...}}]'

# Scale up in backup region
kubectl scale deployment web-demo --replicas=10 -n mysql-business-schema \
  --context=gke_project_europe-west1_mysql-gke-europe
```

---

**Last Updated:** 2024-01-15
**Version:** 2.0
**Review Schedule:** Quarterly