# Real Estate Data Generator

## Overview

A comprehensive data generator for the Real Estate Platform (Example 12) that creates realistic property listings, market dynamics, and user interactions. This generator simulates a complete real estate ecosystem with seasonal patterns, market trends, and realistic property distributions.

## Features

### 🏠 Property Generation
- **10,000 properties** across residential, commercial, and land categories
- Realistic property characteristics (size, bedrooms, bathrooms, age)
- Property features and amenities (15+ per property)
- Detailed room layouts with dimensions
- Property photos metadata (15-20 per property)
- Tax assessment history

### 🌍 Location Hierarchy
- Countries → States → Cities → Zip Codes → Neighborhoods
- Population and income-based pricing
- Walk scores and transit scores
- School ratings and crime statistics
- Geographic coordinates for spatial queries

### 👥 Agents & Brokerages
- **50 brokerages** with licensing information
- **500 agents** with performance metrics
- Specializations and experience levels
- Commission structures
- Performance ratings

### 📊 Market Dynamics
- **Seasonal variations**: Spring boost (15%), Winter slowdown (15%)
- **Price negotiations**: ±5% from list price
- **Interest rate impacts** on pricing
- Monthly market trends per city
- Days on market calculations
- Inventory absorption rates

### 🏷️ Listings Management
- **2,000 active listings**
- **5,000 sold properties**
- **500 pending sales**
- Price change history
- Status progression tracking
- MLS integration simulation

### 👁️ User Interactions
- **5,000 users** (buyers, sellers, renters, investors)
- User search preferences
- **100+ viewings per day**
- Viewing feedback and ratings
- **50+ offers per week**
- Offer contingencies

## Data Volumes

| Entity | Count | Description |
|--------|-------|-------------|
| Properties | 10,000 | All property records |
| Active Listings | 2,000 | Currently on market |
| Sold Listings | 5,000 | Historical sales |
| Pending Listings | 500 | Under contract |
| Agents | 500 | Licensed agents |
| Brokerages | 50 | Real estate firms |
| Users | 5,000 | Platform users |
| Neighborhoods | 150 | Geographic areas |
| Property Photos | ~150,000 | 15 per property avg |
| Property Features | ~100,000 | 10 per property avg |
| Viewings | ~20,000 | Historical viewings |
| Offers | ~2,000 | Purchase offers |
| Market Trends | ~300 | Monthly city data |

## Installation

```bash
# Install Python dependencies
pip install -r requirements.txt
```

## Usage

### Basic Usage

```bash
# Generate with default configuration
python generator.py

# Custom output directory
python generator.py --output ./custom_output

# Custom configuration file
python generator.py --config my_config.json

# Set random seed for reproducibility
python generator.py --seed 12345
```

### Configuration

Edit `config.json` to customize:

```json
{
  "counts": {
    "properties": 10000,
    "active_listings": 2000,
    "agents": 500,
    "users": 5000
  },
  "price_ranges": {
    "residential": {
      "min": 150000,
      "max": 2000000
    }
  },
  "market_dynamics": {
    "seasonal_variation": true,
    "spring_boost": 1.15,
    "average_days_on_market": 45
  }
}
```

## Generated Files

The generator creates CSV files in the output directory:

### Core Data Files
- `properties.csv` - Property details
- `listings.csv` - Active and sold listings
- `agents.csv` - Real estate agents
- `brokerages.csv` - Brokerage firms
- `users.csv` - Platform users

### Location Files
- `countries.csv` - Country data
- `states_provinces.csv` - State information
- `cities.csv` - City demographics
- `zip_codes.csv` - Zip code data
- `neighborhoods.csv` - Neighborhood characteristics

### Property Details
- `property_features.csv` - Amenities and features
- `property_rooms.csv` - Room specifications
- `property_photos.csv` - Photo metadata
- `property_taxes.csv` - Tax history
- `property_types.csv` - Property type hierarchy

### Transaction Data
- `viewings.csv` - Property showings
- `viewing_feedback.csv` - Viewer feedback
- `offers.csv` - Purchase offers
- `offer_contingencies.csv` - Offer conditions
- `price_changes.csv` - Listing price history
- `listing_status_history.csv` - Status transitions

### Market Analysis
- `market_trends.csv` - Monthly market metrics
- `user_preferences.csv` - Buyer search criteria

## Loading into MySQL

```bash
# 1. Create the database schema
mysql -u root < ../../example_12_real_estate/schema/00_create_database.sql
mysql -u root real_estate < ../../example_12_real_estate/schema/01_tables.sql

# 2. Load generated data
for file in output/*.csv; do
    table=$(basename $file .csv)
    mysql -u root real_estate -e "
        LOAD DATA LOCAL INFILE '$file'
        INTO TABLE $table
        FIELDS TERMINATED BY ','
        ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        IGNORE 1 ROWS;"
done
```

## Data Characteristics

### Property Distribution
- **70% Residential**: Single family, condos, townhouses
- **20% Commercial**: Retail, office, industrial
- **10% Land**: Vacant, agricultural, recreational

### Price Ranges
- **Residential**: $150,000 - $2,000,000
- **Commercial**: $500,000 - $10,000,000
- **Land**: $50,000 - $500,000
- **Rentals**: $1,000 - $10,000/month

### Market Patterns
- **Seasonal**: 15% price boost in spring, 15% slowdown in winter
- **Days on Market**: Average 45 days, hot properties <14 days
- **Offer Success**: ~30% of offers accepted
- **Viewing Conversion**: ~15% of viewings lead to offers

### User Behavior
- **50% Buyers**: Actively searching for properties
- **20% Sellers**: Listing their properties
- **20% Renters**: Looking for rentals
- **10% Investors**: Multiple property purchases

## Realistic Features

### Market Dynamics
- Interest rate impacts on pricing
- Seasonal buying patterns
- Price negotiation ranges
- Market inventory cycles

### Agent Performance
- Commission structures (6% sales, 1 month rent)
- Performance ratings based on sales
- Specialization areas
- Years of experience correlation

### Property Characteristics
- Age-based value adjustments
- Location-based pricing (neighborhood median)
- Size and bedroom premiums
- HOA fees for condos

### User Interactions
- Viewing cancellation rates (15%)
- No-show rates (5%)
- Multiple offers on hot properties
- Contingency patterns

## Performance

Generation times on standard hardware:
- Location hierarchy: ~2 seconds
- Properties (10,000): ~15 seconds
- Listings & history: ~10 seconds
- User interactions: ~8 seconds
- Total generation: ~45 seconds

## Troubleshooting

### Common Issues

1. **Memory Usage**: For large datasets (>50,000 properties), increase Python heap:
   ```bash
   python -Xmx4g generator.py
   ```

2. **Slow Generation**: Reduce photo/feature counts in config:
   ```json
   "photos_per_property": 5,
   "features_per_property": 5
   ```

3. **Date Errors**: Ensure date ranges in config are valid:
   ```json
   "listing_history_start": "2023-01-01",
   "listing_history_end": "2024-12-31"
   ```

## Customization

### Adding Custom Property Types
Edit the `property_type_hierarchy` in generator.py:
```python
'residential': {
    'custom_type': ['subtype1', 'subtype2']
}
```

### Adjusting Market Dynamics
Modify market factors in config.json:
```json
"market_dynamics": {
    "spring_boost": 1.20,  // 20% spring increase
    "interest_rate_impact": true,
    "current_interest_rate": 7.25
}
```

### Custom Features
Add features to the `features` dictionary:
```python
'luxury': [
    'Wine Cellar', 'Elevator', 'Guest House'
]
```

## Validation

Run validation after generation:
```bash
# Check record counts
python -c "
import pandas as pd
import glob

for file in glob.glob('output/*.csv'):
    df = pd.read_csv(file)
    print(f'{file}: {len(df)} records')
"
```

## Contributing

To improve the generator:
1. Add new property types or features
2. Enhance market dynamics algorithms
3. Add more realistic user behavior patterns
4. Improve geographic distribution
5. Add international market support

## License

MIT License - Part of the MySQL Business to Schema project