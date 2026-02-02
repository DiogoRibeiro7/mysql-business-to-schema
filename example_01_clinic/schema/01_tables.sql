-- Tables
CREATE TABLE IF NOT EXISTS patients (
  patient_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nif VARCHAR(32) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NOT NULL,
  phone VARCHAR(40) NOT NULL,
  email VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (patient_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS doctors (
  doctor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  license_number VARCHAR(64) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(40) NOT NULL,
  active_from DATE NOT NULL,
  active_to DATE NULL,
  PRIMARY KEY (doctor_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS specialties (
  specialty_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(32) NOT NULL,
  name VARCHAR(120) NOT NULL,
  description VARCHAR(500) NULL,
  PRIMARY KEY (specialty_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS doctor_specialties (
  doctor_id BIGINT UNSIGNED NOT NULL,
  specialty_id BIGINT UNSIGNED NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (doctor_id, specialty_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS appointments (
  appointment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  patient_id BIGINT UNSIGNED NOT NULL,
  doctor_id BIGINT UNSIGNED NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  status ENUM('scheduled','completed','cancelled','no_show') NOT NULL,
  cancel_reason VARCHAR(255) NULL,
  no_show_reason VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (appointment_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoices (
  invoice_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  patient_id BIGINT UNSIGNED NOT NULL,
  invoice_number VARCHAR(40) NOT NULL,
  issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('open','partially_paid','paid','void') NOT NULL DEFAULT 'open',
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (invoice_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoice_items (
  invoice_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  invoice_id BIGINT UNSIGNED NOT NULL,
  appointment_id BIGINT UNSIGNED NULL,
  description VARCHAR(255) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  line_total DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (invoice_item_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  patient_id BIGINT UNSIGNED NOT NULL,
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  method ENUM('cash','card','transfer','other') NOT NULL,
  reference VARCHAR(100) NULL,
  amount DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (payment_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_allocations (
  payment_allocation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payment_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  amount_applied DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (payment_allocation_id)
) ENGINE=InnoDB;
