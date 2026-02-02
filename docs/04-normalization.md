# Normalization Notes

## 1NF
- All tables store atomic values (no repeating groups or arrays).
- Multi-valued services on an appointment are modeled as appointment_service rows.

## 2NF
- All non-key attributes depend on the whole key.
- Where composite meaning exists (appointment + service), a surrogate key is used in appointment_service, and attributes like quantity/unit_price depend on that row.

## 3NF
- Non-key attributes depend only on the key, not on other non-key attributes.
- Reference data (doctor, patient, service) is separated from transactional data (appointment, invoice, payment).

## Deliberate denormalization
- invoice.total_amount and invoice_item.line_total are stored for reporting and performance. They can be derived from line items but are kept to avoid expensive aggregation on every invoice query.
- appointment_service.unit_price is stored to preserve historical pricing even if service.base_price changes later.
