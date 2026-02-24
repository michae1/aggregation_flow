USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS survey_agg_demo;
USE DATABASE survey_agg_demo;
CREATE SCHEMA IF NOT EXISTS survey_agg;
USE SCHEMA survey_agg;

CREATE OR REPLACE TABLE surveys_raw (
  id           VARCHAR(64) NOT NULL,
  geo_point    GEOGRAPHY NOT NULL,
  sector       VARCHAR(64) NOT NULL,
  brand_id     VARCHAR(64) NOT NULL,
  response_score NUMBER(5,2) NOT NULL,
  response_date DATE NOT NULL,
  loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (id)
);

CREATE OR REPLACE TABLE brands_raw (
  id   VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  PRIMARY KEY (id)
);
