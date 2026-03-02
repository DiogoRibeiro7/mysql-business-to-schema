#!/usr/bin/env python3
"""Generator Refactoring Helper Script.

Helps automate the conversion of existing generators to use BaseGenerator
"""

import os
import re
from typing import List, Dict, Any
from pathlib import Path


class GeneratorRefactorer:
    """Helper class to refactor existing generators to use BaseGenerator."""

    def __init__(self, base_dir: str = "."):
        """Initialize the instance."""
        self.base_dir = Path(base_dir)
        self.base_generator_import = """import sys
import os
from generators.base_generator import BaseGenerator
"""

    def find_generators(self) -> List[Path]:
        """Find all generator.py files that need refactoring."""
        generators = []
        exclude_dirs = ["__pycache__", ".git", "base_generator.py"]

        for root, dirs, files in os.walk(self.base_dir):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if d not in exclude_dirs]

            for file in files:
                if file == "generator.py":
                    try:
                        with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                            content = f.read()
                            if "BaseGenerator" not in content:
                                generators.append(Path(root) / file)
                    except Exception as e:
                        print(
                            f"Warning: Could not read {os.path.join(root, file)}: {e}"
                        )
                        continue

        return generators

    def analyze_generator(self, file_path: Path) -> Dict:
        """Analyze a generator file to understand its structure."""
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        analysis: Dict[str, Any] = {
            "file_path": file_path,
            "class_name": None,
            "has_config": "config" in content.lower(),
            "has_faker": "faker" in content.lower(),
            "tables": [],
            "uses_sql_generation": "INSERT INTO" in content,
            "uses_csv": ".csv" in content,
            "uses_json": "json.dump" in content,
        }

        # Find class name
        class_match = re.search(r"class\s+(\w+Generator)", content)
        if class_match:
            analysis["class_name"] = class_match.group(1)

        # Find table names from INSERT statements
        table_matches = re.findall(r"INSERT\s+INTO\s+(\w+)", content, re.IGNORECASE)
        analysis["tables"] = list(set(table_matches))

        return analysis

    def create_refactoring_template(self, analysis: Dict) -> str:
        """Create a template for refactoring based on the analysis."""
        class_name = analysis["class_name"] or "DataGenerator"

        template = f'''#!/usr/bin/env python3
"""
{class_name} - Refactored with BaseGenerator
Auto-generated refactoring template
"""

{self.base_generator_import}

import random
import json
import yaml
import argparse
from datetime import datetime, timedelta, date
from typing import List, Dict, Any, Tuple

from faker import Faker


class {class_name}(BaseGenerator):
    """Refactored {class_name} using BaseGenerator infrastructure"""

    def __init__(self, config_path: str = 'config.yaml', **db_params):
        """Initialize the generator with configuration and database connection"""
        # Initialize base class with database connection parameters
        super().__init__(**db_params)

        # Load configuration
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                self.config = yaml.safe_load(f)
        else:
            self.config = self.get_default_config()

        # Initialize data containers
        self.init_data_containers()

    def get_default_config(self) -> dict:
        """Return default configuration"""
        return {{
            'scale': {{
                'small': {{'records': 100}},
                'medium': {{'records': 1000}},
                'large': {{'records': 10000}}
            }}
        }}

    def init_data_containers(self):
        """Initialize data storage containers"""
        # TODO: Add data containers for each table
'''

        # Add placeholders for each table found
        for table in analysis["tables"]:
            template += f"        self.{table} = []\n"

        template += '''
    def generate_data(self, scale: str = 'small'):
        """Generate all data based on scale"""
        scale_config = self.config['scale'][scale]

        print(f"\\nGenerating {scale} scale data...")
        print("=" * 50)

        # TODO: Implement data generation for each table
        # Example:
        # self.generate_table1(scale_config['records'])
        # self.generate_table2(scale_config['records'])

        return self.get_all_data()

    def get_all_data(self) -> Dict:
        """Return all generated data"""
        return {
'''

        for table in analysis["tables"]:
            template += f"            '{table}': self.{table},\n"

        template += '''        }

    def insert_data_to_database(self):
        """Insert generated data into database using bulk operations"""
        try:
            # Connect to database
            self.connect()

            # TODO: Implement bulk inserts for each table
            # Example:
            # if self.table1:
            #     data = [tuple(record.values()) for record in self.table1]
            #     self.bulk_insert('table1', data, list(self.table1[0].keys()))

            # Print statistics
            self.print_statistics()

        except Exception as e:
            print(f"Error inserting data: {e}")
            raise
        finally:
            self.disconnect()


def main():
    parser = argparse.ArgumentParser(description='Generate sample data')
    parser.add_argument('--scale', choices=['small', 'medium', 'large'], default='small')
    parser.add_argument('--format', choices=['database', 'json', 'sql'], default='database')
    parser.add_argument('--config', default='config.yaml')

    # Database connection parameters
    parser.add_argument('--host', default='localhost')
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--user', default='root')
    parser.add_argument('--password', default='password')
    parser.add_argument('--database', required=True)

    args = parser.parse_args()

    generator = {class_name}(
        config_path=args.config,
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database
    )

    # Generate data
    data = generator.generate_data(args.scale)

    if args.format == 'database':
        generator.insert_data_to_database()
    elif args.format == 'json':
        with open('output.json', 'w') as f:
            json.dump(data, f, indent=2, default=str)

    print("\\n[DONE] Data generation complete!")


if __name__ == '__main__':
    main()
'''

        return template

    def create_migration_guide(self, analyses: List[Dict]) -> str:
        """Create a migration guide document."""
        guide = """# Generator Refactoring Guide

## Overview
This guide helps migrate existing generators to use the BaseGenerator class.

## Generators Found and Analysis:

"""
        for analysis in analyses:
            guide += f"""
### {analysis['file_path'].parent.name} Generator
- **File**: `{analysis['file_path']}`
- **Class**: {analysis['class_name']}
- **Tables**: {', '.join(analysis['tables'])}
- **Uses Config**: {analysis['has_config']}
- **Uses Faker**: {analysis['has_faker']}
- **Output Formats**: {'SQL' if analysis['uses_sql_generation'] else ''} {'CSV' if analysis['uses_csv'] else ''} {'JSON' if analysis['uses_json'] else ''}

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling

"""

        guide += """
## Common Refactoring Patterns

### 1. Class Declaration
```python
# OLD
class SomeGenerator:
    def __init__(self, config_path='config.yaml'):
        ...

# NEW
class SomeGenerator(BaseGenerator):
    def __init__(self, config_path='config.yaml', **db_params):
        super().__init__(**db_params)
        ...
```

### 2. Data Insertion
```python
# OLD
sql = f"INSERT INTO table (col1, col2) VALUES ({val1}, {val2})"
sql_statements.append(sql)

# NEW
data = [(val1, val2), ...]
self.bulk_insert('table', data, ['col1', 'col2'])
```

### 3. Database Connection
```python
# OLD
# Manual connection handling

# NEW
self.connect()  # From BaseGenerator
# ... do work ...
self.disconnect()
```

## Benefits of Migration
- Consistent database connection handling
- Efficient bulk inserts with batching
- Built-in error handling and rollback
- Connection pooling support
- Standardized logging
- Performance metrics
"""

        return guide

    def refactor_all(self, output_dir: str = "refactored"):
        """Run method to analyze and create refactoring templates for all generators."""
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)

        generators = self.find_generators()
        print(f"Found {len(generators)} generators to refactor:")

        analyses = []
        for gen_path in generators:
            print(f"\nAnalyzing: {gen_path}")
            analysis = self.analyze_generator(gen_path)
            analyses.append(analysis)

            # Create refactoring template
            template = self.create_refactoring_template(analysis)

            # Save template
            parent_name = gen_path.parent.name
            template_path = output_path / f"{parent_name}_generator_refactored.py"
            with open(template_path, "w", encoding="utf-8") as f:
                f.write(template)

            print(f"  [OK] Created template: {template_path}")
            print(f"  - Class: {analysis['class_name']}")
            print(f"  - Tables: {', '.join(analysis['tables'][:5])}")

        # Create migration guide
        guide = self.create_migration_guide(analyses)
        guide_path = output_path / "REFACTORING_GUIDE.md"
        with open(guide_path, "w", encoding="utf-8") as f:
            f.write(guide)

        print(f"\n[SUCCESS] Refactoring templates created in {output_path}/")
        print(f"[GUIDE] Migration guide created: {guide_path}")

        return analyses


def main():
    """Run the refactoring helper."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Refactor generators to use BaseGenerator"
    )
    parser.add_argument(
        "--analyze-only",
        action="store_true",
        help="Only analyze generators without creating templates",
    )
    parser.add_argument(
        "--output",
        default="refactored",
        help="Output directory for refactored templates",
    )
    parser.add_argument("--generator", help="Specific generator to refactor")

    args = parser.parse_args()

    refactorer = GeneratorRefactorer()

    if args.analyze_only:
        generators = refactorer.find_generators()
        print(f"Found {len(generators)} generators that need refactoring:\n")
        for gen in generators:
            analysis = refactorer.analyze_generator(gen)
            print(f"- {gen.parent.name}: {analysis['class_name']}")
            print(f"  Tables: {', '.join(analysis['tables'][:5])}")
            if len(analysis["tables"]) > 5:
                print(f"  ... and {len(analysis['tables']) - 5} more tables")
    else:
        analyses = refactorer.refactor_all(args.output)

        # Print summary
        print("\n" + "=" * 60)
        print("REFACTORING SUMMARY")
        print("=" * 60)
        print(f"Total generators analyzed: {len(analyses)}")

        total_tables = sum(len(a["tables"]) for a in analyses)
        print(f"Total tables found: {total_tables}")

        print("\nNext steps:")
        print("1. Review the generated templates in the 'refactored' directory")
        print("2. Copy the logic from original generators to the templates")
        print("3. Update data generation methods to use bulk_insert")
        print("4. Test with actual database connections")
        print("5. Replace original generators with refactored versions")


if __name__ == "__main__":
    main()
