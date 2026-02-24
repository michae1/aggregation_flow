-- Master deployment script. Run with SnowSQL/SnowCLI to build the stack.
USE ROLE ACCOUNTADMIN;
USE DATABASE survey_agg_demo;
USE SCHEMA survey_agg;

!source sql/01_bronze.sql
!source sql/02_silver.sql
!source sql/03_gold.sql
!source sql/04_mapping.sql
!source sql/05_rap.sql
!source sql/06_task.sql
!source sql/07_test_proc.sql
