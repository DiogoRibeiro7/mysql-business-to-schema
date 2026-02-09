#!/usr/bin/env python3
"""
Advanced Analytics Module for MySQL Examples Web Interface.
Provides SQL execution, ER diagram generation, and performance analysis.
"""

import json
import tempfile
import subprocess
import mysql.connector
from pathlib import Path
from datetime import datetime, timedelta
import yaml
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import seaborn as sns
from io import BytesIO
import base64

# For ER diagram generation
try:
    import graphviz
    GRAPHVIZ_AVAILABLE = True
except ImportError:
    GRAPHVIZ_AVAILABLE = False

class SQLExecutor:
    """Safely execute SQL queries with timeout and resource limits."""

    def __init__(self, host='localhost', user='root', password='', database=None):
        self.connection_params = {
            'host': host,
            'user': user,
            'password': password,
            'database': database,
            'autocommit': False,
            'connection_timeout': 5
        }

    def execute_query(self, query, database=None, limit=100, timeout=10):
        """
        Execute a SQL query with safety measures.

        Args:
            query: SQL query to execute
            database: Database to use
            limit: Maximum rows to return
            timeout: Query timeout in seconds

        Returns:
            Dict with results or error information
        """
        result = {
            'success': False,
            'data': [],
            'columns': [],
            'row_count': 0,
            'execution_time': 0,
            'error': None,
            'query_plan': None
        }

        # Safety checks
        query_lower = query.lower().strip()

        # Prevent dangerous operations
        dangerous_keywords = ['drop', 'truncate', 'delete', 'update', 'insert', 'alter', 'create user', 'grant', 'revoke']
        for keyword in dangerous_keywords:
            if keyword in query_lower:
                result['error'] = f"Query contains restricted operation: {keyword}"
                return result

        # Add LIMIT if not present for SELECT queries
        if query_lower.startswith('select') and 'limit' not in query_lower:
            query = f"{query.rstrip(';')} LIMIT {limit}"

        conn = None
        cursor = None

        try:
            # Connect to database
            params = self.connection_params.copy()
            if database:
                params['database'] = database

            conn = mysql.connector.connect(**params)
            cursor = conn.cursor(dictionary=True)

            # Set query timeout
            cursor.execute(f"SET SESSION max_execution_time={timeout * 1000}")

            # Get query execution plan
            if query_lower.startswith('select'):
                cursor.execute(f"EXPLAIN {query}")
                result['query_plan'] = cursor.fetchall()

            # Execute the actual query
            import time
            start_time = time.time()
            cursor.execute(query)
            execution_time = time.time() - start_time

            # Fetch results
            if cursor.description:
                result['columns'] = [desc[0] for desc in cursor.description]
                result['data'] = cursor.fetchall()
                result['row_count'] = len(result['data'])

            result['success'] = True
            result['execution_time'] = round(execution_time * 1000, 2)  # Convert to ms

        except mysql.connector.Error as e:
            result['error'] = str(e)
        except Exception as e:
            result['error'] = f"Unexpected error: {str(e)}"
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()

        return result

class ERDiagramGenerator:
    """Generate Entity-Relationship diagrams from database schemas."""

    def __init__(self):
        self.graph = None

    def analyze_schema(self, schema_file_path):
        """Analyze SQL schema file to extract tables and relationships."""
        tables = {}
        foreign_keys = []

        with open(schema_file_path, 'r') as f:
            content = f.read()

        # Parse CREATE TABLE statements
        import re

        # Find all CREATE TABLE statements
        table_pattern = r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\((.*?)\);'
        matches = re.finditer(table_pattern, content, re.IGNORECASE | re.DOTALL)

        for match in matches:
            table_name = match.group(1)
            table_content = match.group(2)

            columns = []

            # Parse columns
            lines = table_content.split(',')
            for line in lines:
                line = line.strip()

                # Skip constraints
                if any(keyword in line.upper() for keyword in ['PRIMARY KEY', 'FOREIGN KEY', 'INDEX', 'UNIQUE', 'CONSTRAINT']):

                    # Check for foreign keys
                    fk_pattern = r'FOREIGN\s+KEY\s*\(`?(\w+)`?\)\s+REFERENCES\s+`?(\w+)`?\s*\(`?(\w+)`?\)'
                    fk_match = re.search(fk_pattern, line, re.IGNORECASE)
                    if fk_match:
                        foreign_keys.append({
                            'from_table': table_name,
                            'from_column': fk_match.group(1),
                            'to_table': fk_match.group(2),
                            'to_column': fk_match.group(3)
                        })
                    continue

                # Parse column definition
                col_pattern = r'^`?(\w+)`?\s+(\w+(?:\([^)]+\))?)'
                col_match = re.match(col_pattern, line)
                if col_match:
                    col_name = col_match.group(1)
                    col_type = col_match.group(2)

                    # Check for column attributes
                    is_primary = 'PRIMARY KEY' in line.upper()
                    is_unique = 'UNIQUE' in line.upper()
                    is_nullable = 'NOT NULL' not in line.upper()

                    columns.append({
                        'name': col_name,
                        'type': col_type,
                        'primary': is_primary,
                        'unique': is_unique,
                        'nullable': is_nullable
                    })

            tables[table_name] = columns

        return tables, foreign_keys

    def generate_diagram(self, schema_path, output_format='svg'):
        """Generate ER diagram from schema files."""
        if not GRAPHVIZ_AVAILABLE:
            return None, "Graphviz is not installed"

        try:
            from graphviz import Digraph

            dot = Digraph(comment='ER Diagram', format=output_format)
            dot.attr(rankdir='TB', splines='ortho', nodesep='0.5', ranksep='1.0')
            dot.attr('node', shape='record', style='filled', fillcolor='lightblue')

            all_tables = {}
            all_foreign_keys = []

            # Process all SQL files in the schema directory
            schema_dir = Path(schema_path)
            for sql_file in schema_dir.glob('*.sql'):
                tables, foreign_keys = self.analyze_schema(sql_file)
                all_tables.update(tables)
                all_foreign_keys.extend(foreign_keys)

            # Add tables to diagram
            for table_name, columns in all_tables.items():
                # Create table label
                label = f"{{<table> {table_name}|"

                for col in columns:
                    col_str = col['name']
                    if col['primary']:
                        col_str = f"PK: {col_str}"
                    col_str += f" : {col['type']}"
                    if not col['nullable']:
                        col_str += " NOT NULL"
                    label += f"{col_str}\\l"

                label += "}"

                dot.node(table_name, label, shape='record')

            # Add foreign key relationships
            for fk in all_foreign_keys:
                dot.edge(
                    fk['from_table'],
                    fk['to_table'],
                    label=f"{fk['from_column']} -> {fk['to_column']}",
                    arrowhead='crow',
                    arrowtail='none'
                )

            # Render to bytes
            output = dot.pipe(format=output_format)

            # Convert to base64 for embedding in HTML
            if output_format == 'svg':
                return output.decode('utf-8'), None
            else:
                return base64.b64encode(output).decode('utf-8'), None

        except Exception as e:
            return None, str(e)

class PerformanceAnalyzer:
    """Analyze query and schema performance metrics."""

    def __init__(self, connection_params):
        self.connection_params = connection_params

    def analyze_table_stats(self, database, table):
        """Get detailed statistics for a table."""
        stats = {}

        try:
            conn = mysql.connector.connect(**self.connection_params, database=database)
            cursor = conn.cursor(dictionary=True)

            # Table size and row count
            cursor.execute(f"""
                SELECT
                    table_rows,
                    data_length,
                    index_length,
                    (data_length + index_length) AS total_size,
                    avg_row_length
                FROM information_schema.tables
                WHERE table_schema = %s AND table_name = %s
            """, (database, table))

            stats['size'] = cursor.fetchone()

            # Index statistics
            cursor.execute(f"""
                SELECT
                    index_name,
                    cardinality,
                    index_type,
                    column_name
                FROM information_schema.statistics
                WHERE table_schema = %s AND table_name = %s
                ORDER BY index_name, seq_in_index
            """, (database, table))

            stats['indexes'] = cursor.fetchall()

            # Column statistics
            cursor.execute(f"""
                SELECT
                    column_name,
                    data_type,
                    is_nullable,
                    column_key,
                    column_default,
                    character_maximum_length
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                ORDER BY ordinal_position
            """, (database, table))

            stats['columns'] = cursor.fetchall()

            cursor.close()
            conn.close()

        except Exception as e:
            stats['error'] = str(e)

        return stats

    def generate_performance_report(self, database):
        """Generate comprehensive performance report for a database."""
        report = {
            'database': database,
            'timestamp': datetime.now().isoformat(),
            'tables': {},
            'recommendations': []
        }

        try:
            conn = mysql.connector.connect(**self.connection_params, database=database)
            cursor = conn.cursor(dictionary=True)

            # Get all tables
            cursor.execute("SHOW TABLES")
            tables = [list(row.values())[0] for row in cursor.fetchall()]

            for table in tables:
                report['tables'][table] = self.analyze_table_stats(database, table)

                # Generate recommendations
                table_stats = report['tables'][table]
                if 'size' in table_stats and table_stats['size']:
                    # Check for missing indexes
                    if not table_stats.get('indexes'):
                        report['recommendations'].append(
                            f"Table '{table}' has no indexes. Consider adding indexes on frequently queried columns."
                        )

                    # Check for large tables without partitioning
                    if table_stats['size']['table_rows'] > 1000000:
                        report['recommendations'].append(
                            f"Table '{table}' has {table_stats['size']['table_rows']} rows. Consider partitioning for better performance."
                        )

            cursor.close()
            conn.close()

        except Exception as e:
            report['error'] = str(e)

        return report

    def visualize_metrics(self, metrics_data):
        """Create performance visualization charts."""
        charts = {}

        # Table size comparison chart
        if 'tables' in metrics_data:
            fig, ax = plt.subplots(figsize=(10, 6))

            table_names = []
            data_sizes = []
            index_sizes = []

            for table, stats in metrics_data['tables'].items():
                if 'size' in stats and stats['size']:
                    table_names.append(table)
                    data_sizes.append(stats['size']['data_length'] / 1024 / 1024)  # Convert to MB
                    index_sizes.append(stats['size']['index_length'] / 1024 / 1024)

            x = range(len(table_names))
            width = 0.35

            ax.bar([i - width/2 for i in x], data_sizes, width, label='Data Size (MB)', color='skyblue')
            ax.bar([i + width/2 for i in x], index_sizes, width, label='Index Size (MB)', color='orange')

            ax.set_xlabel('Tables')
            ax.set_ylabel('Size (MB)')
            ax.set_title('Table Size Distribution')
            ax.set_xticks(x)
            ax.set_xticklabels(table_names, rotation=45, ha='right')
            ax.legend()

            plt.tight_layout()

            # Convert to base64
            buffer = BytesIO()
            plt.savefig(buffer, format='png')
            buffer.seek(0)
            charts['table_sizes'] = base64.b64encode(buffer.getvalue()).decode()
            plt.close()

        return charts

class QueryOptimizer:
    """Analyze and optimize SQL queries."""

    def __init__(self, connection_params):
        self.connection_params = connection_params

    def analyze_query(self, query, database=None):
        """Analyze query execution plan and suggest optimizations."""
        analysis = {
            'query': query,
            'execution_plan': [],
            'suggestions': [],
            'estimated_cost': None
        }

        try:
            conn = mysql.connector.connect(**self.connection_params, database=database)
            cursor = conn.cursor(dictionary=True)

            # Get execution plan
            cursor.execute(f"EXPLAIN {query}")
            execution_plan = cursor.fetchall()
            analysis['execution_plan'] = execution_plan

            # Analyze plan for issues
            for step in execution_plan:
                # Check for full table scans
                if step.get('type') == 'ALL':
                    analysis['suggestions'].append(
                        f"Full table scan detected on table '{step.get('table')}'. Consider adding an index."
                    )

                # Check for filesort
                if 'Using filesort' in step.get('Extra', ''):
                    analysis['suggestions'].append(
                        f"Filesort detected on table '{step.get('table')}'. Consider adding an index on ORDER BY columns."
                    )

                # Check for temporary tables
                if 'Using temporary' in step.get('Extra', ''):
                    analysis['suggestions'].append(
                        f"Temporary table usage detected. Consider optimizing GROUP BY or DISTINCT operations."
                    )

                # Check for low key efficiency
                if step.get('key') and step.get('rows', 0) > 1000:
                    analysis['suggestions'].append(
                        f"Index '{step.get('key')}' on table '{step.get('table')}' may not be selective enough."
                    )

            # Get query cost estimate (MySQL 8.0+)
            try:
                cursor.execute(f"EXPLAIN FORMAT=JSON {query}")
                json_plan = cursor.fetchone()
                if json_plan:
                    import json
                    plan_data = json.loads(json_plan['EXPLAIN'])
                    if 'query_block' in plan_data and 'cost_info' in plan_data['query_block']:
                        analysis['estimated_cost'] = plan_data['query_block']['cost_info'].get('query_cost')
            except:
                pass

            cursor.close()
            conn.close()

        except Exception as e:
            analysis['error'] = str(e)

        return analysis

    def suggest_indexes(self, query, database=None):
        """Suggest indexes based on query patterns."""
        suggestions = []

        # Parse query to find WHERE, JOIN, and ORDER BY clauses
        import re

        query_upper = query.upper()

        # Find WHERE conditions
        where_match = re.search(r'WHERE\s+(.*?)(?:GROUP BY|ORDER BY|LIMIT|$)', query_upper, re.DOTALL)
        if where_match:
            where_clause = where_match.group(1)
            # Extract column names
            columns = re.findall(r'(\w+)\s*[=<>]', where_clause)
            for col in columns:
                suggestions.append(f"Consider index on column: {col}")

        # Find JOIN conditions
        join_matches = re.finditer(r'JOIN\s+\w+\s+ON\s+(.*?)(?:JOIN|WHERE|GROUP BY|ORDER BY|$)', query_upper, re.DOTALL)
        for match in join_matches:
            join_condition = match.group(1)
            columns = re.findall(r'(\w+\.\w+)', join_condition)
            for col in columns:
                suggestions.append(f"Consider index on join column: {col}")

        # Find ORDER BY columns
        order_match = re.search(r'ORDER BY\s+(.*?)(?:LIMIT|$)', query_upper)
        if order_match:
            order_clause = order_match.group(1)
            columns = re.findall(r'(\w+)', order_clause)
            for col in columns:
                suggestions.append(f"Consider index on sort column: {col}")

        return list(set(suggestions))  # Remove duplicates

class DataExporter:
    """Export database schemas and data in various formats."""

    @staticmethod
    def export_to_sql(database, tables=None, include_data=False, connection_params=None):
        """Export database schema (and optionally data) to SQL format."""
        output = []
        output.append(f"-- MySQL Database Export")
        output.append(f"-- Database: {database}")
        output.append(f"-- Generated: {datetime.now().isoformat()}")
        output.append("")

        try:
            conn = mysql.connector.connect(**connection_params, database=database)
            cursor = conn.cursor()

            # Get tables list
            if not tables:
                cursor.execute("SHOW TABLES")
                tables = [row[0] for row in cursor.fetchall()]

            for table in tables:
                output.append(f"-- Table: {table}")
                output.append(f"DROP TABLE IF EXISTS `{table}`;")

                # Get create table statement
                cursor.execute(f"SHOW CREATE TABLE `{table}`")
                create_stmt = cursor.fetchone()[1]
                output.append(create_stmt + ";")
                output.append("")

                # Export data if requested
                if include_data:
                    cursor.execute(f"SELECT * FROM `{table}`")
                    rows = cursor.fetchall()

                    if rows:
                        output.append(f"-- Data for table `{table}`")
                        columns = [desc[0] for desc in cursor.description]

                        for row in rows:
                            values = []
                            for val in row:
                                if val is None:
                                    values.append("NULL")
                                elif isinstance(val, (int, float)):
                                    values.append(str(val))
                                else:
                                    values.append(f"'{str(val).replace('\'', '\\\'')}'")

                            output.append(f"INSERT INTO `{table}` ({', '.join(columns)}) VALUES ({', '.join(values)});")

                        output.append("")

            cursor.close()
            conn.close()

        except Exception as e:
            output.append(f"-- Error: {str(e)}")

        return '\n'.join(output)

    @staticmethod
    def export_to_markdown(schema_analysis):
        """Export schema analysis to Markdown format."""
        output = []
        output.append("# Database Schema Documentation")
        output.append("")
        output.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        output.append("")

        for table_name, columns in schema_analysis.items():
            output.append(f"## Table: `{table_name}`")
            output.append("")
            output.append("| Column | Type | Nullable | Key |")
            output.append("|--------|------|----------|-----|")

            for col in columns:
                key_type = ""
                if col['primary']:
                    key_type = "PRIMARY"
                elif col['unique']:
                    key_type = "UNIQUE"

                nullable = "YES" if col['nullable'] else "NO"
                output.append(f"| {col['name']} | {col['type']} | {nullable} | {key_type} |")

            output.append("")

        return '\n'.join(output)

    @staticmethod
    def export_to_json(schema_analysis):
        """Export schema analysis to JSON format."""
        export_data = {
            'timestamp': datetime.now().isoformat(),
            'tables': {}
        }

        for table_name, columns in schema_analysis.items():
            export_data['tables'][table_name] = {
                'columns': columns
            }

        return json.dumps(export_data, indent=2)