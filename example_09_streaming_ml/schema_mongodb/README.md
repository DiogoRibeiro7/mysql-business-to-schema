# MongoDB Schema for example_09_streaming_ml

Converted from MySQL on 2026-02-17T23:16:48.754471

## Collections

### schema_version

**Document Structure:**
```json
{
  "version": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "applied_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "applied_by": {
    "type": "String",
    "required": false,
    "default": "USER()"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### system_metrics

**Document Structure:**
```json
{
  "metric_name": {
    "type": "String",
    "required": true
  },
  "metric_value": {
    "type": "Decimal128",
    "required": false
  },
  "metric_unit": {
    "type": "String",
    "required": false
  },
  "component": {
    "type": "String",
    "required": false
  },
  "timestamp": {
    "type": "String",
    "required": false
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### organizations

**Document Structure:**
```json
{
  "org_type": {
    "type": "String",
    "required": false
  },
  "contact_email": {
    "type": "String",
    "required": false
  },
  "subscription_tier": {
    "type": "String",
    "required": false
  },
  "max_models": {
    "type": "Number",
    "required": false,
    "default": "10"
  },
  "max_deployments": {
    "type": "Number",
    "required": false,
    "default": "5"
  },
  "max_streams": {
    "type": "Number",
    "required": false,
    "default": "10"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### projects

**Document Structure:**
```json
{
  "org_id": {
    "type": "Number",
    "required": true
  },
  "project_name": {
    "type": "String",
    "required": true
  },
  "project_description": {
    "type": "String",
    "required": false
  },
  "project_type": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_by": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### data_streams

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "stream_name": {
    "type": "String",
    "required": true
  },
  "stream_type": {
    "type": "String",
    "required": false
  },
  "connection_config": {
    "type": "Object",
    "required": true
  },
  "schema_definition": {
    "type": "Object",
    "required": false
  },
  "data_format": {
    "type": "String",
    "required": false
  },
  "batch_size": {
    "type": "Number",
    "required": false,
    "default": "100"
  },
  "buffer_time_ms": {
    "type": "Number",
    "required": false,
    "default": "1000"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "last_connected": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### stream_pipelines

**Document Structure:**
```json
{
  "stream_id": {
    "type": "Number",
    "required": true
  },
  "pipeline_name": {
    "type": "String",
    "required": true
  },
  "pipeline_config": {
    "type": "Object",
    "required": true
  },
  "processing_type": {
    "type": "String",
    "required": false
  },
  "window_type": {
    "type": "String",
    "required": false
  },
  "window_size_seconds": {
    "type": "Number",
    "required": false
  },
  "watermark_delay_seconds": {
    "type": "Number",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### stream_events

**Document Structure:**
```json
{
  "stream_id": {
    "type": "Number",
    "required": true
  },
  "event_timestamp": {
    "type": "String",
    "required": false
  },
  "event_data": {
    "type": "Object",
    "required": true
  },
  "event_metadata": {
    "type": "Object",
    "required": false
  },
  "processing_status": {
    "type": "String",
    "required": false
  },
  "error_message": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### feature_definitions

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "feature_name": {
    "type": "String",
    "required": true
  },
  "feature_group": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "data_type": {
    "type": "String",
    "required": false
  },
  "computation_type": {
    "type": "String",
    "required": false
  },
  "computation_logic": {
    "type": "String",
    "required": false
  },
  "dependencies": {
    "type": "Object",
    "required": false
  },
  "is_online": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "is_offline": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "ttl_seconds": {
    "type": "Number",
    "required": false
  },
  "version": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### raw_features

**Document Structure:**
```json
{
  "feature_id": {
    "type": "Number",
    "required": true
  },
  "entity_id": {
    "type": "String",
    "required": true
  },
  "feature_value": {
    "type": "Object",
    "required": true
  },
  "event_timestamp": {
    "type": "String",
    "required": false
  },
  "ingestion_timestamp": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP(3)"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### feature_computations

**Document Structure:**
```json
{
  "feature_id": {
    "type": "Number",
    "required": true
  },
  "entity_id": {
    "type": "String",
    "required": true
  },
  "window_start": {
    "type": "Date",
    "required": true
  },
  "window_end": {
    "type": "String",
    "required": false
  },
  "feature_value": {
    "type": "Object",
    "required": true
  },
  "statistics": {
    "type": "Object",
    "required": false
  },
  "computed_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### feature_sets

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "set_name": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "feature_ids": {
    "type": "Object",
    "required": true
  },
  "label_definition": {
    "type": "Object",
    "required": false
  },
  "split_config": {
    "type": "Object",
    "required": false
  },
  "validation_rules": {
    "type": "Object",
    "required": false
  },
  "version": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### experiments

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "experiment_name": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "hypothesis": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "start_time": {
    "type": "Date",
    "required": false
  },
  "end_time": {
    "type": "Date",
    "required": false
  },
  "created_by": {
    "type": "String",
    "required": false
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### experiment_runs

**Document Structure:**
```json
{
  "experiment_id": {
    "type": "Number",
    "required": true
  },
  "run_name": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "parameters": {
    "type": "Object",
    "required": false
  },
  "metrics": {
    "type": "Object",
    "required": false
  },
  "artifacts": {
    "type": "Object",
    "required": false
  },
  "environment": {
    "type": "Object",
    "required": false
  },
  "start_time": {
    "type": "Date",
    "required": true
  },
  "end_time": {
    "type": "Date",
    "required": false
  },
  "duration_seconds": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### run_metrics

**Document Structure:**
```json
{
  "run_id": {
    "type": "String",
    "required": true
  },
  "metric_name": {
    "type": "String",
    "required": true
  },
  "metric_value": {
    "type": "Decimal128",
    "required": false
  },
  "step": {
    "type": "Number",
    "required": false
  },
  "timestamp": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### models

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "experiment_id": {
    "type": "Number",
    "required": false
  },
  "run_id": {
    "type": "String",
    "required": false
  },
  "model_name": {
    "type": "String",
    "required": true
  },
  "model_version": {
    "type": "String",
    "required": true
  },
  "algorithm": {
    "type": "String",
    "required": false
  },
  "framework": {
    "type": "String",
    "required": false
  },
  "model_type": {
    "type": "String",
    "required": false
  },
  "feature_set_id": {
    "type": "Number",
    "required": false
  },
  "training_dataset": {
    "type": "Object",
    "required": false
  },
  "hyperparameters": {
    "type": "Object",
    "required": false
  },
  "model_size_bytes": {
    "type": "Number",
    "required": false
  },
  "model_location": {
    "type": "String",
    "required": false
  },
  "metrics": {
    "type": "Object",
    "required": false
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_by": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### model_evaluations

**Document Structure:**
```json
{
  "model_id": {
    "type": "Number",
    "required": true
  },
  "evaluation_type": {
    "type": "String",
    "required": false
  },
  "dataset_info": {
    "type": "Object",
    "required": false
  },
  "metrics": {
    "type": "Object",
    "required": true
  },
  "confusion_matrix": {
    "type": "Object",
    "required": false
  },
  "roc_curve": {
    "type": "Object",
    "required": false
  },
  "precision_recall_curve": {
    "type": "Object",
    "required": false
  },
  "feature_importance": {
    "type": "Object",
    "required": false
  },
  "evaluation_timestamp": {
    "type": "Date",
    "required": true
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### model_comparisons

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "comparison_name": {
    "type": "String",
    "required": false
  },
  "model_ids": {
    "type": "Object",
    "required": true
  },
  "comparison_metrics": {
    "type": "Object",
    "required": false
  },
  "winner_model_id": {
    "type": "Number",
    "required": false
  },
  "comparison_notes": {
    "type": "String",
    "required": false
  },
  "created_by": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### model_deployments

**Document Structure:**
```json
{
  "model_id": {
    "type": "Number",
    "required": true
  },
  "deployment_name": {
    "type": "String",
    "required": true
  },
  "environment": {
    "type": "String",
    "required": false
  },
  "deployment_type": {
    "type": "String",
    "required": false
  },
  "endpoint_url": {
    "type": "String",
    "required": false
  },
  "deployment_config": {
    "type": "Object",
    "required": false
  },
  "resource_config": {
    "type": "Object",
    "required": false
  },
  "scaling_config": {
    "type": "Object",
    "required": false
  },
  "traffic_percentage": {
    "type": "Number",
    "required": false,
    "default": "100"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "health_status": {
    "type": "String",
    "required": false
  },
  "deployed_at": {
    "type": "Date",
    "required": false
  },
  "retired_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### ab_tests

**Document Structure:**
```json
{
  "project_id": {
    "type": "Number",
    "required": true
  },
  "test_name": {
    "type": "String",
    "required": true
  },
  "control_deployment_id": {
    "type": "Number",
    "required": true
  },
  "treatment_deployment_id": {
    "type": "Number",
    "required": true
  },
  "traffic_split": {
    "type": "Object",
    "required": false
  },
  "success_metrics": {
    "type": "Object",
    "required": false
  },
  "significance_level": {
    "type": "Decimal128",
    "required": false
  },
  "minimum_sample_size": {
    "type": "Number",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "start_time": {
    "type": "Date",
    "required": false
  },
  "end_time": {
    "type": "Date",
    "required": false
  },
  "winner_deployment_id": {
    "type": "Number",
    "required": false
  },
  "results": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### predictions

**Document Structure:**
```json
{
  "deployment_id": {
    "type": "Number",
    "required": true
  },
  "input_features": {
    "type": "Object",
    "required": true
  },
  "prediction_result": {
    "type": "Object",
    "required": true
  },
  "prediction_probability": {
    "type": "Decimal128",
    "required": false
  },
  "prediction_timestamp": {
    "type": "String",
    "required": false
  },
  "response_time_ms": {
    "type": "Number",
    "required": false
  },
  "model_version": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### ground_truth

**Document Structure:**
```json
{
  "true_label": {
    "type": "Object",
    "required": true
  },
  "feedback_type": {
    "type": "String",
    "required": false
  },
  "feedback_source": {
    "type": "String",
    "required": false
  },
  "received_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### drift_detection

**Document Structure:**
```json
{
  "deployment_id": {
    "type": "Number",
    "required": true
  },
  "feature_name": {
    "type": "String",
    "required": false
  },
  "drift_type": {
    "type": "String",
    "required": false
  },
  "reference_window_start": {
    "type": "Date",
    "required": true
  },
  "reference_window_end": {
    "type": "Date",
    "required": true
  },
  "current_window_start": {
    "type": "Date",
    "required": true
  },
  "current_window_end": {
    "type": "Date",
    "required": true
  },
  "drift_score": {
    "type": "Decimal128",
    "required": false
  },
  "statistical_test": {
    "type": "String",
    "required": false
  },
  "p_value": {
    "type": "Decimal128",
    "required": false
  },
  "is_significant": {
    "type": "Boolean",
    "required": false
  },
  "detected_at": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### performance_metrics

**Document Structure:**
```json
{
  "deployment_id": {
    "type": "Number",
    "required": true
  },
  "metric_window_start": {
    "type": "Date",
    "required": true
  },
  "metric_window_end": {
    "type": "String",
    "required": false
  },
  "prediction_count": {
    "type": "Number",
    "required": false
  },
  "avg_response_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "p50_response_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "p95_response_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "p99_response_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "accuracy": {
    "type": "Decimal128",
    "required": false
  },
  "precision_score": {
    "type": "Decimal128",
    "required": false
  },
  "recall_score": {
    "type": "Decimal128",
    "required": false
  },
  "f1_score": {
    "type": "Decimal128",
    "required": false
  },
  "auc_roc": {
    "type": "Decimal128",
    "required": false
  },
  "confusion_matrix": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### model_alerts

**Document Structure:**
```json
{
  "deployment_id": {
    "type": "Number",
    "required": true
  },
  "alert_type": {
    "type": "String",
    "required": false
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "alert_message": {
    "type": "String",
    "required": true
  },
  "alert_details": {
    "type": "Object",
    "required": false
  },
  "triggered_at": {
    "type": "String",
    "required": false
  },
  "acknowledged_at": {
    "type": "Date",
    "required": false
  },
  "acknowledged_by": {
    "type": "String",
    "required": false
  },
  "resolved_at": {
    "type": "Date",
    "required": false
  },
  "resolved_by": {
    "type": "String",
    "required": false
  },
  "resolution_notes": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### compute_resources

**Document Structure:**
```json
{
  "resource_type": {
    "type": "String",
    "required": false
  },
  "provider": {
    "type": "String",
    "required": false
  },
  "specifications": {
    "type": "Object",
    "required": false
  },
  "total_capacity": {
    "type": "Decimal128",
    "required": false
  },
  "available_capacity": {
    "type": "Decimal128",
    "required": false
  },
  "unit": {
    "type": "String",
    "required": false
  },
  "cost_per_unit": {
    "type": "Decimal128",
    "required": false
  },
  "location": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### resource_allocations

**Document Structure:**
```json
{
  "resource_id": {
    "type": "Number",
    "required": true
  },
  "allocated_to_type": {
    "type": "String",
    "required": false
  },
  "allocated_to_id": {
    "type": "Number",
    "required": true
  },
  "allocated_amount": {
    "type": "Decimal128",
    "required": false
  },
  "allocation_start": {
    "type": "Date",
    "required": true
  },
  "allocation_end": {
    "type": "Date",
    "required": false
  },
  "cost_estimate": {
    "type": "Decimal128",
    "required": false
  },
  "actual_cost": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### data_lineage

**Document Structure:**
```json
{
  "source_type": {
    "type": "String",
    "required": false
  },
  "source_id": {
    "type": "Number",
    "required": true
  },
  "target_type": {
    "type": "String",
    "required": false
  },
  "target_id": {
    "type": "Number",
    "required": true
  },
  "transformation_type": {
    "type": "String",
    "required": false
  },
  "transformation_details": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### data_quality_rules

**Document Structure:**
```json
{
  "applies_to_type": {
    "type": "String",
    "required": false
  },
  "applies_to_id": {
    "type": "Number",
    "required": true
  },
  "rule_name": {
    "type": "String",
    "required": true
  },
  "rule_type": {
    "type": "String",
    "required": false
  },
  "rule_definition": {
    "type": "Object",
    "required": true
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### data_quality_violations

**Document Structure:**
```json
{
  "rule_id": {
    "type": "Number",
    "required": true
  },
  "violation_timestamp": {
    "type": "String",
    "required": false
  },
  "affected_records": {
    "type": "Number",
    "required": false
  },
  "violation_details": {
    "type": "Object",
    "required": false
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "resolved": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "resolved_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### user_activity

**Document Structure:**
```json
{
  "user_id": {
    "type": "String",
    "required": true
  },
  "org_id": {
    "type": "Number",
    "required": true
  },
  "activity_type": {
    "type": "String",
    "required": false
  },
  "activity_details": {
    "type": "Object",
    "required": false
  },
  "resource_type": {
    "type": "String",
    "required": false
  },
  "resource_id": {
    "type": "Number",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "user_agent": {
    "type": "String",
    "required": false
  },
  "activity_timestamp": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### api_usage

**Document Structure:**
```json
{
  "org_id": {
    "type": "Number",
    "required": true
  },
  "endpoint": {
    "type": "String",
    "required": true
  },
  "method": {
    "type": "String",
    "required": true
  },
  "request_timestamp": {
    "type": "String",
    "required": false
  },
  "response_status": {
    "type": "Number",
    "required": false
  },
  "response_time_ms": {
    "type": "Number",
    "required": false
  },
  "request_size_bytes": {
    "type": "Number",
    "required": false
  },
  "response_size_bytes": {
    "type": "Number",
    "required": false
  },
  "error_message": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### predictions_hourly

**Document Structure:**
```json
{
  "deployment_id": {
    "type": "Number",
    "required": true
  },
  "hour_timestamp": {
    "type": "String",
    "required": false
  },
  "prediction_count": {
    "type": "Number",
    "required": false
  },
  "avg_response_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "p95_response_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "error_count": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### stream_events_daily

**Document Structure:**
```json
{
  "stream_id": {
    "type": "Number",
    "required": true
  },
  "day_date": {
    "type": "String",
    "required": false
  },
  "event_count": {
    "type": "Number",
    "required": false
  },
  "processed_count": {
    "type": "Number",
    "required": false
  },
  "failed_count": {
    "type": "Number",
    "required": false
  },
  "avg_processing_time_ms": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

