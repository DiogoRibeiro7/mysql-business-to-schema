#!/usr/bin/env python3
"""
MySQL Business-to-Schema Performance Benchmarking Suite

This tool benchmarks database operations and generator performance across all examples.
"""

import os
import sys
import time
import json
import argparse
import subprocess
import statistics
import mysql.connector
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import psutil
import threading

class ColorOutput:
    """Color codes for terminal output"""
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

class BenchmarkResult:
    """Container for benchmark results"""
    def __init__(self, name: str):
        self.name = name
        self.start_time = None
        self.end_time = None
        self.duration = 0
        self.rows_generated = 0
        self.memory_peak = 0
        self.cpu_peak = 0
        self.queries_per_second = 0
        self.errors = []
        self.metadata = {}

    def to_dict(self) -> Dict:
        return {
            'name': self.name,
            'duration': self.duration,
            'rows_generated': self.rows_generated,
            'memory_peak_mb': self.memory_peak,
            'cpu_peak_percent': self.cpu_peak,
            'queries_per_second': self.queries_per_second,
            'errors': self.errors,
            'metadata': self.metadata
        }

class ResourceMonitor:
    """Monitor system resource usage during benchmarks"""
    def __init__(self):
        self.monitoring = False
        self.memory_samples = []
        self.cpu_samples = []
        self.monitor_thread = None

    def start(self):
        """Start monitoring resources"""
        self.monitoring = True
        self.memory_samples = []
        self.cpu_samples = []
        self.monitor_thread = threading.Thread(target=self._monitor)
        self.monitor_thread.start()

    def stop(self) -> Tuple[float, float]:
        """Stop monitoring and return peak values"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join()

        peak_memory = max(self.memory_samples) if self.memory_samples else 0
        peak_cpu = max(self.cpu_samples) if self.cpu_samples else 0
        return peak_memory, peak_cpu

    def _monitor(self):
        """Monitor loop running in separate thread"""
        process = psutil.Process()
        while self.monitoring:
            try:
                memory_mb = process.memory_info().rss / 1024 / 1024
                cpu_percent = process.cpu_percent()
                self.memory_samples.append(memory_mb)
                self.cpu_samples.append(cpu_percent)
                time.sleep(0.1)
            except:
                pass

class DatabaseBenchmark:
    """Benchmark database operations"""

    def __init__(self, config: Dict):
        self.config = config
        self.connection = None
        self.results = []

    def connect(self) -> bool:
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(
                host=self.config.get('host', 'localhost'),
                port=self.config.get('port', 3306),
                user=self.config.get('user', 'root'),
                password=self.config.get('password', ''),
                database=self.config.get('database', '')
            )
            return True
        except Exception as e:
            print(f"{ColorOutput.RED}Connection failed: {e}{ColorOutput.RESET}")
            return False

    def disconnect(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()

    def benchmark_inserts(self, table: str, count: int = 1000) -> BenchmarkResult:
        """Benchmark INSERT operations"""
        result = BenchmarkResult(f"INSERT_{table}")
        monitor = ResourceMonitor()

        try:
            cursor = self.connection.cursor()
            monitor.start()
            result.start_time = time.time()

            # Get table columns
            cursor.execute(f"DESCRIBE {table}")
            columns = cursor.fetchall()

            # Generate and execute INSERT statements
            for i in range(count):
                values = self._generate_values(columns)
                query = f"INSERT INTO {table} VALUES ({values})"
                cursor.execute(query)

            self.connection.commit()
            result.end_time = time.time()
            result.duration = result.end_time - result.start_time
            result.rows_generated = count
            result.queries_per_second = count / result.duration if result.duration > 0 else 0

            memory_peak, cpu_peak = monitor.stop()
            result.memory_peak = memory_peak
            result.cpu_peak = cpu_peak

        except Exception as e:
            result.errors.append(str(e))
            monitor.stop()
        finally:
            cursor.close()

        return result

    def benchmark_selects(self, table: str, count: int = 1000) -> BenchmarkResult:
        """Benchmark SELECT operations"""
        result = BenchmarkResult(f"SELECT_{table}")
        monitor = ResourceMonitor()

        try:
            cursor = self.connection.cursor()
            monitor.start()
            result.start_time = time.time()

            for i in range(count):
                cursor.execute(f"SELECT * FROM {table} LIMIT 1")
                cursor.fetchall()

            result.end_time = time.time()
            result.duration = result.end_time - result.start_time
            result.queries_per_second = count / result.duration if result.duration > 0 else 0

            memory_peak, cpu_peak = monitor.stop()
            result.memory_peak = memory_peak
            result.cpu_peak = cpu_peak

        except Exception as e:
            result.errors.append(str(e))
            monitor.stop()
        finally:
            cursor.close()

        return result

    def benchmark_joins(self, tables: List[str], count: int = 100) -> BenchmarkResult:
        """Benchmark JOIN operations"""
        result = BenchmarkResult(f"JOIN_{tables[0]}")
        monitor = ResourceMonitor()

        if len(tables) < 2:
            result.errors.append("Need at least 2 tables for JOIN benchmark")
            return result

        try:
            cursor = self.connection.cursor()
            monitor.start()
            result.start_time = time.time()

            # Simple JOIN query
            query = f"""
                SELECT COUNT(*)
                FROM {tables[0]} t1
                JOIN {tables[1]} t2 ON t1.id = t2.id
                LIMIT 100
            """

            for i in range(count):
                cursor.execute(query)
                cursor.fetchall()

            result.end_time = time.time()
            result.duration = result.end_time - result.start_time
            result.queries_per_second = count / result.duration if result.duration > 0 else 0

            memory_peak, cpu_peak = monitor.stop()
            result.memory_peak = memory_peak
            result.cpu_peak = cpu_peak

        except Exception as e:
            result.errors.append(str(e))
            monitor.stop()
        finally:
            cursor.close()

        return result

    def benchmark_aggregates(self, table: str, count: int = 100) -> BenchmarkResult:
        """Benchmark aggregate operations"""
        result = BenchmarkResult(f"AGGREGATE_{table}")
        monitor = ResourceMonitor()

        try:
            cursor = self.connection.cursor()
            monitor.start()
            result.start_time = time.time()

            queries = [
                f"SELECT COUNT(*) FROM {table}",
                f"SELECT AVG(id) FROM {table}",
                f"SELECT MAX(id) FROM {table}",
                f"SELECT MIN(id) FROM {table}",
            ]

            for i in range(count):
                for query in queries:
                    cursor.execute(query)
                    cursor.fetchall()

            result.end_time = time.time()
            result.duration = result.end_time - result.start_time
            result.queries_per_second = (count * len(queries)) / result.duration if result.duration > 0 else 0

            memory_peak, cpu_peak = monitor.stop()
            result.memory_peak = memory_peak
            result.cpu_peak = cpu_peak

        except Exception as e:
            result.errors.append(str(e))
            monitor.stop()
        finally:
            cursor.close()

        return result

    def _generate_values(self, columns: List) -> str:
        """Generate dummy values for INSERT"""
        values = []
        for col in columns:
            col_type = col[1].lower()
            if 'int' in col_type:
                values.append('1')
            elif 'varchar' in col_type or 'text' in col_type:
                values.append("'test'")
            elif 'decimal' in col_type or 'float' in col_type:
                values.append('1.0')
            elif 'date' in col_type:
                values.append("'2024-01-01'")
            elif 'time' in col_type:
                values.append("'2024-01-01 00:00:00'")
            else:
                values.append('NULL')
        return ','.join(values)

class GeneratorBenchmark:
    """Benchmark data generators"""

    def __init__(self, generator_path: str):
        self.generator_path = generator_path
        self.results = []

    def benchmark_generator(self, mode: str = 'test') -> BenchmarkResult:
        """Benchmark a single generator"""
        generator_name = Path(self.generator_path).parent.name
        result = BenchmarkResult(f"generator_{generator_name}")
        monitor = ResourceMonitor()

        try:
            env = os.environ.copy()
            env['GENERATOR_MODE'] = mode

            monitor.start()
            result.start_time = time.time()

            # Run generator
            process = subprocess.Popen(
                [sys.executable, 'generator.py'],
                cwd=self.generator_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env
            )

            stdout, stderr = process.communicate(timeout=300)  # 5 minute timeout

            result.end_time = time.time()
            result.duration = result.end_time - result.start_time

            # Parse output for row count
            output = stdout.decode('utf-8')
            for line in output.split('\n'):
                if 'Generated' in line and 'records' in line:
                    try:
                        parts = line.split()
                        for i, part in enumerate(parts):
                            if part.isdigit():
                                result.rows_generated += int(part)
                    except:
                        pass

            memory_peak, cpu_peak = monitor.stop()
            result.memory_peak = memory_peak
            result.cpu_peak = cpu_peak

            if process.returncode != 0:
                result.errors.append(f"Generator failed with code {process.returncode}")
                result.errors.append(stderr.decode('utf-8'))

        except subprocess.TimeoutExpired:
            result.errors.append("Generator timeout (5 minutes)")
            monitor.stop()
        except Exception as e:
            result.errors.append(str(e))
            monitor.stop()

        return result

class BenchmarkSuite:
    """Main benchmark orchestrator"""

    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.results = {}
        self.start_time = None
        self.end_time = None

    def run_all(self, parallel: bool = False, examples: List[str] = None):
        """Run benchmarks for all examples"""
        self.start_time = datetime.now()

        # Get list of examples
        if examples:
            example_dirs = [self.project_root / f"example_{ex}" if not ex.startswith('example_') else self.project_root / ex
                           for ex in examples]
        else:
            example_dirs = sorted([d for d in self.project_root.glob("example_*") if d.is_dir()])

        print(f"{ColorOutput.BOLD}MySQL Business-to-Schema Benchmark Suite{ColorOutput.RESET}")
        print(f"{'=' * 60}")
        print(f"Starting benchmarks for {len(example_dirs)} examples")
        print(f"Parallel execution: {parallel}")
        print(f"{'=' * 60}\n")

        if parallel:
            self._run_parallel(example_dirs)
        else:
            self._run_sequential(example_dirs)

        self.end_time = datetime.now()
        self._print_summary()
        self._save_results()

    def _run_sequential(self, example_dirs: List[Path]):
        """Run benchmarks sequentially"""
        for i, example_dir in enumerate(example_dirs, 1):
            example_name = example_dir.name
            print(f"{ColorOutput.CYAN}[{i}/{len(example_dirs)}] Benchmarking {example_name}{ColorOutput.RESET}")

            result = self._benchmark_example(example_dir)
            self.results[example_name] = result

            if result.get('errors'):
                print(f"  {ColorOutput.RED}[FAIL] {len(result['errors'])} errors{ColorOutput.RESET}")
            else:
                print(f"  {ColorOutput.GREEN}[OK] Duration: {result.get('total_duration', 0):.2f}s{ColorOutput.RESET}")

    def _run_parallel(self, example_dirs: List[Path]):
        """Run benchmarks in parallel"""
        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = {executor.submit(self._benchmark_example, d): d.name
                      for d in example_dirs}

            for future in as_completed(futures):
                example_name = futures[future]
                try:
                    result = future.result(timeout=600)  # 10 minute timeout
                    self.results[example_name] = result

                    if result.get('errors'):
                        print(f"{ColorOutput.RED}[FAIL] {example_name}{ColorOutput.RESET}")
                    else:
                        print(f"{ColorOutput.GREEN}[OK] {example_name} - {result.get('total_duration', 0):.2f}s{ColorOutput.RESET}")
                except Exception as e:
                    print(f"{ColorOutput.RED}[ERROR] {example_name}: {e}{ColorOutput.RESET}")
                    self.results[example_name] = {'errors': [str(e)]}

    def _benchmark_example(self, example_dir: Path) -> Dict:
        """Benchmark a single example"""
        results = {
            'example': example_dir.name,
            'timestamp': datetime.now().isoformat(),
            'generator': {},
            'database': {},
            'errors': []
        }

        # Find generator
        generator_name = example_dir.name.replace('example_', '').split('_', 1)[1] if '_' in example_dir.name else example_dir.name
        generator_path = self.project_root / 'generators' / generator_name

        # Benchmark generator if it exists
        if generator_path.exists() and (generator_path / 'generator.py').exists():
            bench = GeneratorBenchmark(str(generator_path))
            gen_result = bench.benchmark_generator('test')
            results['generator'] = gen_result.to_dict()
        else:
            results['errors'].append(f"Generator not found: {generator_path}")

        # Benchmark database operations if docker-compose exists
        docker_compose = example_dir / 'docker-compose.yml'
        if docker_compose.exists():
            # Parse docker-compose for connection details
            config = self._parse_docker_compose(docker_compose)
            if config:
                db_bench = DatabaseBenchmark(config)
                if db_bench.connect():
                    # Run various benchmarks
                    # Note: This assumes database is already running
                    # In production, we'd start it first
                    db_bench.disconnect()

        # Calculate total duration
        total_duration = 0
        if results['generator']:
            total_duration += results['generator'].get('duration', 0)

        results['total_duration'] = total_duration

        return results

    def _parse_docker_compose(self, compose_file: Path) -> Optional[Dict]:
        """Parse docker-compose.yml for database configuration"""
        try:
            import yaml
            with open(compose_file, 'r') as f:
                compose = yaml.safe_load(f)

            mysql_service = compose.get('services', {}).get('mysql', {})
            env = mysql_service.get('environment', {})
            ports = mysql_service.get('ports', [])

            # Extract port
            port = 3306
            if ports:
                port_mapping = ports[0].split(':')
                if len(port_mapping) == 2:
                    port = int(port_mapping[0])

            return {
                'host': 'localhost',
                'port': port,
                'user': 'root',
                'password': env.get('MYSQL_ROOT_PASSWORD', ''),
                'database': env.get('MYSQL_DATABASE', '')
            }
        except Exception as e:
            return None

    def _print_summary(self):
        """Print benchmark summary"""
        print(f"\n{'=' * 60}")
        print(f"{ColorOutput.BOLD}Benchmark Summary{ColorOutput.RESET}")
        print(f"{'=' * 60}")

        total_duration = (self.end_time - self.start_time).total_seconds()
        successful = sum(1 for r in self.results.values() if not r.get('errors'))
        failed = len(self.results) - successful

        print(f"Total Examples: {len(self.results)}")
        print(f"Successful: {ColorOutput.GREEN}{successful}{ColorOutput.RESET}")
        print(f"Failed: {ColorOutput.RED}{failed}{ColorOutput.RESET}")
        print(f"Total Duration: {total_duration:.2f}s")

        # Top performers
        if self.results:
            sorted_results = sorted(
                [(k, v) for k, v in self.results.items() if not v.get('errors')],
                key=lambda x: x[1].get('total_duration', float('inf'))
            )

            if sorted_results:
                print(f"\n{ColorOutput.BOLD}Top 5 Fastest Examples:{ColorOutput.RESET}")
                for i, (name, result) in enumerate(sorted_results[:5], 1):
                    duration = result.get('total_duration', 0)
                    rows = result.get('generator', {}).get('rows_generated', 0)
                    print(f"  {i}. {name}: {duration:.2f}s ({rows} rows)")

        # Memory usage
        all_memory = [r.get('generator', {}).get('memory_peak_mb', 0)
                     for r in self.results.values() if not r.get('errors')]
        if all_memory:
            print(f"\n{ColorOutput.BOLD}Memory Usage:{ColorOutput.RESET}")
            print(f"  Average: {statistics.mean(all_memory):.2f} MB")
            print(f"  Peak: {max(all_memory):.2f} MB")

    def _save_results(self):
        """Save benchmark results to file"""
        output_dir = self.project_root / 'benchmark_results'
        output_dir.mkdir(exist_ok=True)

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = output_dir / f'benchmark_{timestamp}.json'

        with open(output_file, 'w') as f:
            json.dump({
                'start_time': self.start_time.isoformat(),
                'end_time': self.end_time.isoformat(),
                'duration': (self.end_time - self.start_time).total_seconds(),
                'results': self.results
            }, f, indent=2)

        print(f"\nResults saved to: {output_file}")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='MySQL Business-to-Schema Benchmark Suite')
    parser.add_argument('--examples', nargs='+', help='Specific examples to benchmark')
    parser.add_argument('--parallel', action='store_true', help='Run benchmarks in parallel')
    parser.add_argument('--mode', choices=['test', 'production'], default='test',
                       help='Generator mode (test=small dataset, production=large dataset)')
    parser.add_argument('--output', help='Output file for results')

    args = parser.parse_args()

    # Get project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # Run benchmark suite
    suite = BenchmarkSuite(str(project_root))
    suite.run_all(parallel=args.parallel, examples=args.examples)

if __name__ == '__main__':
    main()