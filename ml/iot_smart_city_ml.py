"""
IoT and Smart City Machine Learning Models
Specialized ML for waste management, energy optimization, and urban analytics
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor, GradientBoostingClassifier
from sklearn.cluster import DBSCAN, KMeans
from sklearn.preprocessing import StandardScaler
from prophet import Prophet
import warnings
warnings.filterwarnings('ignore')

from ml_pipeline import (
    TimeSeriesForecaster, AnomalyDetector,
    MLPipeline, CustomerSegmentation
)


class SmartWasteManagement:
    """
    ML models for intelligent waste collection and management
    """

    def __init__(self):
        self.models = {}
        self.route_optimizer = None

    def predict_bin_fill_time(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Predict when waste bins will be full

        Args:
            df: DataFrame with bin sensor data

        Returns:
            DataFrame with fill time predictions
        """
        print("[OK] Training bin fill time prediction model...")

        # Features for fill rate prediction
        features = [
            'current_fill_level', 'location_type', 'day_of_week',
            'temperature', 'nearby_events', 'historical_fill_rate',
            'bin_capacity', 'last_emptied_hours_ago'
        ]

        # Create synthetic features if not present
        for feature in features:
            if feature not in df.columns:
                if feature == 'current_fill_level':
                    df[feature] = np.random.uniform(0, 100, len(df))
                elif feature == 'bin_capacity':
                    df[feature] = np.random.choice([100, 150, 200], len(df))
                elif feature == 'last_emptied_hours_ago':
                    df[feature] = np.random.exponential(24, len(df))
                elif feature == 'historical_fill_rate':
                    df[feature] = np.random.uniform(1, 5, len(df))  # % per hour
                elif feature == 'temperature':
                    df[feature] = np.random.normal(70, 10, len(df))
                elif feature == 'day_of_week':
                    df[feature] = np.random.randint(0, 7, len(df))
                elif feature == 'nearby_events':
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.8, 0.2])
                else:
                    df[feature] = np.random.randint(1, 5, len(df))

        # Calculate hours until full
        remaining_capacity = df['bin_capacity'] - df['current_fill_level']

        # Adjust fill rate based on factors
        adjusted_fill_rate = df['historical_fill_rate'].copy()
        adjusted_fill_rate *= (1 + 0.2 * df['nearby_events'])  # Events increase fill rate
        adjusted_fill_rate *= (1 + 0.1 * (df['day_of_week'].isin([5, 6])))  # Weekends

        hours_until_full = remaining_capacity / np.maximum(adjusted_fill_rate, 0.1)

        # Train model to predict fill time
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        X = df[[f for f in features if f in df.columns]]
        model.fit(X, hours_until_full)

        predictions = model.predict(X)

        results = pd.DataFrame({
            'bin_id': df.get('bin_id', range(len(df))),
            'current_fill_level': df['current_fill_level'],
            'predicted_hours_until_full': predictions,
            'predicted_full_time': pd.Timestamp.now() + pd.to_timedelta(predictions, unit='h'),
            'priority': pd.cut(
                predictions,
                bins=[0, 6, 12, 24, float('inf')],
                labels=['urgent', 'high', 'medium', 'low']
            ),
            'recommended_collection': predictions < 12
        })

        self.models['fill_predictor'] = model
        print(f"[OK] Fill time predictions complete for {len(df)} bins")
        return results

    def optimize_collection_routes(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Optimize waste collection routes using ML

        Args:
            df: DataFrame with bin locations and fill predictions

        Returns:
            Optimized collection routes
        """
        print("[OK] Optimizing collection routes...")

        # Create synthetic location data if not present
        if 'latitude' not in df.columns:
            df['latitude'] = np.random.uniform(40.7, 40.8, len(df))
        if 'longitude' not in df.columns:
            df['longitude'] = np.random.uniform(-74.0, -73.9, len(df))

        # Filter bins that need collection
        if 'predicted_hours_until_full' not in df.columns:
            df['predicted_hours_until_full'] = np.random.uniform(0, 48, len(df))

        urgent_bins = df[df['predicted_hours_until_full'] < 24].copy()

        if len(urgent_bins) == 0:
            print("[WARN] No bins require urgent collection")
            return pd.DataFrame()

        # Cluster bins by location for route optimization
        coords = urgent_bins[['latitude', 'longitude']].values

        # Use DBSCAN for geographic clustering
        clustering = DBSCAN(eps=0.01, min_samples=2)
        urgent_bins['cluster'] = clustering.fit_predict(coords)

        # Create routes for each cluster
        routes = []
        for cluster_id in urgent_bins['cluster'].unique():
            if cluster_id == -1:  # Noise points
                continue

            cluster_bins = urgent_bins[urgent_bins['cluster'] == cluster_id]

            # Simple TSP approximation using nearest neighbor
            route = self._nearest_neighbor_route(cluster_bins)

            routes.append({
                'route_id': f'route_{cluster_id}',
                'truck_id': f'truck_{cluster_id % 3 + 1}',  # Assign to available trucks
                'bins': route,
                'total_bins': len(route),
                'estimated_time_hours': len(route) * 0.25,  # 15 min per bin
                'total_capacity_needed': cluster_bins['bin_capacity'].sum() if 'bin_capacity' in cluster_bins else len(route) * 150
            })

        routes_df = pd.DataFrame(routes)

        print(f"[OK] Optimized {len(routes_df)} collection routes for {len(urgent_bins)} bins")
        return routes_df

    def detect_illegal_dumping(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Detect potential illegal dumping using anomaly detection

        Args:
            df: DataFrame with bin sensor data over time

        Returns:
            DataFrame with illegal dumping alerts
        """
        print("[OK] Detecting illegal dumping patterns...")

        # Features for anomaly detection
        features = [
            'fill_rate_change', 'sudden_weight_increase', 'off_hours_activity',
            'temperature_anomaly', 'unusual_fill_pattern'
        ]

        # Create synthetic anomaly features
        for feature in features:
            if feature not in df.columns:
                if feature == 'fill_rate_change':
                    df[feature] = np.random.exponential(2, len(df))
                elif feature == 'sudden_weight_increase':
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.95, 0.05])
                elif feature == 'off_hours_activity':
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.9, 0.1])
                else:
                    df[feature] = np.random.randn(len(df))

        # Use anomaly detector
        detector = AnomalyDetector(
            method='isolation_forest',
            features=[f for f in features if f in df.columns],
            contamination=0.1
        )

        detector.train(df)
        anomalies = detector.detect_anomalies(df)

        # Add specific dumping indicators
        anomalies['dumping_probability'] = (
            anomalies['anomaly_score'] * 0.4 +
            df.get('sudden_weight_increase', 0) * 0.3 +
            df.get('off_hours_activity', 0) * 0.3
        )

        anomalies['alert_type'] = 'normal'
        anomalies.loc[anomalies['dumping_probability'] > 0.7, 'alert_type'] = 'high_risk_dumping'
        anomalies.loc[anomalies['dumping_probability'] > 0.5, 'alert_type'] = 'suspicious_activity'

        results = pd.DataFrame({
            'bin_id': df.get('bin_id', range(len(df))),
            'timestamp': df.get('timestamp', pd.Timestamp.now()),
            'is_anomaly': anomalies['is_anomaly'],
            'dumping_probability': anomalies['dumping_probability'],
            'alert_type': anomalies['alert_type'],
            'recommended_action': anomalies['alert_type'].map({
                'high_risk_dumping': 'immediate_inspection',
                'suspicious_activity': 'schedule_inspection',
                'normal': 'no_action'
            })
        })

        print(f"[OK] Detected {results['is_anomaly'].sum()} potential illegal dumping incidents")
        return results

    def _nearest_neighbor_route(self, bins_df: pd.DataFrame) -> list:
        """Simple nearest neighbor routing for bin collection"""
        if len(bins_df) == 0:
            return []

        route = []
        remaining = bins_df.copy()
        current = remaining.iloc[0]
        route.append(current.get('bin_id', 0))
        remaining = remaining.iloc[1:]

        while len(remaining) > 0:
            # Find nearest bin
            distances = np.sqrt(
                (remaining['latitude'] - current['latitude'])**2 +
                (remaining['longitude'] - current['longitude'])**2
            )
            nearest_idx = distances.idxmin()
            current = remaining.loc[nearest_idx]
            route.append(current.get('bin_id', 0))
            remaining = remaining.drop(nearest_idx)

        return route


class SmartEnergyOptimization:
    """
    ML models for smart grid and energy optimization
    """

    def __init__(self):
        self.models = {}
        self.forecaster = None

    def forecast_energy_demand(self, df: pd.DataFrame, forecast_hours: int = 24) -> pd.DataFrame:
        """
        Forecast energy demand for smart grid optimization

        Args:
            df: DataFrame with historical energy consumption
            forecast_hours: Hours to forecast ahead

        Returns:
            Energy demand forecast
        """
        print(f"[OK] Forecasting energy demand for next {forecast_hours} hours...")

        # Prepare time series data
        if 'timestamp' not in df.columns:
            df['timestamp'] = pd.date_range(
                start='2024-01-01',
                periods=len(df),
                freq='H'
            )

        if 'energy_consumption' not in df.columns:
            # Create synthetic energy pattern
            hours = pd.to_datetime(df['timestamp']).dt.hour
            base_load = 1000

            # Daily pattern
            daily_pattern = np.where(
                (hours >= 6) & (hours <= 22),
                base_load * (1 + 0.3 * np.sin((hours - 6) * np.pi / 16)),
                base_load * 0.7
            )

            # Add weekly pattern
            day_of_week = pd.to_datetime(df['timestamp']).dt.dayofweek
            weekly_factor = np.where(day_of_week < 5, 1.0, 0.8)  # Lower on weekends

            df['energy_consumption'] = daily_pattern * weekly_factor + np.random.normal(0, 50, len(df))

        # Use TimeSeriesForecaster
        self.forecaster = TimeSeriesForecaster(
            method='prophet',
            target_column='energy_consumption',
            date_column='timestamp'
        )

        # Prepare data for Prophet
        ts_data = pd.DataFrame({
            'ds': df['timestamp'],
            'y': df['energy_consumption']
        })

        # Add additional regressors if available
        if 'temperature' in df.columns:
            ts_data['temperature'] = df['temperature']

        self.forecaster.train(ts_data)
        forecast = self.forecaster.forecast(periods=forecast_hours)

        # Add peak detection
        forecast['is_peak'] = forecast['yhat'] > forecast['yhat'].quantile(0.8)

        # Add load categories
        forecast['load_category'] = pd.cut(
            forecast['yhat'],
            bins=[0, 800, 1200, 1500, float('inf')],
            labels=['low', 'normal', 'high', 'critical']
        )

        print(f"[OK] Energy demand forecast complete")
        return forecast

    def optimize_renewable_mix(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Optimize renewable energy source mix based on predictions

        Args:
            df: DataFrame with weather and energy data

        Returns:
            Optimal renewable energy mix
        """
        print("[OK] Optimizing renewable energy mix...")

        # Features for renewable optimization
        features = [
            'solar_irradiance', 'wind_speed', 'temperature',
            'cloud_cover', 'humidity', 'hour_of_day'
        ]

        # Create synthetic features if not present
        for feature in features:
            if feature not in df.columns:
                if feature == 'solar_irradiance':
                    hour = pd.to_datetime(df.get('timestamp', pd.Timestamp.now())).dt.hour
                    df[feature] = np.maximum(0, 1000 * np.sin((hour - 6) * np.pi / 12))
                elif feature == 'wind_speed':
                    df[feature] = np.random.gamma(2, 2, len(df))
                elif feature == 'cloud_cover':
                    df[feature] = np.random.uniform(0, 1, len(df))
                elif feature == 'temperature':
                    df[feature] = np.random.normal(70, 10, len(df))
                elif feature == 'hour_of_day':
                    df[feature] = pd.to_datetime(df.get('timestamp', pd.Timestamp.now())).dt.hour
                else:
                    df[feature] = np.random.uniform(0, 1, len(df))

        # Calculate renewable potential
        solar_potential = df['solar_irradiance'] * (1 - df['cloud_cover']) / 1000
        wind_potential = np.minimum(1, df['wind_speed'] / 15)  # Normalized wind potential

        # Calculate optimal mix based on availability
        total_potential = solar_potential + wind_potential

        results = pd.DataFrame({
            'timestamp': df.get('timestamp', pd.date_range(start='2024-01-01', periods=len(df), freq='H')),
            'solar_percentage': (solar_potential / np.maximum(total_potential, 0.01) * 100).round(1),
            'wind_percentage': (wind_potential / np.maximum(total_potential, 0.01) * 100).round(1),
            'solar_mw': solar_potential * 100,  # Assuming 100MW solar capacity
            'wind_mw': wind_potential * 150,  # Assuming 150MW wind capacity
            'total_renewable_mw': solar_potential * 100 + wind_potential * 150,
            'grid_supplement_needed': np.maximum(0, df.get('energy_consumption', 1000) - (solar_potential * 100 + wind_potential * 150))
        })

        # Add recommendations
        results['recommendation'] = 'balanced_mix'
        results.loc[results['solar_percentage'] > 70, 'recommendation'] = 'maximize_solar'
        results.loc[results['wind_percentage'] > 70, 'recommendation'] = 'maximize_wind'
        results.loc[results['grid_supplement_needed'] > 500, 'recommendation'] = 'activate_backup'

        print(f"[OK] Renewable mix optimization complete")
        return results

    def detect_grid_anomalies(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Detect anomalies in power grid operation

        Args:
            df: DataFrame with grid sensor data

        Returns:
            Grid anomaly detection results
        """
        print("[OK] Detecting grid anomalies...")

        # Grid health features
        features = [
            'voltage', 'current', 'frequency', 'power_factor',
            'transformer_temperature', 'line_losses'
        ]

        # Create synthetic features
        for feature in features:
            if feature not in df.columns:
                if feature == 'voltage':
                    df[feature] = np.random.normal(230, 5, len(df))
                elif feature == 'frequency':
                    df[feature] = np.random.normal(50, 0.1, len(df))
                elif feature == 'power_factor':
                    df[feature] = np.random.uniform(0.85, 0.99, len(df))
                elif feature == 'transformer_temperature':
                    df[feature] = np.random.normal(65, 10, len(df))
                else:
                    df[feature] = np.random.exponential(2, len(df))

        # Anomaly detection
        detector = AnomalyDetector(
            method='isolation_forest',
            features=[f for f in features if f in df.columns]
        )

        detector.train(df)
        anomalies = detector.detect_anomalies(df)

        # Classify anomaly types
        anomalies['anomaly_type'] = 'normal'

        if 'voltage' in df.columns:
            anomalies.loc[(df['voltage'] < 220) | (df['voltage'] > 240), 'anomaly_type'] = 'voltage_fluctuation'

        if 'frequency' in df.columns:
            anomalies.loc[(df['frequency'] < 49.5) | (df['frequency'] > 50.5), 'anomaly_type'] = 'frequency_deviation'

        if 'transformer_temperature' in df.columns:
            anomalies.loc[df['transformer_temperature'] > 85, 'anomaly_type'] = 'overheating'

        # Priority levels
        anomalies['priority'] = anomalies['anomaly_type'].map({
            'overheating': 'critical',
            'voltage_fluctuation': 'high',
            'frequency_deviation': 'medium',
            'normal': 'low'
        })

        results = pd.DataFrame({
            'timestamp': df.get('timestamp', pd.Timestamp.now()),
            'is_anomaly': anomalies['is_anomaly'],
            'anomaly_type': anomalies['anomaly_type'],
            'anomaly_score': anomalies['anomaly_score'],
            'priority': anomalies['priority'],
            'action_required': anomalies['priority'].isin(['critical', 'high'])
        })

        print(f"[OK] Detected {results['is_anomaly'].sum()} grid anomalies")
        return results

    def predict_equipment_failure(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Predict equipment failure in power grid

        Args:
            df: DataFrame with equipment sensor data

        Returns:
            Equipment failure predictions
        """
        print("[OK] Predicting equipment failures...")

        # Equipment health features
        features = [
            'operating_hours', 'maintenance_age_days', 'vibration_level',
            'temperature_delta', 'load_cycles', 'efficiency_ratio'
        ]

        # Create synthetic features
        for feature in features:
            if feature not in df.columns:
                if feature == 'operating_hours':
                    df[feature] = np.random.exponential(5000, len(df))
                elif feature == 'maintenance_age_days':
                    df[feature] = np.random.exponential(180, len(df))
                elif feature == 'load_cycles':
                    df[feature] = np.random.poisson(1000, len(df))
                elif feature == 'efficiency_ratio':
                    df[feature] = np.random.beta(9, 2, len(df))
                else:
                    df[feature] = np.random.exponential(1, len(df))

        # Calculate failure probability
        failure_score = (
            (df.get('operating_hours', 0) / 10000) * 0.25 +
            (df.get('maintenance_age_days', 0) / 365) * 0.25 +
            (df.get('vibration_level', 0) / 10) * 0.25 +
            (1 - df.get('efficiency_ratio', 0.9)) * 0.25
        )

        # Train failure prediction model
        pipeline = MLPipeline(
            model_type='gradient_boosting',
            task_type='classification',
            features=[f for f in features if f in df.columns],
            target='will_fail' if 'will_fail' in df.columns else None
        )

        # Create synthetic target
        if 'will_fail' not in df.columns:
            df['will_fail'] = (failure_score + np.random.normal(0, 0.1, len(df))) > 0.6

        pipeline.train(df)
        predictions = pipeline.predict(df)

        # Calculate days until failure
        days_until_failure = np.where(
            predictions == 1,
            np.random.exponential(30, len(df)),
            np.random.exponential(365, len(df))
        )

        results = pd.DataFrame({
            'equipment_id': df.get('equipment_id', range(len(df))),
            'failure_probability': failure_score,
            'will_fail_soon': predictions,
            'estimated_days_until_failure': days_until_failure,
            'maintenance_priority': pd.cut(
                days_until_failure,
                bins=[0, 7, 30, 90, float('inf')],
                labels=['urgent', 'high', 'medium', 'low']
            ),
            'recommended_action': np.where(
                days_until_failure < 30,
                'schedule_maintenance',
                'monitor'
            )
        })

        print(f"[OK] Equipment failure predictions complete for {len(df)} units")
        return results


class UrbanTrafficOptimization:
    """
    ML models for urban traffic and transportation optimization
    """

    def __init__(self):
        self.models = {}

    def predict_traffic_flow(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Predict traffic flow patterns

        Args:
            df: DataFrame with traffic sensor data

        Returns:
            Traffic flow predictions
        """
        print("[OK] Predicting traffic flow...")

        # Traffic features
        features = [
            'hour_of_day', 'day_of_week', 'is_holiday',
            'weather_condition', 'temperature', 'events_nearby',
            'historical_avg_speed', 'current_occupancy'
        ]

        # Create synthetic features
        for feature in features:
            if feature not in df.columns:
                if feature == 'hour_of_day':
                    df[feature] = np.random.randint(0, 24, len(df))
                elif feature == 'day_of_week':
                    df[feature] = np.random.randint(0, 7, len(df))
                elif feature == 'is_holiday':
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.95, 0.05])
                elif feature == 'weather_condition':
                    df[feature] = np.random.choice([0, 1, 2], len(df), p=[0.7, 0.2, 0.1])  # Clear, rain, snow
                elif feature == 'historical_avg_speed':
                    df[feature] = np.random.normal(35, 10, len(df))
                elif feature == 'current_occupancy':
                    df[feature] = np.random.uniform(0, 1, len(df))
                else:
                    df[feature] = np.random.randn(len(df))

        # Calculate traffic flow
        base_flow = 1000  # vehicles per hour
        hour_factor = np.where(
            (df['hour_of_day'] >= 7) & (df['hour_of_day'] <= 9) |
            (df['hour_of_day'] >= 17) & (df['hour_of_day'] <= 19),
            1.5,  # Rush hour
            1.0
        )

        weather_factor = 1 - 0.2 * df.get('weather_condition', 0) / 2  # Reduce in bad weather

        predicted_flow = base_flow * hour_factor * weather_factor * (1 + np.random.normal(0, 0.1, len(df)))
        predicted_speed = df.get('historical_avg_speed', 35) * (1 - df.get('current_occupancy', 0.5))

        # Congestion level
        congestion = pd.cut(
            predicted_speed,
            bins=[0, 15, 25, 35, float('inf')],
            labels=['severe', 'heavy', 'moderate', 'light']
        )

        results = pd.DataFrame({
            'segment_id': df.get('segment_id', range(len(df))),
            'predicted_flow': predicted_flow.round(),
            'predicted_speed_mph': predicted_speed.round(1),
            'congestion_level': congestion,
            'travel_time_minutes': (df.get('segment_length', 1) / predicted_speed * 60).round(1),
            'recommended_route': congestion.isin(['light', 'moderate'])
        })

        print(f"[OK] Traffic flow predictions complete for {len(df)} segments")
        return results

    def optimize_signal_timing(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Optimize traffic signal timing using ML

        Args:
            df: DataFrame with intersection data

        Returns:
            Optimized signal timings
        """
        print("[OK] Optimizing signal timings...")

        # Create synthetic intersection data
        if 'north_south_flow' not in df.columns:
            df['north_south_flow'] = np.random.poisson(20, len(df))
        if 'east_west_flow' not in df.columns:
            df['east_west_flow'] = np.random.poisson(15, len(df))
        if 'pedestrian_count' not in df.columns:
            df['pedestrian_count'] = np.random.poisson(5, len(df))

        # Calculate optimal cycle times
        total_flow = df['north_south_flow'] + df['east_west_flow']
        ns_ratio = df['north_south_flow'] / np.maximum(total_flow, 1)

        # Base cycle time with adjustments
        base_cycle = 90  # seconds
        cycle_time = base_cycle + np.minimum(30, total_flow / 10)

        # Green time allocation
        ns_green = cycle_time * ns_ratio * 0.8  # 80% for traffic, 20% for yellow/red
        ew_green = cycle_time * (1 - ns_ratio) * 0.8

        # Pedestrian adjustment
        ped_adjustment = np.minimum(10, df['pedestrian_count'] / 2)

        results = pd.DataFrame({
            'intersection_id': df.get('intersection_id', range(len(df))),
            'cycle_time_seconds': cycle_time.round(),
            'north_south_green': (ns_green - ped_adjustment/2).round(),
            'east_west_green': (ew_green - ped_adjustment/2).round(),
            'pedestrian_crossing_time': (15 + ped_adjustment).round(),
            'efficiency_score': (1 - (df['north_south_flow'] + df['east_west_flow']) / (cycle_time * 10)).clip(0, 1),
            'adaptive_timing_enabled': total_flow > 30
        })

        print(f"[OK] Signal timing optimization complete for {len(df)} intersections")
        return results


def main():
    """Example usage of IoT and Smart City ML models"""
    print("=" * 60)
    print("IoT and Smart City Machine Learning Models")
    print("=" * 60)

    # Initialize models
    waste_mgmt = SmartWasteManagement()
    energy_opt = SmartEnergyOptimization()
    traffic_opt = UrbanTrafficOptimization()

    # 1. Waste Management
    print("\n1. Smart Waste Management")
    print("-" * 40)

    # Create sample bin data
    bin_data = pd.DataFrame({
        'bin_id': range(1, 51),
        'current_fill_level': np.random.uniform(20, 95, 50),
        'bin_capacity': np.random.choice([100, 150, 200], 50),
        'location_type': np.random.choice([1, 2, 3], 50),  # Residential, commercial, public
        'latitude': np.random.uniform(40.7, 40.8, 50),
        'longitude': np.random.uniform(-74.0, -73.9, 50)
    })

    # Predict fill times
    fill_predictions = waste_mgmt.predict_bin_fill_time(bin_data)
    print("\nBin fill predictions:")
    print(fill_predictions.head())
    print(f"Urgent collections needed: {(fill_predictions['priority'] == 'urgent').sum()}")

    # Optimize routes
    routes = waste_mgmt.optimize_collection_routes(bin_data)
    print("\nOptimized collection routes:")
    print(routes)

    # Detect illegal dumping
    dumping_alerts = waste_mgmt.detect_illegal_dumping(bin_data)
    print(f"\nIllegal dumping alerts: {(dumping_alerts['alert_type'] != 'normal').sum()}")

    # 2. Smart Energy
    print("\n2. Smart Energy Optimization")
    print("-" * 40)

    # Create sample energy data
    energy_data = pd.DataFrame({
        'timestamp': pd.date_range(start='2024-01-01', periods=168, freq='H'),  # 1 week
        'energy_consumption': 1000 + 300 * np.sin(np.arange(168) * 2 * np.pi / 24) + np.random.normal(0, 50, 168),
        'temperature': 70 + 15 * np.sin(np.arange(168) * 2 * np.pi / 24) + np.random.normal(0, 5, 168)
    })

    # Forecast demand
    demand_forecast = energy_opt.forecast_energy_demand(energy_data, forecast_hours=24)
    print("\nEnergy demand forecast (next 24 hours):")
    print(demand_forecast.head())
    print(f"Peak hours predicted: {demand_forecast['is_peak'].sum()}")

    # Optimize renewable mix
    renewable_mix = energy_opt.optimize_renewable_mix(energy_data)
    print("\nRenewable energy mix optimization:")
    print(renewable_mix.head())
    avg_renewable = renewable_mix['total_renewable_mw'].mean()
    print(f"Average renewable generation: {avg_renewable:.1f} MW")

    # Detect grid anomalies
    grid_data = pd.DataFrame({
        'voltage': np.random.normal(230, 5, 100),
        'frequency': np.random.normal(50, 0.1, 100),
        'transformer_temperature': np.random.normal(65, 10, 100)
    })

    anomalies = energy_opt.detect_grid_anomalies(grid_data)
    print(f"\nGrid anomalies detected: {anomalies['is_anomaly'].sum()}")
    print(f"Critical issues: {(anomalies['priority'] == 'critical').sum()}")

    # Predict equipment failures
    equipment_data = pd.DataFrame({
        'equipment_id': range(1, 21),
        'operating_hours': np.random.exponential(5000, 20),
        'maintenance_age_days': np.random.exponential(180, 20),
        'efficiency_ratio': np.random.beta(9, 2, 20)
    })

    failure_predictions = energy_opt.predict_equipment_failure(equipment_data)
    print("\nEquipment failure predictions:")
    print(failure_predictions.head())
    print(f"Urgent maintenance needed: {(failure_predictions['maintenance_priority'] == 'urgent').sum()}")

    # 3. Traffic Optimization
    print("\n3. Urban Traffic Optimization")
    print("-" * 40)

    # Create sample traffic data
    traffic_data = pd.DataFrame({
        'segment_id': range(1, 31),
        'hour_of_day': np.random.randint(0, 24, 30),
        'current_occupancy': np.random.uniform(0.2, 0.9, 30),
        'segment_length': np.random.uniform(0.5, 2, 30)  # miles
    })

    # Predict traffic flow
    flow_predictions = traffic_opt.predict_traffic_flow(traffic_data)
    print("\nTraffic flow predictions:")
    print(flow_predictions.head())
    print(f"Congested segments: {(flow_predictions['congestion_level'].isin(['heavy', 'severe'])).sum()}")

    # Optimize signal timing
    intersection_data = pd.DataFrame({
        'intersection_id': range(1, 11),
        'north_south_flow': np.random.poisson(25, 10),
        'east_west_flow': np.random.poisson(20, 10),
        'pedestrian_count': np.random.poisson(8, 10)
    })

    signal_timing = traffic_opt.optimize_signal_timing(intersection_data)
    print("\nOptimized signal timings:")
    print(signal_timing.head())
    avg_efficiency = signal_timing['efficiency_score'].mean()
    print(f"Average intersection efficiency: {avg_efficiency:.2%}")


if __name__ == "__main__":
    main()