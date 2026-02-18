# Contributing to MySQL Business to Schema

Thank you for your interest in contributing to MySQL Business to Schema! This project aims to be the definitive resource for learning and implementing production-grade MySQL database designs.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Style Guides](#style-guides)
- [Community](#community)

## 📜 Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and follow our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing viewpoints and experiences
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites

- Python 3.10+ installed
- MySQL 8.0+ or MariaDB 10.5+ installed
- Git for version control
- Docker (optional, for containerized development)

### First-Time Contributors

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mysql-business-to-schema.git
   cd mysql-business-to-schema
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/mysql-business-to-schema.git
   ```
4. Create a new branch for your contribution:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 🤝 How to Contribute

### Types of Contributions

#### 1. **New Database Examples** 🏗️
Create new industry-specific examples:
- Follow the structure in existing examples (01-15)
- Include complete schema, queries, and documentation
- Add a data generator if possible
- Document business context and use cases

#### 2. **Data Generators** 🎲
Improve or create data generators:
- Use Python with Faker library
- Support configurable output via YAML
- Generate realistic patterns
- Include temporal variations (daily/weekly/seasonal)

#### 3. **Documentation** 📚
Enhance learning materials:
- Fix typos and clarify explanations
- Add new guides and tutorials
- Create video walkthroughs
- Translate documentation

#### 4. **Query Examples** 📊
Add valuable queries:
- Business analytics queries
- Performance optimization examples
- Complex JOIN scenarios
- Window function demonstrations

#### 5. **Web Interface** 🌐
Improve the Flask application:
- Add new features
- Enhance UI/UX
- Fix bugs
- Add visualizations

#### 6. **Testing** 🧪
Strengthen test coverage:
- Add unit tests
- Create integration tests
- Add performance benchmarks
- Validate schemas and queries

#### 7. **Bug Fixes** 🐛
Fix issues:
- Check [GitHub Issues](https://github.com/OWNER/mysql-business-to-schema/issues)
- Fix broken queries
- Resolve generator issues
- Correct documentation errors

### Good First Issues

Look for issues labeled:
- `good first issue` - Perfect for newcomers
- `help wanted` - Community help needed
- `documentation` - Documentation improvements
- `bug` - Bug fixes

## 💻 Development Setup

### Local Development Environment

1. **Install Python dependencies:**
   ```bash
   poetry install --no-root --with dev,web,ml
   ```

2. **Setup MySQL:**
   ```bash
   # Windows
   ./scripts/run_mysql_local.ps1

   # Unix/Mac
   ./scripts/run_mysql_local.sh
   ```

3. **Run tests:**
   ```bash
   python -m pytest tests/
   ```

4. **Start web interface:**
   ```bash
   poetry run python web_interface/app.py
   ```

### Docker Development

1. **Start MySQL container:**
   ```bash
   docker-compose up -d
   ```

2. **Run generators:**
   ```bash
   docker-compose run generator python generate.py
   ```

## 📝 Contribution Guidelines

### For New Examples

Structure your example as:
```
example_XX_name/
├── README.md                    # Business context (use template below)
├── schema/
│   ├── 00_create_database.sql  # Database creation
│   ├── 01_tables.sql           # Table definitions
│   ├── 02_constraints.sql      # Foreign keys, checks
│   ├── 03_indexes.sql          # Performance indexes
│   └── 04_partitions.sql       # If applicable
├── queries/
│   ├── 01_basic.sql            # Simple queries
│   ├── 02_analytics.sql        # Analytics queries
│   └── 03_advanced.sql         # Complex queries
└── data/
    └── seed.sql                 # Sample data
```

#### README Template:
```markdown
# Example XX: [Industry Name]

## Business Context
[Describe the business scenario in 2-3 paragraphs]

## Key Features
- Feature 1
- Feature 2
- Feature 3

## Schema Statistics
- Tables: X
- Relationships: Y
- Indexes: Z

## Learning Objectives
1. Objective 1
2. Objective 2
3. Objective 3

## Technical Patterns
- Pattern 1 (e.g., Time-series partitioning)
- Pattern 2 (e.g., Multi-tenancy)

## Sample Queries
[List 3-5 interesting queries this example demonstrates]
```

### For Generators

Generator requirements:
```python
# generators/example_name/generator.py

class ExampleGenerator:
    def __init__(self, config_path='config.yaml'):
        """Initialize with configuration"""
        pass

    def generate_data(self, num_records=1000):
        """Generate realistic data"""
        pass

    def save_to_csv(self, output_dir='output'):
        """Save generated data to CSV files"""
        pass

# Include:
# - Temporal patterns (time-based variations)
# - Relationships between entities
# - Edge cases and anomalies
# - Configurable parameters
```

### For Queries

Query documentation format:
```sql
-- =====================================================
-- Query: [Descriptive Name]
-- Purpose: [What this query accomplishes]
-- Performance: [Expected performance characteristics]
-- Business Value: [Why this query matters]
-- =====================================================

-- The actual query here
SELECT ...

-- Expected results:
-- [Describe what the results should look like]
```

## 🔄 Pull Request Process

### Before Submitting

1. **Update from upstream:**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

2. **Run all tests:**
   ```bash
   # SQL validation
   python tools/schema_validator.py

   # Python tests
   python -m pytest

   # Linting
   black .
   flake8 .
   ```

3. **Update documentation:**
   - Update README if adding features
   - Add/update docstrings
   - Update EXAMPLES_OVERVIEW.md if adding examples

### PR Guidelines

1. **Title Format:**
   ```
   [Type] Brief description

   Types: feat, fix, docs, test, refactor, perf, ci, chore
   Example: [feat] Add inventory management example
   ```

2. **Description Template:**
   ```markdown
   ## Summary
   Brief description of changes

   ## Motivation
   Why these changes are needed

   ## Changes
   - Change 1
   - Change 2

   ## Testing
   How you tested these changes

   ## Checklist
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] Schema validates
   - [ ] Queries tested
   ```

3. **PR Size:**
   - Keep PRs focused and small
   - Large features should be split into multiple PRs
   - One PR = one feature/fix

## 🎨 Style Guides

### SQL Style Guide

```sql
-- Use uppercase for SQL keywords
SELECT
    u.user_id,
    u.username,
    COUNT(o.order_id) AS total_orders
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.user_id, u.username
HAVING COUNT(o.order_id) > 0
ORDER BY total_orders DESC;

-- Table naming: lowercase with underscores
CREATE TABLE user_profiles (
    -- Column naming: lowercase with underscores
    user_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes: idx_tablename_columns
CREATE INDEX idx_users_email ON users(email);

-- Foreign keys: fk_tablename_referencedtable
ALTER TABLE orders
ADD CONSTRAINT fk_orders_users
FOREIGN KEY (user_id) REFERENCES users(user_id);
```

### Python Style Guide

```python
# Follow PEP 8
# Use type hints where appropriate
from typing import List, Dict, Optional

def generate_users(count: int, seed: Optional[int] = None) -> List[Dict]:
    """
    Generate fake user data.

    Args:
        count: Number of users to generate
        seed: Random seed for reproducibility

    Returns:
        List of user dictionaries
    """
    # Implementation here
    pass

# Use descriptive variable names
# Prefer clarity over brevity
customer_order_total = calculate_order_total(customer_id)  # Good
tot = calc(id)  # Bad
```

### Commit Message Format

```
[type](scope): brief description

Detailed explanation of changes if needed.

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Testing
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `ci`: CI/CD changes
- `chore`: Maintenance

## 🌍 Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community discussion
- **Discord**: Real-time chat (link in README)
- **Email**: project-maintainer@example.com

### Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Given credit in documentation
- Eligible for special contributor badges

### Getting Help

If you need help:
1. Check existing documentation
2. Search closed issues
3. Ask in GitHub Discussions
4. Reach out on Discord
5. Email maintainers as last resort

## 📊 Contribution Impact Levels

### 🥉 Bronze (First PR Merged)
- Added to contributors list
- Welcome message from maintainers

### 🥈 Silver (3+ PRs Merged)
- Contributor badge
- Input on roadmap planning

### 🥇 Gold (10+ PRs Merged)
- Core contributor status
- Direct commit access consideration
- Feature planning involvement

### 💎 Diamond (Major Feature)
- Special recognition
- Co-authorship opportunity
- Speaking opportunity at events

## 🚫 What NOT to Do

Please avoid:
- Large, unfocused PRs
- Breaking changes without discussion
- Removing features without consensus
- Adding dependencies without justification
- Committing sensitive data or credentials
- Using copyrighted or licensed content

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Every contribution, no matter how small, helps make this project better. We appreciate your time and effort in improving MySQL Business to Schema!

---

*Last updated: February 2024*
