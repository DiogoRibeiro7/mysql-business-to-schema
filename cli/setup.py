"""Setup configuration for MySQL Business-to-Schema CLI."""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="mysql-schema-cli",
    version="1.0.0",
    author="MySQL Business Schema Team",
    author_email="admin@mysqlbusinessschema.com",
    description="Unified CLI for MySQL Business-to-Schema system",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/mysql-business-to-schema",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "Topic :: Database",
        "Topic :: Software Development :: Code Generators",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.8",
    install_requires=[
        "click>=8.1.0",
        "click-completion>=0.5.2",
        "rich>=13.0.0",
        "pyyaml>=6.0",
        "python-dotenv>=1.0.0",
        "requests>=2.28.0",
        "mysql-connector-python>=8.0.0",
        "tabulate>=0.9.0",
        "questionary>=2.0.0",
        "pygments>=2.14.0",
        "watchdog>=3.0.0",
        "jinja2>=3.1.0",
        "gitpython>=3.1.0",
        "docker>=6.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.0.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "mysql-schema=mysql_schema_cli.main:cli",
            "msc=mysql_schema_cli.main:cli",  # Short alias
        ],
    },
    package_data={
        "mysql_schema_cli": [
            "templates/**/*",
            "config/*.yaml",
        ],
    },
    project_urls={
        "Bug Reports": "https://github.com/yourusername/mysql-business-to-schema/issues",
        "Documentation": "https://mysql-business-schema.readthedocs.io/",
        "Source": "https://github.com/yourusername/mysql-business-to-schema",
    },
)
