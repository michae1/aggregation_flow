-- Master deployment script. Run with SnowSQL/SnowCLI to build the stack.
USE DATABASE SURVEY_DB;

!source sql/01_bronze.sql
!source sql/02_silver.sql
!source sql/03_gold.sql
!source sql/04_mapping.sql
!source sql/05_rap.sql
!source sql/07_test_proc.sql
