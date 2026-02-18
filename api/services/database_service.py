"""
Database Microservice
Handles all database operations including schema management and data generation
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import os
import sys
import importlib
import json
from datetime import datetime
import asyncio
import logging
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Database Microservice",
    description="Database schema management and data generation service",
    version="1.0.0"
)

# Request/Response Models
class DatabaseInfo(BaseModel):
    name: str
    description: str
    tables: int
    has_generator: bool
    supported_formats: List[str] = ["mysql", "postgresql", "mongodb"]


class SchemaRequest(BaseModel):
    database: str
    format: str = "mysql"


class SchemaResponse(BaseModel):
    database: str
    format: str
    schema: Dict[str, Any]
    generated_at: datetime = Field(default_factory=datetime.now)


class GenerateDataRequest(BaseModel):
    rows: int = Field(default=1000, ge=1, le=1000000)
    format: str = "sql"
    include_indexes: bool = True
    include_constraints: bool = True


class GenerateDataResponse(BaseModel):
    database: str
    rows_generated: int
    format: str
    file_path: Optional[str] = None
    status: str
    generated_at: datetime = Field(default_factory=datetime.now)


class QueryRequest(BaseModel):
    database: str
    query: str
    limit: int = Field(default=100, ge=1, le=10000)


class QueryResponse(BaseModel):
    database: str
    query: str
    results: List[Dict[str, Any]]
    row_count: int
    execution_time_ms: float


# Database Registry
DATABASES = {
    "ecommerce": {
        "name": "E-Commerce Platform",
        "description": "Complete e-commerce database with products, orders, customers",
        "tables": 15,
        "generator": "generators.ecommerce.generator",
        "example_path": "examples/example_09_ecommerce"
    },
    "fintech": {
        "name": "FinTech Platform",
        "description": "Financial technology platform with transactions and accounts",
        "tables": 12,
        "generator": "generators.fintech.generator",
        "example_path": "examples/example_13_fintech"
    },
    "social_media": {
        "name": "Social Media Network",
        "description": "Social networking platform with users, posts, interactions",
        "tables": 14,
        "generator": "generators.social_media.generator",
        "example_path": "examples/example_12_social_media"
    },
    "healthcare_iot": {
        "name": "Healthcare IoT",
        "description": "IoT-enabled healthcare monitoring system",
        "tables": 10,
        "generator": "generators.healthcare_iot.generator",
        "example_path": "examples/example_05_healthcare_iot"
    },
    "smart_energy": {
        "name": "Smart Energy Grid",
        "description": "Smart grid energy management system",
        "tables": 11,
        "generator": "generators.smart_energy.generator",
        "example_path": "examples/example_07_smart_energy"
    },
    "iot_bins": {
        "name": "IoT Waste Management",
        "description": "Smart waste management with IoT sensors",
        "tables": 8,
        "generator": "generators.iot_bins.generator",
        "example_path": "examples/example_02_iot_bins"
    },
    "education": {
        "name": "Education Platform",
        "description": "Online education and learning management system",
        "tables": 13,
        "generator": "generators.education.generator",
        "example_path": "examples/example_14_education"
    },
    "event_ticketing": {
        "name": "Event Ticketing",
        "description": "Event management and ticketing platform",
        "tables": 11,
        "generator": "generators.event_ticketing.generator",
        "example_path": "examples/example_15_event_ticketing"
    },
    "real_estate": {
        "name": "Real Estate Platform",
        "description": "Property listing and management system",
        "tables": 12,
        "generator": "generators.real_estate.generator",
        "example_path": "examples/example_11_real_estate"
    },
    "industrial_iot": {
        "name": "Industrial IoT",
        "description": "Industrial IoT monitoring and control system",
        "tables": 9,
        "generator": "generators.industrial_iot.generator",
        "example_path": "examples/example_06_industrial_iot"
    }
}


# Schema Cache
schema_cache = {}


async def load_schema(database: str, format: str = "mysql") -> Dict[str, Any]:
    """Load schema for a database"""
    cache_key = f"{database}:{format}"

    if cache_key in schema_cache:
        return schema_cache[cache_key]

    if database not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {database} not found")

    db_info = DATABASES[database]

    # Try to load schema file
    schema_path = Path(db_info["example_path"]) / "schema.sql"

    if schema_path.exists():
        with open(schema_path, 'r') as f:
            schema_content = f.read()

        # Parse schema based on format
        if format == "mysql":
            schema = parse_mysql_schema(schema_content)
        elif format == "postgresql":
            # Convert MySQL to PostgreSQL
            from converters.postgresql_converter import MySQLToPostgreSQLConverter
            converter = MySQLToPostgreSQLConverter()
            schema = converter.convert(schema_content)
        elif format == "mongodb":
            # Convert to MongoDB collections
            from converters.mongodb_converter import MySQLToMongoDBConverter
            converter = MySQLToMongoDBConverter()
            schema = converter.convert(schema_content)
        else:
            schema = {"raw": schema_content}

        schema_cache[cache_key] = schema
        return schema
    else:
        # Generate schema dynamically
        return generate_dynamic_schema(database, format)


def parse_mysql_schema(schema_content: str) -> Dict[str, Any]:
    """Parse MySQL schema into structured format"""
    tables = {}
    current_table = None

    lines = schema_content.split('\n')
    for line in lines:
        line = line.strip()

        # Parse CREATE TABLE
        if line.startswith('CREATE TABLE'):
            table_name = line.split('`')[1] if '`' in line else line.split()[2]
            current_table = table_name
            tables[current_table] = {
                "columns": [],
                "indexes": [],
                "constraints": []
            }

        # Parse columns
        elif current_table and line and not line.startswith(('PRIMARY', 'KEY', 'INDEX', 'CONSTRAINT', ')')):
            if '`' in line:
                parts = line.split('`')
                if len(parts) >= 2:
                    column_name = parts[1]
                    column_def = line.split('`')[2].strip().rstrip(',')
                    tables[current_table]["columns"].append({
                        "name": column_name,
                        "definition": column_def
                    })

        # Parse constraints
        elif current_table and 'PRIMARY KEY' in line:
            tables[current_table]["constraints"].append({
                "type": "PRIMARY KEY",
                "definition": line
            })

        # End of table
        elif line.startswith(');'):
            current_table = None

    return {
        "database_type": "mysql",
        "tables": tables,
        "table_count": len(tables)
    }


def generate_dynamic_schema(database: str, format: str) -> Dict[str, Any]:
    """Generate schema dynamically from generator module"""
    if database not in DATABASES:
        return {}

    db_info = DATABASES[database]

    try:
        # Import generator module
        module = importlib.import_module(db_info["generator"])
        generator = module.DataGenerator()

        # Generate schema based on generator's configuration
        schema = {
            "database_type": format,
            "database_name": database,
            "tables": {},
            "description": db_info["description"]
        }

        # Add sample table structure
        schema["tables"] = {
            "sample_table": {
                "columns": [
                    {"name": "id", "type": "INT", "constraints": "PRIMARY KEY AUTO_INCREMENT"},
                    {"name": "created_at", "type": "TIMESTAMP", "default": "CURRENT_TIMESTAMP"}
                ]
            }
        }

        return schema

    except Exception as e:
        logger.error(f"Error generating schema for {database}: {e}")
        return {}


async def generate_data_async(database: str, request: GenerateDataRequest) -> Dict[str, Any]:
    """Generate data asynchronously"""
    if database not in DATABASES:
        raise ValueError(f"Database {database} not found")

    db_info = DATABASES[database]

    try:
        # Import generator module
        module = importlib.import_module(db_info["generator"])
        generator = module.DataGenerator()

        # Generate data
        logger.info(f"Generating {request.rows} rows for {database}")
        data = generator.generate_batch(request.rows)

        # Save to file based on format
        output_dir = Path("output") / database
        output_dir.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        if request.format == "sql":
            file_path = output_dir / f"data_{timestamp}.sql"
            with open(file_path, 'w') as f:
                f.write(f"-- Generated data for {database}\n")
                f.write(f"-- Rows: {request.rows}\n")
                f.write(f"-- Generated at: {datetime.now()}\n\n")

                # Write INSERT statements
                for record in data:
                    f.write(f"INSERT INTO table_name VALUES {record};\n")

        elif request.format == "json":
            file_path = output_dir / f"data_{timestamp}.json"
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2, default=str)

        elif request.format == "csv":
            import csv
            file_path = output_dir / f"data_{timestamp}.csv"
            if data:
                with open(file_path, 'w', newline='') as f:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)

        else:
            file_path = None

        return {
            "database": database,
            "rows_generated": len(data),
            "format": request.format,
            "file_path": str(file_path) if file_path else None,
            "status": "completed"
        }

    except Exception as e:
        logger.error(f"Error generating data for {database}: {e}")
        return {
            "database": database,
            "rows_generated": 0,
            "format": request.format,
            "file_path": None,
            "status": f"error: {str(e)}"
        }


# API Endpoints

@app.get("/health")
async def health_check():
    """Service health check"""
    return {
        "service": "database",
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    }


@app.get("/databases", response_model=List[DatabaseInfo])
async def list_databases():
    """List all available databases"""
    databases = []
    for key, info in DATABASES.items():
        databases.append(DatabaseInfo(
            name=key,
            description=info["description"],
            tables=info["tables"],
            has_generator=bool(info.get("generator"))
        ))
    return databases


@app.get("/databases/{db_name}")
async def get_database_info(db_name: str):
    """Get detailed information about a database"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    db_info = DATABASES[db_name]
    return {
        "name": db_name,
        "description": db_info["description"],
        "tables": db_info["tables"],
        "has_generator": bool(db_info.get("generator")),
        "example_path": db_info["example_path"],
        "supported_operations": [
            "schema",
            "generate",
            "query",
            "export"
        ]
    }


@app.get("/databases/{db_name}/schema", response_model=SchemaResponse)
async def get_schema(db_name: str, format: str = "mysql"):
    """Get schema for a database"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    schema = await load_schema(db_name, format)

    return SchemaResponse(
        database=db_name,
        format=format,
        schema=schema
    )


@app.post("/databases/{db_name}/generate", response_model=GenerateDataResponse)
async def generate_data(
    db_name: str,
    request: GenerateDataRequest,
    background_tasks: BackgroundTasks
):
    """Generate sample data for a database"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    # For large datasets, run in background
    if request.rows > 10000:
        background_tasks.add_task(generate_data_async, db_name, request)
        return GenerateDataResponse(
            database=db_name,
            rows_generated=0,
            format=request.format,
            status="processing"
        )
    else:
        # Generate synchronously for small datasets
        result = await generate_data_async(db_name, request)
        return GenerateDataResponse(**result)


@app.post("/databases/{db_name}/query", response_model=QueryResponse)
async def execute_query(db_name: str, request: QueryRequest):
    """Execute a query on a database (simulation)"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    # Simulate query execution
    import time
    start_time = time.time()

    # Parse query type
    query_upper = request.query.upper()

    if query_upper.startswith("SELECT"):
        # Simulate SELECT results
        results = [
            {"id": i, "name": f"Record {i}", "value": i * 10}
            for i in range(min(request.limit, 10))
        ]
    elif query_upper.startswith("INSERT"):
        results = [{"affected_rows": 1}]
    elif query_upper.startswith("UPDATE"):
        results = [{"affected_rows": 5}]
    elif query_upper.startswith("DELETE"):
        results = [{"affected_rows": 3}]
    else:
        results = []

    execution_time = (time.time() - start_time) * 1000

    return QueryResponse(
        database=db_name,
        query=request.query,
        results=results,
        row_count=len(results),
        execution_time_ms=execution_time
    )


@app.post("/databases/{db_name}/export")
async def export_database(
    db_name: str,
    format: str = "sql",
    include_data: bool = True,
    include_schema: bool = True
):
    """Export database schema and/or data"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    export_path = Path("exports") / db_name
    export_path.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_name = f"{db_name}_{timestamp}.{format}"
    file_path = export_path / file_name

    # Generate export content
    content = []

    if include_schema:
        schema = await load_schema(db_name, "mysql")
        content.append(f"-- Schema for {db_name}")
        content.append(json.dumps(schema, indent=2, default=str))

    if include_data:
        content.append(f"\n-- Sample data for {db_name}")
        content.append("-- [Data would be generated here]")

    with open(file_path, 'w') as f:
        f.write('\n'.join(content))

    return {
        "database": db_name,
        "format": format,
        "file_path": str(file_path),
        "file_size": file_path.stat().st_size,
        "include_schema": include_schema,
        "include_data": include_data,
        "exported_at": datetime.now().isoformat()
    }


@app.get("/databases/{db_name}/statistics")
async def get_database_statistics(db_name: str):
    """Get statistics for a database"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    db_info = DATABASES[db_name]

    # Simulate statistics
    return {
        "database": db_name,
        "tables": db_info["tables"],
        "estimated_rows": db_info["tables"] * 10000,
        "estimated_size_mb": db_info["tables"] * 5,
        "indexes": db_info["tables"] * 3,
        "constraints": db_info["tables"] * 2,
        "last_updated": datetime.now().isoformat(),
        "access_pattern": {
            "reads_per_second": 150,
            "writes_per_second": 50,
            "cache_hit_ratio": 0.85
        }
    }


@app.post("/databases/{db_name}/validate")
async def validate_schema(db_name: str, schema: Dict[str, Any]):
    """Validate a schema against database rules"""
    if db_name not in DATABASES:
        raise HTTPException(status_code=404, detail=f"Database {db_name} not found")

    # Perform validation
    errors = []
    warnings = []

    # Check for required elements
    if "tables" not in schema:
        errors.append("Schema must contain 'tables' field")

    # Check table definitions
    for table_name, table_def in schema.get("tables", {}).items():
        if "columns" not in table_def:
            errors.append(f"Table {table_name} must have columns")

        # Check for primary key
        has_primary = any(
            "PRIMARY" in str(col.get("constraints", ""))
            for col in table_def.get("columns", [])
        )
        if not has_primary:
            warnings.append(f"Table {table_name} should have a primary key")

    return {
        "database": db_name,
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "validated_at": datetime.now().isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001, log_level="info")