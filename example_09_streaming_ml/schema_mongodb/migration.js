// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.753294
// From MySQL to MongoDB

use converted_db;

// Create collection: schema_version
db.createCollection('schema_version');

// Create collection: system_metrics
db.createCollection('system_metrics');

// Create collection: organizations
db.createCollection('organizations');

// Create collection: projects
db.createCollection('projects');

// Create collection: data_streams
db.createCollection('data_streams');

// Create collection: stream_pipelines
db.createCollection('stream_pipelines');

// Create collection: stream_events
db.createCollection('stream_events');

// Create collection: feature_definitions
db.createCollection('feature_definitions');

// Create collection: raw_features
db.createCollection('raw_features');

// Create collection: feature_computations
db.createCollection('feature_computations');

// Create collection: feature_sets
db.createCollection('feature_sets');

// Create collection: experiments
db.createCollection('experiments');

// Create collection: experiment_runs
db.createCollection('experiment_runs');

// Create collection: run_metrics
db.createCollection('run_metrics');

// Create collection: models
db.createCollection('models');

// Create collection: model_evaluations
db.createCollection('model_evaluations');

// Create collection: model_comparisons
db.createCollection('model_comparisons');

// Create collection: model_deployments
db.createCollection('model_deployments');

// Create collection: ab_tests
db.createCollection('ab_tests');

// Create collection: predictions
db.createCollection('predictions');

// Create collection: ground_truth
db.createCollection('ground_truth');

// Create collection: drift_detection
db.createCollection('drift_detection');

// Create collection: performance_metrics
db.createCollection('performance_metrics');

// Create collection: model_alerts
db.createCollection('model_alerts');

// Create collection: compute_resources
db.createCollection('compute_resources');

// Create collection: resource_allocations
db.createCollection('resource_allocations');

// Create collection: data_lineage
db.createCollection('data_lineage');

// Create collection: data_quality_rules
db.createCollection('data_quality_rules');

// Create collection: data_quality_violations
db.createCollection('data_quality_violations');

// Create collection: user_activity
db.createCollection('user_activity');

// Create collection: api_usage
db.createCollection('api_usage');

// Create collection: predictions_hourly
db.createCollection('predictions_hourly');

// Create collection: stream_events_daily
db.createCollection('stream_events_daily');

// Indexes for schema_version
db.schema_version.createIndex({"description": "text"}, {"name": "schema_version_text"});

// Indexes for organizations

// Indexes for projects
db.projects.createIndex({"project_description": "text"}, {"name": "projects_text"});

// Indexes for data_streams

// Indexes for stream_events
db.stream_events.createIndex({"error_message": "text"}, {"name": "stream_events_text"});

// Indexes for feature_definitions
db.feature_definitions.createIndex({"description": "text", "computation_logic": "text"}, {"name": "feature_definitions_text"});

// Indexes for feature_computations

// Indexes for feature_sets
db.feature_sets.createIndex({"description": "text"}, {"name": "feature_sets_text"});

// Indexes for experiments
db.experiments.createIndex({"description": "text", "hypothesis": "text"}, {"name": "experiments_text"});

// Indexes for models

// Indexes for model_comparisons
db.model_comparisons.createIndex({"comparison_notes": "text"}, {"name": "model_comparisons_text"});

// Indexes for predictions

// Indexes for ground_truth

// Indexes for performance_metrics

// Indexes for model_alerts
db.model_alerts.createIndex({"alert_message": "text", "resolution_notes": "text"}, {"name": "model_alerts_text"});

// Indexes for compute_resources

// Indexes for data_quality_rules

// Indexes for user_activity
db.user_activity.createIndex({"user_agent": "text"}, {"name": "user_activity_text"});

// Indexes for api_usage
db.api_usage.createIndex({"error_message": "text"}, {"name": "api_usage_text"});

// Validation for schema_version
db.runCommand({
  collMod: 'schema_version',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "version"
    ],
    "properties": {
      "version": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "applied_at": {
        "bsonType": "date"
      },
      "applied_by": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for system_metrics
db.runCommand({
  collMod: 'system_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "metric_name"
    ],
    "properties": {
      "metric_name": {
        "bsonType": "string"
      },
      "metric_value": {
        "bsonType": "decimal128"
      },
      "metric_unit": {
        "bsonType": "string"
      },
      "component": {
        "bsonType": "string"
      },
      "timestamp": {
        "bsonType": "string"
      },
      "tags": {
        "bsonType": "object"
      }
    }
  }
}
});

// Validation for organizations
db.runCommand({
  collMod: 'organizations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "org_type": {
        "bsonType": "string"
      },
      "contact_email": {
        "bsonType": "string"
      },
      "subscription_tier": {
        "bsonType": "string"
      },
      "max_models": {
        "bsonType": "number"
      },
      "max_deployments": {
        "bsonType": "number"
      },
      "max_streams": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for projects
db.runCommand({
  collMod: 'projects',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "org_id",
      "project_name"
    ],
    "properties": {
      "org_id": {
        "bsonType": "number"
      },
      "project_name": {
        "bsonType": "string"
      },
      "project_description": {
        "bsonType": "string"
      },
      "project_type": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "created_by": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for data_streams
db.runCommand({
  collMod: 'data_streams',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "stream_name",
      "connection_config"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "stream_name": {
        "bsonType": "string"
      },
      "stream_type": {
        "bsonType": "string"
      },
      "connection_config": {
        "bsonType": "object"
      },
      "schema_definition": {
        "bsonType": "object"
      },
      "data_format": {
        "bsonType": "string"
      },
      "batch_size": {
        "bsonType": "number"
      },
      "buffer_time_ms": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "last_connected": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for stream_pipelines
db.runCommand({
  collMod: 'stream_pipelines',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "stream_id",
      "pipeline_name",
      "pipeline_config"
    ],
    "properties": {
      "stream_id": {
        "bsonType": "number"
      },
      "pipeline_name": {
        "bsonType": "string"
      },
      "pipeline_config": {
        "bsonType": "object"
      },
      "processing_type": {
        "bsonType": "string"
      },
      "window_type": {
        "bsonType": "string"
      },
      "window_size_seconds": {
        "bsonType": "number"
      },
      "watermark_delay_seconds": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for stream_events
db.runCommand({
  collMod: 'stream_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "stream_id",
      "event_timestamp",
      "event_data"
    ],
    "properties": {
      "stream_id": {
        "bsonType": "number"
      },
      "event_timestamp": {
        "bsonType": "string"
      },
      "event_data": {
        "bsonType": "object"
      },
      "event_metadata": {
        "bsonType": "object"
      },
      "processing_status": {
        "bsonType": "string"
      },
      "error_message": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for feature_definitions
db.runCommand({
  collMod: 'feature_definitions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "feature_name"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "feature_name": {
        "bsonType": "string"
      },
      "feature_group": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "data_type": {
        "bsonType": "string"
      },
      "computation_type": {
        "bsonType": "string"
      },
      "computation_logic": {
        "bsonType": "string"
      },
      "dependencies": {
        "bsonType": "object"
      },
      "is_online": {
        "bsonType": "boolean"
      },
      "is_offline": {
        "bsonType": "boolean"
      },
      "ttl_seconds": {
        "bsonType": "number"
      },
      "version": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for raw_features
db.runCommand({
  collMod: 'raw_features',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "feature_id",
      "entity_id",
      "feature_value",
      "event_timestamp"
    ],
    "properties": {
      "feature_id": {
        "bsonType": "number"
      },
      "entity_id": {
        "bsonType": "string"
      },
      "feature_value": {
        "bsonType": "object"
      },
      "event_timestamp": {
        "bsonType": "string"
      },
      "ingestion_timestamp": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for feature_computations
db.runCommand({
  collMod: 'feature_computations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "feature_id",
      "entity_id",
      "window_start",
      "window_end",
      "feature_value"
    ],
    "properties": {
      "feature_id": {
        "bsonType": "number"
      },
      "entity_id": {
        "bsonType": "string"
      },
      "window_start": {
        "bsonType": "date"
      },
      "window_end": {
        "bsonType": "string"
      },
      "feature_value": {
        "bsonType": "object"
      },
      "statistics": {
        "bsonType": "object"
      },
      "computed_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for feature_sets
db.runCommand({
  collMod: 'feature_sets',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "set_name",
      "feature_ids"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "set_name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "feature_ids": {
        "bsonType": "object"
      },
      "label_definition": {
        "bsonType": "object"
      },
      "split_config": {
        "bsonType": "object"
      },
      "validation_rules": {
        "bsonType": "object"
      },
      "version": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for experiments
db.runCommand({
  collMod: 'experiments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "experiment_name"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "experiment_name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "hypothesis": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "created_by": {
        "bsonType": "string"
      },
      "tags": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for experiment_runs
db.runCommand({
  collMod: 'experiment_runs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "experiment_id",
      "start_time"
    ],
    "properties": {
      "experiment_id": {
        "bsonType": "number"
      },
      "run_name": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "parameters": {
        "bsonType": "object"
      },
      "metrics": {
        "bsonType": "object"
      },
      "artifacts": {
        "bsonType": "object"
      },
      "environment": {
        "bsonType": "object"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "duration_seconds": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for run_metrics
db.runCommand({
  collMod: 'run_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "run_id",
      "metric_name",
      "timestamp"
    ],
    "properties": {
      "run_id": {
        "bsonType": "string"
      },
      "metric_name": {
        "bsonType": "string"
      },
      "metric_value": {
        "bsonType": "decimal128"
      },
      "step": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for models
db.runCommand({
  collMod: 'models',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "model_name",
      "model_version"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "experiment_id": {
        "bsonType": "number"
      },
      "run_id": {
        "bsonType": "string"
      },
      "model_name": {
        "bsonType": "string"
      },
      "model_version": {
        "bsonType": "string"
      },
      "algorithm": {
        "bsonType": "string"
      },
      "framework": {
        "bsonType": "string"
      },
      "model_type": {
        "bsonType": "string"
      },
      "feature_set_id": {
        "bsonType": "number"
      },
      "training_dataset": {
        "bsonType": "object"
      },
      "hyperparameters": {
        "bsonType": "object"
      },
      "model_size_bytes": {
        "bsonType": "number"
      },
      "model_location": {
        "bsonType": "string"
      },
      "metrics": {
        "bsonType": "object"
      },
      "tags": {
        "bsonType": "object"
      },
      "status": {
        "bsonType": "string"
      },
      "created_by": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for model_evaluations
db.runCommand({
  collMod: 'model_evaluations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "model_id",
      "metrics",
      "evaluation_timestamp"
    ],
    "properties": {
      "model_id": {
        "bsonType": "number"
      },
      "evaluation_type": {
        "bsonType": "string"
      },
      "dataset_info": {
        "bsonType": "object"
      },
      "metrics": {
        "bsonType": "object"
      },
      "confusion_matrix": {
        "bsonType": "object"
      },
      "roc_curve": {
        "bsonType": "object"
      },
      "precision_recall_curve": {
        "bsonType": "object"
      },
      "feature_importance": {
        "bsonType": "object"
      },
      "evaluation_timestamp": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for model_comparisons
db.runCommand({
  collMod: 'model_comparisons',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "model_ids"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "comparison_name": {
        "bsonType": "string"
      },
      "model_ids": {
        "bsonType": "object"
      },
      "comparison_metrics": {
        "bsonType": "object"
      },
      "winner_model_id": {
        "bsonType": "number"
      },
      "comparison_notes": {
        "bsonType": "string"
      },
      "created_by": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for model_deployments
db.runCommand({
  collMod: 'model_deployments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "model_id",
      "deployment_name"
    ],
    "properties": {
      "model_id": {
        "bsonType": "number"
      },
      "deployment_name": {
        "bsonType": "string"
      },
      "environment": {
        "bsonType": "string"
      },
      "deployment_type": {
        "bsonType": "string"
      },
      "endpoint_url": {
        "bsonType": "string"
      },
      "deployment_config": {
        "bsonType": "object"
      },
      "resource_config": {
        "bsonType": "object"
      },
      "scaling_config": {
        "bsonType": "object"
      },
      "traffic_percentage": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "health_status": {
        "bsonType": "string"
      },
      "deployed_at": {
        "bsonType": "date"
      },
      "retired_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for ab_tests
db.runCommand({
  collMod: 'ab_tests',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "project_id",
      "test_name",
      "control_deployment_id",
      "treatment_deployment_id"
    ],
    "properties": {
      "project_id": {
        "bsonType": "number"
      },
      "test_name": {
        "bsonType": "string"
      },
      "control_deployment_id": {
        "bsonType": "number"
      },
      "treatment_deployment_id": {
        "bsonType": "number"
      },
      "traffic_split": {
        "bsonType": "object"
      },
      "success_metrics": {
        "bsonType": "object"
      },
      "significance_level": {
        "bsonType": "decimal128"
      },
      "minimum_sample_size": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "winner_deployment_id": {
        "bsonType": "number"
      },
      "results": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for predictions
db.runCommand({
  collMod: 'predictions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "deployment_id",
      "input_features",
      "prediction_result",
      "prediction_timestamp"
    ],
    "properties": {
      "deployment_id": {
        "bsonType": "number"
      },
      "input_features": {
        "bsonType": "object"
      },
      "prediction_result": {
        "bsonType": "object"
      },
      "prediction_probability": {
        "bsonType": "decimal128"
      },
      "prediction_timestamp": {
        "bsonType": "string"
      },
      "response_time_ms": {
        "bsonType": "number"
      },
      "model_version": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for ground_truth
db.runCommand({
  collMod: 'ground_truth',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "true_label"
    ],
    "properties": {
      "true_label": {
        "bsonType": "object"
      },
      "feedback_type": {
        "bsonType": "string"
      },
      "feedback_source": {
        "bsonType": "string"
      },
      "received_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for drift_detection
db.runCommand({
  collMod: 'drift_detection',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "deployment_id",
      "reference_window_start",
      "reference_window_end",
      "current_window_start",
      "current_window_end"
    ],
    "properties": {
      "deployment_id": {
        "bsonType": "number"
      },
      "feature_name": {
        "bsonType": "string"
      },
      "drift_type": {
        "bsonType": "string"
      },
      "reference_window_start": {
        "bsonType": "date"
      },
      "reference_window_end": {
        "bsonType": "date"
      },
      "current_window_start": {
        "bsonType": "date"
      },
      "current_window_end": {
        "bsonType": "date"
      },
      "drift_score": {
        "bsonType": "decimal128"
      },
      "statistical_test": {
        "bsonType": "string"
      },
      "p_value": {
        "bsonType": "decimal128"
      },
      "is_significant": {
        "bsonType": "boolean"
      },
      "detected_at": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for performance_metrics
db.runCommand({
  collMod: 'performance_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "deployment_id",
      "metric_window_start",
      "metric_window_end"
    ],
    "properties": {
      "deployment_id": {
        "bsonType": "number"
      },
      "metric_window_start": {
        "bsonType": "date"
      },
      "metric_window_end": {
        "bsonType": "string"
      },
      "prediction_count": {
        "bsonType": "number"
      },
      "avg_response_time_ms": {
        "bsonType": "decimal128"
      },
      "p50_response_time_ms": {
        "bsonType": "decimal128"
      },
      "p95_response_time_ms": {
        "bsonType": "decimal128"
      },
      "p99_response_time_ms": {
        "bsonType": "decimal128"
      },
      "accuracy": {
        "bsonType": "decimal128"
      },
      "precision_score": {
        "bsonType": "decimal128"
      },
      "recall_score": {
        "bsonType": "decimal128"
      },
      "f1_score": {
        "bsonType": "decimal128"
      },
      "auc_roc": {
        "bsonType": "decimal128"
      },
      "confusion_matrix": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for model_alerts
db.runCommand({
  collMod: 'model_alerts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "deployment_id",
      "alert_message",
      "triggered_at"
    ],
    "properties": {
      "deployment_id": {
        "bsonType": "number"
      },
      "alert_type": {
        "bsonType": "string"
      },
      "severity": {
        "bsonType": "string"
      },
      "alert_message": {
        "bsonType": "string"
      },
      "alert_details": {
        "bsonType": "object"
      },
      "triggered_at": {
        "bsonType": "string"
      },
      "acknowledged_at": {
        "bsonType": "date"
      },
      "acknowledged_by": {
        "bsonType": "string"
      },
      "resolved_at": {
        "bsonType": "date"
      },
      "resolved_by": {
        "bsonType": "string"
      },
      "resolution_notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for compute_resources
db.runCommand({
  collMod: 'compute_resources',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "resource_type": {
        "bsonType": "string"
      },
      "provider": {
        "bsonType": "string"
      },
      "specifications": {
        "bsonType": "object"
      },
      "total_capacity": {
        "bsonType": "decimal128"
      },
      "available_capacity": {
        "bsonType": "decimal128"
      },
      "unit": {
        "bsonType": "string"
      },
      "cost_per_unit": {
        "bsonType": "decimal128"
      },
      "location": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for resource_allocations
db.runCommand({
  collMod: 'resource_allocations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "resource_id",
      "allocated_to_id",
      "allocation_start"
    ],
    "properties": {
      "resource_id": {
        "bsonType": "number"
      },
      "allocated_to_type": {
        "bsonType": "string"
      },
      "allocated_to_id": {
        "bsonType": "number"
      },
      "allocated_amount": {
        "bsonType": "decimal128"
      },
      "allocation_start": {
        "bsonType": "date"
      },
      "allocation_end": {
        "bsonType": "date"
      },
      "cost_estimate": {
        "bsonType": "decimal128"
      },
      "actual_cost": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for data_lineage
db.runCommand({
  collMod: 'data_lineage',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "source_id",
      "target_id"
    ],
    "properties": {
      "source_type": {
        "bsonType": "string"
      },
      "source_id": {
        "bsonType": "number"
      },
      "target_type": {
        "bsonType": "string"
      },
      "target_id": {
        "bsonType": "number"
      },
      "transformation_type": {
        "bsonType": "string"
      },
      "transformation_details": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for data_quality_rules
db.runCommand({
  collMod: 'data_quality_rules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "applies_to_id",
      "rule_name",
      "rule_definition"
    ],
    "properties": {
      "applies_to_type": {
        "bsonType": "string"
      },
      "applies_to_id": {
        "bsonType": "number"
      },
      "rule_name": {
        "bsonType": "string"
      },
      "rule_type": {
        "bsonType": "string"
      },
      "rule_definition": {
        "bsonType": "object"
      },
      "severity": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for data_quality_violations
db.runCommand({
  collMod: 'data_quality_violations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rule_id",
      "violation_timestamp"
    ],
    "properties": {
      "rule_id": {
        "bsonType": "number"
      },
      "violation_timestamp": {
        "bsonType": "string"
      },
      "affected_records": {
        "bsonType": "number"
      },
      "violation_details": {
        "bsonType": "object"
      },
      "severity": {
        "bsonType": "string"
      },
      "resolved": {
        "bsonType": "boolean"
      },
      "resolved_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for user_activity
db.runCommand({
  collMod: 'user_activity',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "org_id",
      "activity_timestamp"
    ],
    "properties": {
      "user_id": {
        "bsonType": "string"
      },
      "org_id": {
        "bsonType": "number"
      },
      "activity_type": {
        "bsonType": "string"
      },
      "activity_details": {
        "bsonType": "object"
      },
      "resource_type": {
        "bsonType": "string"
      },
      "resource_id": {
        "bsonType": "number"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "activity_timestamp": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for api_usage
db.runCommand({
  collMod: 'api_usage',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "org_id",
      "endpoint",
      "method",
      "request_timestamp"
    ],
    "properties": {
      "org_id": {
        "bsonType": "number"
      },
      "endpoint": {
        "bsonType": "string"
      },
      "method": {
        "bsonType": "string"
      },
      "request_timestamp": {
        "bsonType": "string"
      },
      "response_status": {
        "bsonType": "number"
      },
      "response_time_ms": {
        "bsonType": "number"
      },
      "request_size_bytes": {
        "bsonType": "number"
      },
      "response_size_bytes": {
        "bsonType": "number"
      },
      "error_message": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for predictions_hourly
db.runCommand({
  collMod: 'predictions_hourly',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "deployment_id",
      "hour_timestamp"
    ],
    "properties": {
      "deployment_id": {
        "bsonType": "number"
      },
      "hour_timestamp": {
        "bsonType": "string"
      },
      "prediction_count": {
        "bsonType": "number"
      },
      "avg_response_time_ms": {
        "bsonType": "decimal128"
      },
      "p95_response_time_ms": {
        "bsonType": "decimal128"
      },
      "error_count": {
        "bsonType": "number"
      }
    }
  }
}
});

// Validation for stream_events_daily
db.runCommand({
  collMod: 'stream_events_daily',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "stream_id",
      "day_date"
    ],
    "properties": {
      "stream_id": {
        "bsonType": "number"
      },
      "day_date": {
        "bsonType": "string"
      },
      "event_count": {
        "bsonType": "number"
      },
      "processed_count": {
        "bsonType": "number"
      },
      "failed_count": {
        "bsonType": "number"
      },
      "avg_processing_time_ms": {
        "bsonType": "decimal128"
      }
    }
  }
}
});
