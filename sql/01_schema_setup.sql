-- ======================================================================================
-- PROJECT: Consumer Complaint Intelligence (CFPB)
-- FILE: 01_schema_setup.sql
-- PURPOSE: Database Schema Setup, Table DDL, Constraints, and Indexes
-- ======================================================================================

-- 1. Create Analytics Schema / Database Namespace
CREATE SCHEMA IF NOT EXISTS cfpb_analytics;

-- 2. Create Relational Table Structure
DROP TABLE IF EXISTS cfpb_analytics.complaints;

CREATE TABLE cfpb_analytics.complaints (
    complaint_id                  BIGINT PRIMARY KEY,
    date_received                 DATE NOT NULL,
    product                       VARCHAR(150) NOT NULL,
    sub_product                   VARCHAR(150),
    issue                         VARCHAR(250) NOT NULL,
    sub_issue                     VARCHAR(250),
    company_public_response       VARCHAR(255),
    company                       VARCHAR(200) NOT NULL,
    state                         VARCHAR(50),
    zip_code                      VARCHAR(20),
    tags                          VARCHAR(100),
    submitted_via                 VARCHAR(50) NOT NULL,
    date_sent_to_company          DATE,
    company_response_to_consumer  VARCHAR(150),
    timely_response               VARCHAR(10) CHECK (timely_response IN ('Yes', 'No', 'Unknown')),
    year                          SMALLINT NOT NULL,
    month                         SMALLINT NOT NULL,
    quarter                       SMALLINT NOT NULL,
    day_of_week                   VARCHAR(20) NOT NULL,
    response_days                 INTEGER DEFAULT 0
);

-- ======================================================================================
-- 3. Analytical Indexing for High-Performance Queries
-- ======================================================================================

CREATE INDEX IF NOT EXISTS idx_complaints_date_received 
ON cfpb_analytics.complaints(date_received);

CREATE INDEX IF NOT EXISTS idx_complaints_product 
ON cfpb_analytics.complaints(product);

CREATE INDEX IF NOT EXISTS idx_complaints_company 
ON cfpb_analytics.complaints(company);

CREATE INDEX IF NOT EXISTS idx_complaints_year_month 
ON cfpb_analytics.complaints(year, month);
