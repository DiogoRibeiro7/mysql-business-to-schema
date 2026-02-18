# Event Ticketing Data Generator

## Overview

A comprehensive data generator for the Event Ticketing Platform (Example 13) that creates realistic venue configurations, events, performances, and booking transactions. This generator simulates a complete ticketing ecosystem with dynamic pricing, seat management, and customer behavior patterns.

## Features

### 🏟️ Venue Configuration
- **25 venues** across different types (stadiums, arenas, theaters, clubs)
- Detailed seating maps with sections, rows, and individual seats
- Capacity ranges from 200 (clubs) to 80,000 (stadiums)
- Accessibility information and view quality ratings
- Entry gates and venue rules

### 🎭 Event Management
- **500 events** across 6 main categories
- **200 performers** (artists, bands, teams, speakers)
- **2,000 performances** scheduled over 365 days
- Tours, festivals, seasons, and single events
- Age restrictions and duration tracking

### 💺 Seating & Pricing
- Individual seat tracking with coordinates
- Dynamic pricing based on:
  - Day of week (weekends 30% higher)
  - Time to event (early bird discounts)
  - Demand levels (surge pricing)
  - Section quality (VIP, Premium, Standard, Economy)
- Service fees, facility fees, and processing fees

### 👥 Customer Experience
- **10,000 customers** with preferences
- **2,000 loyalty members** with tier benefits
- Payment methods (credit/debit, PayPal, Apple Pay)
- Guest checkout and mobile ticketing
- Customer analytics and behavior tracking

### 🎫 Ticketing Operations
- **100,000+ tickets** generated
- Real-time seat selection and availability
- 10-minute cart hold mechanism
- Group bookings (10+ tickets)
- Ticket transfers between customers
- **1,000 resale listings** with markup controls

### 📊 Analytics & Metrics
- Sales metrics per performance
- Venue utilization tracking
- Revenue optimization
- Occupancy rates
- Customer lifetime value

## Data Volumes

| Entity | Count | Description |
|--------|-------|-------------|
| Venues | 25 | Various types and capacities |
| Venue Seats | ~250,000 | Individual seat records |
| Events | 500 | Tours, festivals, shows |
| Performances | 2,000 | Individual show instances |
| Performers | 200 | Artists, bands, speakers |
| Customers | 10,000 | Registered users |
| Bookings | ~30,000 | Purchase transactions |
| Tickets | 100,000+ | Individual tickets |
| Price Tiers | ~8,000 | Section/performance pricing |
| Resale Listings | 1,000 | Secondary market |
| Promotional Codes | 50 | Discount codes |

## Installation

```bash
# Install Python dependencies
poetry install --no-root
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
python generator.py --seed 42
```

### Configuration

Edit `config.json` to customize:

```json
{
  "counts": {
    "venues": 25,
    "events": 500,
    "customers": 10000,
    "total_tickets": 100000
  },
  "pricing": {
    "base_price_min": 25,
    "base_price_max": 500,
    "service_fee_percentage": 0.15
  },
  "dynamic_pricing": {
    "enabled": true,
    "surge_multiplier": 1.5,
    "day_of_week_factors": {
      "friday": 1.2,
      "saturday": 1.3
    }
  }
}
```

## Generated Files

The generator creates CSV files in the output directory:

### Venue Configuration
- `venues.csv` - Venue information
- `venue_sections.csv` - Seating sections
- `venue_rows.csv` - Row configurations
- `venue_seats.csv` - Individual seats

### Event Catalog
- `event_categories.csv` - Event categorization
- `performers.csv` - Artists and performers
- `events.csv` - Event information
- `performances.csv` - Show schedules
- `event_performers.csv` - Event lineup
- `price_tiers.csv` - Pricing structure

### Customer Data
- `customers.csv` - Customer accounts
- `customer_preferences.csv` - Preferences
- `loyalty_members.csv` - Loyalty program
- `payment_methods.csv` - Payment information

### Transactions
- `booking_transactions.csv` - Purchase records
- `tickets.csv` - Individual tickets
- `payment_transactions.csv` - Payments
- `promotional_codes.csv` - Discount codes
- `ticket_transfers.csv` - Ticket transfers
- `resale_listings.csv` - Secondary market
- `resale_transactions.csv` - Resale sales

### Analytics
- `sales_metrics.csv` - Performance metrics
- `venue_utilization.csv` - Venue usage stats

## Loading into MySQL

```bash
# 1. Create the database schema
mysql -u root < ../../example_13_event_ticketing/schema/00_create_database.sql
mysql -u root event_ticketing < ../../example_13_event_ticketing/schema/01_tables.sql

# 2. Load generated data
for file in output/*.csv; do
    table=$(basename $file .csv)
    mysql -u root event_ticketing -e "
        LOAD DATA LOCAL INFILE '$file'
        INTO TABLE $table
        FIELDS TERMINATED BY ','
        ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        IGNORE 1 ROWS;"
done
```

## Data Characteristics

### Venue Distribution
- **10% Stadiums**: 20,000-80,000 capacity
- **15% Arenas**: 5,000-20,000 capacity
- **30% Theaters**: 500-3,000 capacity
- **20% Concert Halls**: 1,000-5,000 capacity
- **15% Clubs**: 200-1,000 capacity
- **10% Conference Centers**: 100-5,000 capacity

### Pricing Structure
- **Base Prices**: $25-$500
- **VIP Multiplier**: 3x base price
- **Premium Multiplier**: 1.5x base price
- **Early Bird Discount**: 20% off
- **Group Discount**: 15% off (10+ tickets)
- **Service Fee**: 15% of ticket price
- **Facility Fee**: $5 per ticket
- **Processing Fee**: $3.50 per order

### Dynamic Pricing Factors
- **Monday-Tuesday**: 0.8x (20% discount)
- **Wednesday-Thursday**: 0.9-0.95x
- **Friday**: 1.2x (20% premium)
- **Saturday**: 1.3x (30% premium)
- **Sunday**: 1.1x (10% premium)
- **High Demand** (>70% sold): 1.5x surge
- **Low Demand** (<30% sold): 0.8x discount

### Customer Behavior
- **Cart Abandonment**: 25%
- **Average Tickets/Booking**: 2.5
- **Repeat Customer Rate**: 30%
- **Loyalty Signup**: 20%
- **Mobile Purchase**: 60%
- **Ticket Transfer Rate**: 10%
- **Resale Rate**: 8%

### Payment Methods
- **70% Credit Card**
- **15% Debit Card**
- **10% PayPal**
- **5% Apple Pay**

### Ticket Delivery
- **50% Mobile** (QR code)
- **30% Email** (PDF)
- **15% Will Call** (box office)
- **5% Mail** (physical)

## Realistic Features

### Seat Management
- Individual seat tracking
- Accessible seating with companion seats
- Obstructed view notifications
- Aisle seat identification
- Section-based entry gates

### Dynamic Pricing Engine
- Real-time demand-based pricing
- Time-to-event adjustments
- Day-of-week variations
- Section quality tiers
- Group discounts

### Booking Patterns
- Peak booking hours (12pm, 6-8pm)
- 10-minute cart expiration
- Guest checkout option
- Fraud detection patterns
- IP-based rate limiting

### Secondary Market
- Resale price caps (2x face value)
- Platform fees (10%)
- Seller payouts (90%)
- Transfer restrictions

### Seasonal Patterns
- **Peak Months**: May-August, November-December
- **Slow Months**: January-February
- **Holiday Surge**: 1.5x activity
- **Summer Festival Boost**: 1.3x events

## Performance

Generation times on standard hardware:
- Venue configuration: ~5 seconds
- Events & performances: ~8 seconds
- Customer base: ~10 seconds
- Bookings & tickets: ~15 seconds
- Total generation: ~45 seconds

## Troubleshooting

### Common Issues

1. **Memory Usage**: For large venues (>50,000 seats):
   ```bash
   python -Xmx4g generator.py
   ```

2. **Slow Generation**: Reduce counts in config:
   ```json
   "seats_per_row": 15,
   "rows_per_section": 10
   ```

3. **Booking Failures**: Ensure enough performances:
   ```json
   "performances": 2000,
   "total_tickets": 50000
   ```

## Customization

### Adding Venue Types
Edit venue_types in config.json:
```json
"venue_types": {
    "amphitheater": {
        "capacity_min": 3000,
        "capacity_max": 10000,
        "sections": ["lawn", "pavilion"],
        "distribution": 0.1
    }
}
```

### Adjusting Pricing
Modify pricing factors:
```json
"dynamic_pricing": {
    "surge_multiplier": 2.0,
    "day_of_week_factors": {
        "friday": 1.5
    }
}
```

### Event Categories
Add new categories:
```json
"event_categories": [
    {
        "name": "E-Sports",
        "subcategories": ["League of Legends", "CS:GO", "Dota 2"]
    }
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

# Verify seat availability
python -c "
import pandas as pd

seats = pd.read_csv('output/venue_seats.csv')
tickets = pd.read_csv('output/tickets.csv')
print(f'Total seats: {len(seats)}')
print(f'Tickets sold: {len(tickets)}')
print(f'Utilization: {len(tickets)/len(seats)*100:.1f}%')
"
```

## Use Cases

This generator simulates:
1. **High-demand events** with surge pricing
2. **Season tickets** with multiple performances
3. **Festival ticketing** with multi-day passes
4. **Corporate group bookings**
5. **Secondary market dynamics**
6. **Loyalty program benefits**
7. **Dynamic pricing optimization**
8. **Venue utilization analysis**

## Contributing

To improve the generator:
1. Add more venue types (outdoor, festival grounds)
2. Enhance pricing algorithms
3. Add international venues
4. Implement subscription models
5. Add virtual event support

## License

MIT License - Part of the MySQL Business to Schema project
