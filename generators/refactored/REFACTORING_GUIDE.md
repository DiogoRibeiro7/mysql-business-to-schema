# Generator Refactoring Guide

## Overview
This guide helps migrate existing generators to use the BaseGenerator class.

## Generators Found and Analysis:


### clinic Generator
- **File**: `clinic\generator.py`
- **Class**: ClinicDataGenerator
- **Tables**: patients, clinics, departments, doctors
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**: SQL  JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### ecommerce Generator
- **File**: `ecommerce\generator.py`
- **Class**: EcommerceGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### education Generator
- **File**: `education\generator.py`
- **Class**: EducationDataGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### event_ticketing Generator
- **File**: `event_ticketing\generator.py`
- **Class**: EventTicketingDataGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### fintech Generator
- **File**: `fintech\generator.py`
- **Class**: FinTechGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### fleet_management Generator
- **File**: `fleet_management\generator.py`
- **Class**: FleetManagementGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### healthcare_iot Generator
- **File**: `healthcare_iot\generator.py`
- **Class**: HealthcareIoTGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### industrial_iot Generator
- **File**: `industrial_iot\generator.py`
- **Class**: IndustrialIoTGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### iot_bins Generator
- **File**: `iot_bins\generator.py`
- **Class**: IoTBinsGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV 

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### logistics Generator
- **File**: `logistics\generator.py`
- **Class**: LogisticsGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### real_estate Generator
- **File**: `real_estate\generator.py`
- **Class**: RealEstateDataGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### smart_agriculture Generator
- **File**: `smart_agriculture\generator.py`
- **Class**: SmartAgricultureGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### smart_energy Generator
- **File**: `smart_energy\generator.py`
- **Class**: SmartEnergyGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### social_media Generator
- **File**: `social_media\generator.py`
- **Class**: SocialMediaGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


### streaming_ml Generator
- **File**: `streaming_ml\generator.py`
- **Class**: StreamingMLGenerator
- **Tables**: 
- **Uses Config**: True
- **Uses Faker**: True
- **Output Formats**:  CSV JSON

**Refactoring Steps**:
1. Inherit from BaseGenerator
2. Update __init__ to accept database parameters
3. Replace SQL string generation with bulk_insert calls
4. Use connection management from BaseGenerator
5. Implement proper error handling


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
