"""
Setup configuration for MySQL Business-to-Schema Python SDK
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="mysql-business-schema",
    version="1.0.0",
    author="MySQL Business Schema Team",
    author_email="admin@mysqlbusinessschema.com",
    description="Python SDK for MySQL Business-to-Schema system",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/mysql-business-to-schema",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "Topic :: Database",
        "Topic :: Software Development :: Libraries :: Python Modules",
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
        "requests>=2.28.0",
        "pydantic>=2.0.0",
        "mysql-connector-python>=8.0.0",
        "pandas>=1.5.0",
        "python-dotenv>=1.0.0",
        "click>=8.0.0",
        "rich>=13.0.0",
        "tenacity>=8.0.0",
        "websocket-client>=1.4.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "pytest-asyncio>=0.21.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.0.0",
            "sphinx>=5.0.0",
            "tox>=4.0.0",
        ],
        "async": [
            "aiohttp>=3.8.0",
            "aiomysql>=0.2.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "mysql-schema=mysql_business_schema.cli:main",
        ],
    },
    project_urls={
        "Bug Reports": "https://github.com/yourusername/mysql-business-to-schema/issues",
        "Documentation": "https://mysql-business-schema.readthedocs.io/",
        "Source": "https://github.com/yourusername/mysql-business-to-schema",
    },
)
