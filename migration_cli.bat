@echo off
REM Migration CLI Wrapper Script for Windows

REM Get the directory of this script
set DIR=%~dp0

REM Run the migration CLI with Python
python "%DIR%migration_system\migration_cli.py" %*