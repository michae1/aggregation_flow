USE DATABASE IMPRESSIONS_DB;
USE SCHEMA BRONZE;

-- DDL for raw tables
CREATE OR REPLACE TABLE impressions_raw (
  id           VARCHAR(64) NOT NULL,
  geo_point    GEOGRAPHY NOT NULL,
  category     VARCHAR(64) NOT NULL,
  site_id      VARCHAR(64) NOT NULL,
  view_count   NUMBER(10,0) NOT NULL,
  event_date   DATE NOT NULL,
  loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (id)
);

CREATE OR REPLACE TABLE sites_raw (
  id   VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  PRIMARY KEY (id)
);
