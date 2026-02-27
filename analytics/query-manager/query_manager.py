#!/usr/bin/env python3
"""
Query Management System for MySQL Business-to-Schema
Manages query collections, templates, and sharing
"""

import json
import hashlib
import yaml
from datetime import datetime
from typing import Dict, List, Optional, Any
from pathlib import Path
import mysql.connector
from mysql.connector import Error
import re


class QueryManager:
    """Manages query collections and templates"""

    def __init__(self, config_path: str = "query_collections.yml"):
        """Initialize Query Manager"""
        self.config_path = Path(config_path)
        self.collections = {}
        self.templates = {}
        self.load_collections()

    def load_collections(self):
        """Load query collections from configuration file"""
        if self.config_path.exists():
            with open(self.config_path, "r") as f:
                data = yaml.safe_load(f) or {}
                self.collections = data.get("collections", {})
                self.templates = data.get("templates", {})

    def save_collections(self):
        """Save query collections to configuration file"""
        data = {
            "collections": self.collections,
            "templates": self.templates,
            "metadata": {
                "last_updated": datetime.now().isoformat(),
                "version": "1.0.0",
            },
        }

        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_path, "w") as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)

    def create_collection(
        self, name: str, description: str, database: str, tags: List[str] = None
    ) -> str:
        """Create a new query collection"""
        collection_id = self._generate_id(name)

        self.collections[collection_id] = {
            "id": collection_id,
            "name": name,
            "description": description,
            "database": database,
            "tags": tags or [],
            "queries": [],
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "version": 1,
            "shared": False,
            "author": "system",
        }

        self.save_collections()
        return collection_id

    def add_query(self, collection_id: str, query: Dict[str, Any]) -> str:
        """Add a query to a collection"""
        if collection_id not in self.collections:
            raise ValueError(f"Collection {collection_id} not found")

        # Generate query ID
        query_id = self._generate_id(query.get("name", query.get("sql", "")))

        # Prepare query object
        query_obj = {
            "id": query_id,
            "name": query.get("name", "Unnamed Query"),
            "description": query.get("description", ""),
            "sql": query["sql"],
            "tags": query.get("tags", []),
            "parameters": self._extract_parameters(query["sql"]),
            "created_at": datetime.now().isoformat(),
            "execution_stats": {
                "avg_time_ms": None,
                "execution_count": 0,
                "last_executed": None,
            },
            "category": query.get("category", "custom"),
            "complexity": self._analyze_complexity(query["sql"]),
        }

        # Add to collection
        self.collections[collection_id]["queries"].append(query_obj)
        self.collections[collection_id]["updated_at"] = datetime.now().isoformat()
        self.collections[collection_id]["version"] += 1

        self.save_collections()
        return query_id

    def create_template(
        self, name: str, template_sql: str, description: str, variables: List[Dict]
    ) -> str:
        """Create a reusable query template"""
        template_id = self._generate_id(name)

        self.templates[template_id] = {
            "id": template_id,
            "name": name,
            "description": description,
            "template_sql": template_sql,
            "variables": variables,  # [{'name': 'table_name', 'type': 'string', 'default': ''}]
            "examples": [],
            "created_at": datetime.now().isoformat(),
            "usage_count": 0,
        }

        self.save_collections()
        return template_id

    def render_template(self, template_id: str, variables: Dict[str, Any]) -> str:
        """Render a query template with variables"""
        if template_id not in self.templates:
            raise ValueError(f"Template {template_id} not found")

        template = self.templates[template_id]
        sql = template["template_sql"]

        # Replace variables
        for var in template["variables"]:
            var_name = var["name"]
            var_value = variables.get(var_name, var.get("default", ""))

            # Escape value based on type
            if var["type"] == "string":
                var_value = f"'{var_value}'"
            elif var["type"] == "identifier":
                var_value = f"`{var_value}`"

            sql = sql.replace(f"{{{{{var_name}}}}}", str(var_value))

        # Update usage count
        self.templates[template_id]["usage_count"] += 1
        self.save_collections()

        return sql

    def search_queries(
        self, search_term: str, tags: List[str] = None, database: str = None
    ) -> List[Dict]:
        """Search for queries across collections"""
        results = []
        search_lower = search_term.lower()

        for collection in self.collections.values():
            # Filter by database if specified
            if database and collection["database"] != database:
                continue

            for query in collection["queries"]:
                # Search in query name, description, and SQL
                if (
                    search_lower in query["name"].lower()
                    or search_lower in query["description"].lower()
                    or search_lower in query["sql"].lower()
                ):

                    # Filter by tags if specified
                    if tags and not any(tag in query["tags"] for tag in tags):
                        continue

                    results.append(
                        {
                            "collection": collection["name"],
                            "collection_id": collection["id"],
                            "query": query,
                        }
                    )

        return results

    def export_collection(self, collection_id: str, format: str = "json") -> str:
        """Export a collection to various formats"""
        if collection_id not in self.collections:
            raise ValueError(f"Collection {collection_id} not found")

        collection = self.collections[collection_id]

        if format == "json":
            return json.dumps(collection, indent=2, default=str)

        elif format == "sql":
            # Export as SQL file with comments
            sql_content = f"""-- Query Collection: {collection['name']}
-- Description: {collection['description']}
-- Database: {collection['database']}
-- Generated: {datetime.now().isoformat()}
-- Version: {collection['version']}

"""
            for query in collection["queries"]:
                sql_content += f"""
-- =====================================================
-- Query: {query['name']}
-- Description: {query['description']}
-- Tags: {', '.join(query['tags'])}
-- Complexity: {query['complexity']}
-- =====================================================

{query['sql']}

"""
            return sql_content

        elif format == "markdown":
            # Export as Markdown documentation
            md_content = f"""# {collection['name']}

**Description:** {collection['description']}
**Database:** `{collection['database']}`
**Last Updated:** {collection['updated_at']}
**Version:** {collection['version']}

## Queries

"""
            for i, query in enumerate(collection["queries"], 1):
                md_content += f"""
### {i}. {query['name']}

{query['description']}

**Tags:** {', '.join(f'`{tag}`' for tag in query['tags'])}
**Complexity:** {query['complexity']}

```sql
{query['sql']}
```

"""
            return md_content

        else:
            raise ValueError(f"Unsupported export format: {format}")

    def import_collection(self, data: str, format: str = "json") -> str:
        """Import a collection from various formats"""
        if format == "json":
            collection = json.loads(data)
            collection_id = collection["id"]

            # Check for conflicts
            if collection_id in self.collections:
                # Generate new ID for imported collection
                collection_id = self._generate_id(collection["name"] + "_imported")
                collection["id"] = collection_id
                collection["name"] = collection["name"] + " (Imported)"

            self.collections[collection_id] = collection
            self.save_collections()
            return collection_id

        else:
            raise ValueError(f"Unsupported import format: {format}")

    def share_collection(self, collection_id: str, share_code: str = None) -> str:
        """Generate a shareable link/code for a collection"""
        if collection_id not in self.collections:
            raise ValueError(f"Collection {collection_id} not found")

        if not share_code:
            # Generate unique share code
            share_code = hashlib.md5(
                f"{collection_id}{datetime.now().isoformat()}".encode()
            ).hexdigest()[:8]

        self.collections[collection_id]["shared"] = True
        self.collections[collection_id]["share_code"] = share_code
        self.save_collections()

        return share_code

    def get_statistics(self) -> Dict[str, Any]:
        """Get statistics about query collections"""
        total_queries = sum(len(col["queries"]) for col in self.collections.values())

        databases = list(set(col["database"] for col in self.collections.values()))

        all_tags = []
        for col in self.collections.values():
            for query in col["queries"]:
                all_tags.extend(query["tags"])

        tag_frequency = {}
        for tag in all_tags:
            tag_frequency[tag] = tag_frequency.get(tag, 0) + 1

        return {
            "total_collections": len(self.collections),
            "total_queries": total_queries,
            "total_templates": len(self.templates),
            "databases": databases,
            "popular_tags": sorted(
                tag_frequency.items(), key=lambda x: x[1], reverse=True
            )[:10],
            "shared_collections": sum(
                1 for col in self.collections.values() if col.get("shared")
            ),
        }

    def _generate_id(self, text: str) -> str:
        """Generate a unique ID from text"""
        return hashlib.md5(text.encode()).hexdigest()[:12]

    def _extract_parameters(self, sql: str) -> List[str]:
        """Extract parameter placeholders from SQL"""
        # Find :param_name or @param_name patterns
        params = re.findall(r"[:@](\w+)", sql)
        return list(set(params))

    def _analyze_complexity(self, sql: str) -> str:
        """Analyze query complexity"""
        sql_upper = sql.upper()

        # Count various SQL features
        join_count = sql_upper.count("JOIN")
        subquery_count = sql_upper.count("SELECT") - 1
        union_count = sql_upper.count("UNION")

        # Determine complexity level
        if join_count > 3 or subquery_count > 2 or union_count > 0:
            return "high"
        elif join_count > 1 or subquery_count > 0:
            return "medium"
        else:
            return "low"


class QueryOptimizer:
    """Optimize and analyze queries"""

    def __init__(self, connection_params: Dict[str, Any]):
        """Initialize Query Optimizer"""
        self.connection_params = connection_params

    def analyze_query(self, sql: str) -> Dict[str, Any]:
        """Analyze a query for performance issues"""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor(dictionary=True)

            # Get execution plan
            cursor.execute(f"EXPLAIN {sql}")
            explain_results = cursor.fetchall()

            # Analyze the plan
            issues = []
            suggestions = []

            for row in explain_results:
                # Check for full table scans
                if row.get("type") == "ALL":
                    issues.append(
                        {
                            "type": "full_table_scan",
                            "table": row.get("table"),
                            "severity": "high",
                        }
                    )
                    suggestions.append(
                        f"Consider adding an index on {row.get('table')}"
                    )

                # Check for filesort
                if "Using filesort" in str(row.get("Extra", "")):
                    issues.append(
                        {
                            "type": "filesort",
                            "table": row.get("table"),
                            "severity": "medium",
                        }
                    )
                    suggestions.append("Consider adding an index to support ORDER BY")

                # Check for temporary tables
                if "Using temporary" in str(row.get("Extra", "")):
                    issues.append(
                        {
                            "type": "temporary_table",
                            "table": row.get("table"),
                            "severity": "medium",
                        }
                    )

            cursor.close()
            conn.close()

            return {
                "execution_plan": explain_results,
                "issues": issues,
                "suggestions": suggestions,
                "estimated_rows": sum(row.get("rows", 0) for row in explain_results),
            }

        except Error as e:
            return {"error": str(e), "issues": [], "suggestions": []}

    def suggest_indexes(self, sql: str, table_schema: Dict) -> List[str]:
        """Suggest indexes based on query patterns"""
        suggestions = []
        sql_upper = sql.upper()

        # Extract WHERE conditions
        where_match = re.search(r"WHERE\s+(.*?)(?:GROUP|ORDER|LIMIT|$)", sql_upper)
        if where_match:
            where_clause = where_match.group(1)
            # Extract column names from WHERE clause
            columns = re.findall(r"(\w+)\s*[=<>]", where_clause)
            if columns:
                suggestions.append(
                    f"CREATE INDEX idx_where ON table ({', '.join(set(columns))})"
                )

        # Extract JOIN conditions
        join_matches = re.findall(
            r"JOIN.*?ON\s+(.*?)(?:JOIN|WHERE|GROUP|ORDER|$)", sql_upper
        )
        for join_condition in join_matches:
            columns = re.findall(r"(\w+)\s*=\s*\w+\.(\w+)", join_condition)
            for col_pair in columns:
                suggestions.append(
                    f"CREATE INDEX idx_join_{col_pair[0]} ON table ({col_pair[0]})"
                )

        # Extract ORDER BY columns
        order_match = re.search(r"ORDER\s+BY\s+(.*?)(?:LIMIT|$)", sql_upper)
        if order_match:
            order_clause = order_match.group(1)
            columns = re.findall(r"(\w+)(?:\s+(?:ASC|DESC))?", order_clause)
            if columns:
                suggestions.append(
                    f"CREATE INDEX idx_order ON table ({', '.join(columns)})"
                )

        return list(set(suggestions))


def create_default_collections():
    """Create default query collections for each database"""
    manager = QueryManager()

    # Medical Clinic Collection
    clinic_id = manager.create_collection(
        name="Medical Clinic Analytics",
        description="Common queries for medical clinic database",
        database="clinic_db",
        tags=["healthcare", "analytics", "reporting"],
    )

    manager.add_query(
        clinic_id,
        {
            "name": "Daily Appointment Summary",
            "description": "Get appointment counts and revenue by day",
            "sql": """
SELECT
    DATE(appointment_date) as date,
    COUNT(*) as total_appointments,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled,
    SUM(billing_amount) as total_revenue
FROM appointments a
LEFT JOIN billing b ON a.appointment_id = b.appointment_id
WHERE appointment_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(appointment_date)
ORDER BY date DESC;
        """,
            "tags": ["reporting", "revenue"],
            "category": "analytics",
        },
    )

    manager.add_query(
        clinic_id,
        {
            "name": "Doctor Utilization Report",
            "description": "Analyze doctor appointment load and utilization",
            "sql": """
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) as doctor_name,
    s.name as specialty,
    COUNT(a.appointment_id) as total_appointments,
    AVG(TIMESTAMPDIFF(MINUTE, a.start_time, a.end_time)) as avg_duration_minutes,
    COUNT(DISTINCT DATE(a.appointment_date)) as days_worked
FROM doctors d
JOIN specialties s ON d.specialty_id = s.specialty_id
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
WHERE a.appointment_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.doctor_id, s.name
ORDER BY total_appointments DESC;
        """,
            "tags": ["utilization", "doctors", "performance"],
            "category": "analytics",
        },
    )

    # IoT Bins Collection
    iot_id = manager.create_collection(
        name="IoT Waste Management Queries",
        description="Monitoring and analytics for smart waste bins",
        database="iot_bins",
        tags=["iot", "monitoring", "smart-city"],
    )

    manager.add_query(
        iot_id,
        {
            "name": "Bins Requiring Collection",
            "description": "Find bins that need immediate collection",
            "sql": """
SELECT
    b.bin_id,
    b.location,
    b.bin_type,
    r.fill_level,
    r.temperature,
    r.battery_level,
    TIMESTAMPDIFF(HOUR, r.timestamp, NOW()) as hours_since_reading
FROM bins b
JOIN (
    SELECT bin_id, MAX(timestamp) as latest
    FROM sensor_readings
    GROUP BY bin_id
) latest_reading ON b.bin_id = latest_reading.bin_id
JOIN sensor_readings r ON r.bin_id = b.bin_id AND r.timestamp = latest_reading.latest
WHERE r.fill_level > 75
   OR r.battery_level < 20
   OR TIMESTAMPDIFF(HOUR, r.timestamp, NOW()) > 24
ORDER BY r.fill_level DESC, r.battery_level ASC;
        """,
            "tags": ["monitoring", "operations", "alerts"],
            "category": "operational",
        },
    )

    # E-Commerce Collection
    ecommerce_id = manager.create_collection(
        name="E-Commerce Analytics Suite",
        description="Sales, inventory, and customer analytics",
        database="ecommerce_db",
        tags=["ecommerce", "sales", "analytics"],
    )

    manager.add_query(
        ecommerce_id,
        {
            "name": "Top Selling Products",
            "description": "Identify best-selling products by revenue and quantity",
            "sql": """
SELECT
    p.product_id,
    p.name as product_name,
    c.name as category,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    AVG(r.rating) as avg_rating,
    COUNT(r.review_id) as review_count
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN reviews r ON p.product_id = r.product_id
WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
  AND o.status IN ('completed', 'shipped')
GROUP BY p.product_id, c.name
ORDER BY total_revenue DESC
LIMIT 20;
        """,
            "tags": ["sales", "products", "revenue"],
            "category": "analytics",
        },
    )

    # Create query templates
    manager.create_template(
        name="Table Statistics",
        template_sql="""
SELECT
    '{{table_name}}' as table_name,
    COUNT(*) as row_count,
    COUNT(DISTINCT {{primary_key}}) as unique_keys,
    MIN({{date_column}}) as earliest_date,
    MAX({{date_column}}) as latest_date,
    ROUND(AVG(LENGTH({{text_column}}))) as avg_text_length
FROM {{table_name}}
WHERE {{date_column}} >= DATE_SUB(CURDATE(), INTERVAL {{days}} DAY);
        """,
        description="Get basic statistics for any table",
        variables=[
            {"name": "table_name", "type": "identifier", "default": "users"},
            {"name": "primary_key", "type": "identifier", "default": "id"},
            {"name": "date_column", "type": "identifier", "default": "created_at"},
            {"name": "text_column", "type": "identifier", "default": "description"},
            {"name": "days", "type": "number", "default": 30},
        ],
    )

    print("Default query collections created successfully!")

    # Display statistics
    stats = manager.get_statistics()
    print(f"\nQuery Manager Statistics:")
    print(f"  Collections: {stats['total_collections']}")
    print(f"  Queries: {stats['total_queries']}")
    print(f"  Templates: {stats['total_templates']}")
    print(f"  Databases: {', '.join(stats['databases'])}")


if __name__ == "__main__":
    create_default_collections()
