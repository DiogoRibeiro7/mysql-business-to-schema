#!/usr/bin/env python3
"""
MySQL Examples Web Interface

A Flask-based web application for browsing and exploring
all database examples in the mysql-business-to-schema project.
"""

import os
import json
import yaml
from pathlib import Path
from datetime import datetime
from flask import Flask, render_template, send_file, jsonify, request, session, make_response
from flask_cors import CORS
import markdown
from pygments import highlight
from pygments.lexers import SqlLexer, PythonLexer, YamlLexer
from pygments.formatters import HtmlFormatter

# Import analytics module
from analytics import (
    SQLExecutor, ERDiagramGenerator, PerformanceAnalyzer,
    QueryOptimizer, DataExporter
)

app = Flask(__name__)
CORS(app)

# Configuration
PROJECT_ROOT = Path(__file__).parent.parent
EXAMPLES_DIR = PROJECT_ROOT
GENERATORS_DIR = PROJECT_ROOT / 'generators'

# Cache for loaded content
cache = {}

class ExampleLoader:
    """Load and parse example data."""

    @staticmethod
    def get_all_examples():
        """Get list of all examples with metadata."""
        examples = []

        for example_dir in sorted(EXAMPLES_DIR.glob('example_*')):
            if not example_dir.is_dir():
                continue

            example_id = example_dir.name.split('_')[1]
            example_name = '_'.join(example_dir.name.split('_')[2:])

            # Read README for description
            readme_path = example_dir / 'README.md'
            description = ""
            category = ""
            tables_count = 0

            if readme_path.exists():
                with open(readme_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')

                    # Extract description from first paragraph after title
                    for i, line in enumerate(lines):
                        if line.startswith('## Business Context'):
                            if i + 2 < len(lines):
                                description = lines[i + 2]
                            break

                    # Determine category
                    if 'iot' in example_name.lower() or 'sensor' in content.lower():
                        category = 'IoT & Time Series'
                    elif 'fintech' in example_name.lower() or 'banking' in content.lower():
                        category = 'Financial'
                    elif 'social' in example_name.lower():
                        category = 'Social'
                    elif 'real_estate' in example_name.lower():
                        category = 'Real Estate'
                    elif 'ecommerce' in example_name.lower():
                        category = 'E-Commerce'
                    elif 'clinic' in example_name.lower() or 'healthcare' in example_name.lower():
                        category = 'Healthcare'
                    elif 'event' in example_name.lower() or 'ticketing' in example_name.lower():
                        category = 'Entertainment'
                    elif 'streaming' in example_name.lower() or 'ml' in example_name.lower():
                        category = 'Analytics & ML'
                    else:
                        category = 'Other'

            # Count tables from schema files
            schema_dir = example_dir / 'schema'
            if schema_dir.exists():
                for sql_file in schema_dir.glob('01_tables.sql'):
                    if sql_file.exists():
                        with open(sql_file, 'r', encoding='utf-8') as f:
                            content = f.read()
                            tables_count = content.lower().count('create table')

            # Check for generator
            generator_name = example_name
            has_generator = (GENERATORS_DIR / generator_name).exists()

            examples.append({
                'id': example_id,
                'name': example_name.replace('_', ' ').title(),
                'path': example_dir.name,
                'description': description[:200] + '...' if len(description) > 200 else description,
                'category': category,
                'tables_count': tables_count,
                'has_generator': has_generator,
                'readme_exists': readme_path.exists(),
                'schema_exists': (example_dir / 'schema').exists(),
                'queries_exist': (example_dir / 'queries').exists()
            })

        return sorted(examples, key=lambda x: x['id'])

    @staticmethod
    def get_example_details(example_path):
        """Get detailed information about an example."""
        example_dir = EXAMPLES_DIR / example_path

        if not example_dir.exists():
            return None

        details = {
            'path': example_path,
            'name': '_'.join(example_path.split('_')[2:]).replace('_', ' ').title(),
            'files': {},
            'readme_html': '',
            'stats': {
                'tables': 0,
                'queries': 0,
                'indexes': 0,
                'procedures': 0
            }
        }

        # Load README
        readme_path = example_dir / 'README.md'
        if readme_path.exists():
            with open(readme_path, 'r', encoding='utf-8') as f:
                md_content = f.read()
                details['readme_html'] = markdown.markdown(
                    md_content,
                    extensions=['fenced_code', 'tables', 'codehilite']
                )

        # Load schema files
        schema_dir = example_dir / 'schema'
        if schema_dir.exists():
            details['files']['schema'] = []
            for sql_file in sorted(schema_dir.glob('*.sql')):
                with open(sql_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                    # Count elements
                    details['stats']['tables'] += content.lower().count('create table')
                    details['stats']['indexes'] += content.lower().count('create index')
                    details['stats']['indexes'] += content.lower().count('create unique index')
                    details['stats']['procedures'] += content.lower().count('create procedure')
                    details['stats']['procedures'] += content.lower().count('create function')

                    # Syntax highlight SQL
                    highlighted = highlight(content, SqlLexer(), HtmlFormatter())

                    details['files']['schema'].append({
                        'name': sql_file.name,
                        'content': content,
                        'highlighted': highlighted,
                        'lines': len(content.split('\n'))
                    })

        # Load query files
        queries_dir = example_dir / 'queries'
        if queries_dir.exists():
            details['files']['queries'] = []
            for sql_file in sorted(queries_dir.glob('*.sql')):
                with open(sql_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                    # Count queries (rough estimate)
                    details['stats']['queries'] += content.upper().count('SELECT')

                    # Syntax highlight SQL
                    highlighted = highlight(content, SqlLexer(), HtmlFormatter())

                    details['files']['queries'].append({
                        'name': sql_file.name,
                        'content': content,
                        'highlighted': highlighted,
                        'lines': len(content.split('\n'))
                    })

        # Check for generator
        generator_name = '_'.join(example_path.split('_')[2:])
        generator_dir = GENERATORS_DIR / generator_name

        if generator_dir.exists():
            details['generator'] = {
                'exists': True,
                'config': None,
                'script': None
            }

            # Load generator config
            config_path = generator_dir / 'config.yaml'
            if config_path.exists():
                with open(config_path, 'r', encoding='utf-8') as f:
                    config_content = f.read()
                    details['generator']['config'] = {
                        'content': config_content,
                        'highlighted': highlight(config_content, YamlLexer(), HtmlFormatter()),
                        'parsed': yaml.safe_load(config_content)
                    }

            # Load generator script
            script_path = generator_dir / 'generate.py'
            if script_path.exists():
                with open(script_path, 'r', encoding='utf-8') as f:
                    script_content = f.read()
                    # Only show first 100 lines for preview
                    preview_lines = '\n'.join(script_content.split('\n')[:100])
                    details['generator']['script'] = {
                        'preview': preview_lines,
                        'highlighted': highlight(preview_lines + '\n# ... (truncated)', PythonLexer(), HtmlFormatter()),
                        'total_lines': len(script_content.split('\n'))
                    }

        return details

    @staticmethod
    def search_examples(query):
        """Search across all examples."""
        results = []
        query_lower = query.lower()

        for example_dir in EXAMPLES_DIR.glob('example_*'):
            if not example_dir.is_dir():
                continue

            matches = []

            # Search in README
            readme_path = example_dir / 'README.md'
            if readme_path.exists():
                with open(readme_path, 'r', encoding='utf-8') as f:
                    content = f.read().lower()
                    if query_lower in content:
                        # Find context around match
                        idx = content.index(query_lower)
                        start = max(0, idx - 100)
                        end = min(len(content), idx + 100)
                        context = content[start:end]
                        matches.append({
                            'file': 'README.md',
                            'context': '...' + context + '...'
                        })

            # Search in SQL files
            for sql_dir in ['schema', 'queries']:
                sql_path = example_dir / sql_dir
                if sql_path.exists():
                    for sql_file in sql_path.glob('*.sql'):
                        with open(sql_file, 'r', encoding='utf-8') as f:
                            content = f.read().lower()
                            if query_lower in content:
                                idx = content.index(query_lower)
                                start = max(0, idx - 100)
                                end = min(len(content), idx + 100)
                                context = content[start:end]
                                matches.append({
                                    'file': f'{sql_dir}/{sql_file.name}',
                                    'context': '...' + context + '...'
                                })

            if matches:
                results.append({
                    'example': example_dir.name,
                    'name': '_'.join(example_dir.name.split('_')[2:]).replace('_', ' ').title(),
                    'matches': matches[:3]  # Limit to 3 matches per example
                })

        return results

# Routes
@app.route('/')
def index():
    """Home page with all examples."""
    examples = ExampleLoader.get_all_examples()

    # Group by category
    categories = {}
    for example in examples:
        category = example['category']
        if category not in categories:
            categories[category] = []
        categories[category].append(example)

    # Calculate statistics
    stats = {
        'total_examples': len(examples),
        'total_tables': sum(e['tables_count'] for e in examples),
        'with_generators': sum(1 for e in examples if e['has_generator']),
        'categories': len(categories)
    }

    return render_template('index.html',
                         categories=categories,
                         stats=stats,
                         last_updated=datetime.now().strftime('%Y-%m-%d'))

@app.route('/example/<path:example_path>')
def example_detail(example_path):
    """View details of a specific example."""
    details = ExampleLoader.get_example_details(example_path)

    if not details:
        return "Example not found", 404

    return render_template('example.html', example=details)

@app.route('/compare')
def compare_examples():
    """Compare multiple examples side by side."""
    examples = ExampleLoader.get_all_examples()

    # Get selected examples from query params
    selected = request.args.getlist('examples[]')

    if not selected:
        # Default to first 3 examples
        selected = [e['path'] for e in examples[:3]]

    comparison_data = []
    for example_path in selected:
        details = ExampleLoader.get_example_details(example_path)
        if details:
            comparison_data.append(details)

    return render_template('compare.html',
                         examples=examples,
                         comparison=comparison_data,
                         selected=selected)

@app.route('/search')
def search():
    """Search across all examples."""
    query = request.args.get('q', '')

    if not query:
        return jsonify({'results': []})

    results = ExampleLoader.search_examples(query)

    return render_template('search.html',
                         query=query,
                         results=results,
                         count=len(results))

@app.route('/download/<path:example_path>/<file_type>')
def download_file(example_path, file_type):
    """Download schema or query files."""
    example_dir = EXAMPLES_DIR / example_path

    if file_type == 'schema':
        file_path = example_dir / 'schema' / '01_tables.sql'
    elif file_type == 'all':
        # TODO: Create zip file with all files
        pass
    else:
        return "Invalid file type", 400

    if file_path.exists():
        return send_file(file_path, as_attachment=True)

    return "File not found", 404

@app.route('/api/stats')
def api_stats():
    """API endpoint for statistics."""
    examples = ExampleLoader.get_all_examples()

    stats = {
        'total_examples': len(examples),
        'total_tables': sum(e['tables_count'] for e in examples),
        'with_generators': sum(1 for e in examples if e['has_generator']),
        'categories': {}
    }

    for example in examples:
        category = example['category']
        if category not in stats['categories']:
            stats['categories'][category] = 0
        stats['categories'][category] += 1

    return jsonify(stats)

@app.route('/tools')
def tools():
    """View available analysis tools."""
    tools_list = [
        {
            'name': 'Query Performance Analyzer',
            'file': 'query_analyzer.py',
            'description': 'Analyzes query performance using EXPLAIN plans and execution timing.',
            'features': ['EXPLAIN analysis', 'Execution benchmarks', 'Index recommendations', 'Cross-example comparison']
        },
        {
            'name': 'Test Runner',
            'file': 'test_runner.py',
            'description': 'Comprehensive testing framework for all database examples.',
            'features': ['Schema validation', 'Query testing', 'Generator verification', 'CI/CD integration']
        },
        {
            'name': 'Schema Validator',
            'file': 'schema_validator.py',
            'description': 'Validates schemas against best practices and naming conventions.',
            'features': ['Naming conventions', 'Data type consistency', 'Normalization checks', 'Anti-pattern detection']
        }
    ]

    return render_template('tools.html', tools=tools_list)

@app.route('/documentation')
def documentation():
    """View project documentation."""
    docs = {
        'getting_started': {
            'title': 'Getting Started',
            'content': '''
            ## Installation

            1. Clone the repository
            2. Install MySQL 8.0+
            3. Run docker-compose for quick setup
            4. Load examples using provided scripts

            ## Quick Start

            ```bash
            # Start MySQL
            docker-compose up -d

            # Load an example
            cd example_01_clinic
            mysql -u root < schema/00_create_database.sql
            ```
            '''
        },
        'learning_path': {
            'title': 'Learning Path',
            'content': '''
            ## Recommended Learning Path

            ### Beginner
            1. Start with Clinic (basic CRUD)
            2. Move to E-commerce (transactions)

            ### Intermediate
            3. Explore IoT examples (time series)
            4. Study Social Media (graph patterns)

            ### Advanced
            5. Analyze FinTech (financial integrity)
            6. Master Real Estate (spatial queries)
            '''
        }
    }

    # Convert markdown to HTML
    for key in docs:
        docs[key]['html'] = markdown.markdown(
            docs[key]['content'],
            extensions=['fenced_code', 'tables']
        )

    return render_template('documentation.html', docs=docs)

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    return render_template('500.html'), 500

# Analytics Routes
@app.route('/analytics')
def analytics_dashboard():
    """Main analytics dashboard."""
    return render_template('analytics.html')

@app.route('/analytics/query-executor')
def query_executor():
    """SQL query executor interface."""
    examples = ExampleLoader.get_all_examples()
    return render_template('query_executor.html', examples=examples)

@app.route('/api/execute-query', methods=['POST'])
def api_execute_query():
    """Execute SQL query API endpoint."""
    data = request.json
    query = data.get('query', '')
    database = data.get('database', '')

    # Security: Only allow in development mode
    if not app.debug:
        return jsonify({'error': 'Query execution disabled in production'}), 403

    # Initialize SQL executor with safe defaults
    executor = SQLExecutor(
        host='localhost',
        user='root',
        password='',  # Should be configured via environment variable
        database=database
    )

    result = executor.execute_query(query, database)
    return jsonify(result)

@app.route('/analytics/er-diagram/<path:example_path>')
def er_diagram(example_path):
    """Generate and display ER diagram for an example."""
    example_dir = EXAMPLES_DIR / example_path
    schema_dir = example_dir / 'schema'

    if not schema_dir.exists():
        return "Schema directory not found", 404

    generator = ERDiagramGenerator()
    svg_content, error = generator.generate_diagram(schema_dir, output_format='svg')

    if error:
        return f"Error generating diagram: {error}", 500

    return render_template('er_diagram.html',
                          example_path=example_path,
                          svg_content=svg_content)

@app.route('/api/er-diagram/<path:example_path>')
def api_er_diagram(example_path):
    """API endpoint to get ER diagram data."""
    example_dir = EXAMPLES_DIR / example_path
    schema_dir = example_dir / 'schema'

    if not schema_dir.exists():
        return jsonify({'error': 'Schema directory not found'}), 404

    generator = ERDiagramGenerator()

    # Analyze schema to get table relationships
    tables = {}
    relationships = []

    for sql_file in schema_dir.glob('*.sql'):
        file_tables, file_relationships = generator.analyze_schema(sql_file)
        tables.update(file_tables)
        relationships.extend(file_relationships)

    return jsonify({
        'tables': tables,
        'relationships': relationships
    })

@app.route('/analytics/performance/<path:example_path>')
def performance_analysis(example_path):
    """Performance analysis dashboard for an example."""
    # Get database name from example path
    database_name = f"{example_path}_db"

    # Initialize performance analyzer
    analyzer = PerformanceAnalyzer({
        'host': 'localhost',
        'user': 'root',
        'password': ''
    })

    # Generate performance report
    report = analyzer.generate_performance_report(database_name)

    # Generate visualization charts
    charts = analyzer.visualize_metrics(report)

    return render_template('performance.html',
                          example_path=example_path,
                          report=report,
                          charts=charts)

@app.route('/api/optimize-query', methods=['POST'])
def api_optimize_query():
    """Analyze and optimize SQL query."""
    data = request.json
    query = data.get('query', '')
    database = data.get('database', '')

    optimizer = QueryOptimizer({
        'host': 'localhost',
        'user': 'root',
        'password': ''
    })

    analysis = optimizer.analyze_query(query, database)
    index_suggestions = optimizer.suggest_indexes(query, database)

    analysis['index_suggestions'] = index_suggestions

    return jsonify(analysis)

@app.route('/export/<path:example_path>/<format>')
def export_schema(example_path, format):
    """Export schema in various formats."""
    example_dir = EXAMPLES_DIR / example_path
    schema_dir = example_dir / 'schema'

    if not schema_dir.exists():
        return "Schema directory not found", 404

    # Analyze schema
    generator = ERDiagramGenerator()
    tables = {}

    for sql_file in schema_dir.glob('*.sql'):
        file_tables, _ = generator.analyze_schema(sql_file)
        tables.update(file_tables)

    # Export based on format
    if format == 'json':
        output = DataExporter.export_to_json(tables)
        response = make_response(output)
        response.headers['Content-Type'] = 'application/json'
        response.headers['Content-Disposition'] = f'attachment; filename={example_path}_schema.json'
        return response

    elif format == 'markdown':
        output = DataExporter.export_to_markdown(tables)
        response = make_response(output)
        response.headers['Content-Type'] = 'text/markdown'
        response.headers['Content-Disposition'] = f'attachment; filename={example_path}_schema.md'
        return response

    elif format == 'sql':
        # Combine all SQL files
        output = f"-- Schema export for {example_path}\n"
        output += f"-- Generated: {datetime.now().isoformat()}\n\n"

        for sql_file in sorted(schema_dir.glob('*.sql')):
            with open(sql_file, 'r', encoding='utf-8') as f:
                output += f"-- File: {sql_file.name}\n"
                output += f"-- {'=' * 60}\n\n"
                output += f.read()
                output += "\n\n"

        response = make_response(output)
        response.headers['Content-Type'] = 'application/sql'
        response.headers['Content-Disposition'] = f'attachment; filename={example_path}_schema.sql'
        return response

    else:
        return "Invalid format", 400

# Session configuration for query history
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')

@app.route('/api/query-history', methods=['GET', 'POST'])
def query_history():
    """Manage query execution history."""
    if 'query_history' not in session:
        session['query_history'] = []

    if request.method == 'POST':
        query_data = request.json
        query_data['timestamp'] = datetime.now().isoformat()

        # Keep last 50 queries
        session['query_history'].insert(0, query_data)
        session['query_history'] = session['query_history'][:50]
        session.modified = True

        return jsonify({'success': True})

    return jsonify(session.get('query_history', []))

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)