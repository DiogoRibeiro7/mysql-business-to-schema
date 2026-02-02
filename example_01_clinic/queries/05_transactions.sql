-- Transactions: invoice + payment insertion with rollback example

-- 1) Start a transaction (expect: new transaction context)
START TRANSACTION;

-- 2) Create a new invoice (expect: new invoice row)
INSERT INTO invoices (patient_id, invoice_number, issued_at, status, total_amount)
VALUES (1, 'INV-2025-9999', NOW(), 'open', 120.00);

-- 3) Add invoice items (expect: 2 line items)
INSERT INTO invoice_items (invoice_id, appointment_id, description, quantity, unit_price, line_total)
VALUES
  (LAST_INSERT_ID(), 1, 'Consultation #1', 1, 70.00, 70.00),
  (LAST_INSERT_ID(), 2, 'Consultation #2', 1, 50.00, 50.00);

-- 4) Commit the invoice (expect: invoice + items persisted)
COMMIT;

-- 5) Start a payment transaction (expect: new transaction context)
START TRANSACTION;

-- 6) Insert a payment (expect: payment row)
INSERT INTO payments (patient_id, payment_date, method, reference, amount)
VALUES (1, NOW(), 'card', 'PAY-99999', 60.00);

-- 7) Allocate payment (expect: allocation row)
INSERT INTO payment_allocations (payment_id, invoice_id, amount_applied)
VALUES (LAST_INSERT_ID(), 1, 60.00);

-- 8) Commit the payment (expect: payment + allocation persisted)
COMMIT;

-- 9) Rollback example: bad allocation (expect: no rows inserted)
START TRANSACTION;
INSERT INTO payments (patient_id, payment_date, method, reference, amount)
VALUES (2, NOW(), 'cash', 'PAY-ROLLBACK', 20.00);
INSERT INTO payment_allocations (payment_id, invoice_id, amount_applied)
VALUES (LAST_INSERT_ID(), 2, 9999.00);
ROLLBACK;
