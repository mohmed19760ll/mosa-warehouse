/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None.
	This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
--Stored procedure creation

CREATE OR ALTER PROCEDURE Bronze.load_bronze AS   
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME,@batch_start_time DATETIME, @batch_end_time DATETIME
	
	BEGIN TRY
	SET @batch_start_time = GETDATE();

		PRINT '========================================';
		PRINT 'Loading Bronze Layer';
		PRINT '========================================';

		PRINT '----------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------------------';

	SET @start_time = GETDATE();

			--TRUNC & INSERT Bronze.crm_cust_info
		PRINT '>>Truncating table : Bronze.crm_cust_info';

			TRUNCATE TABLE Bronze.crm_cust_info;

		PRINT '>>Inserting data into : Bronze.crm_cust_info';

			BULK INSERT Bronze.crm_cust_info
			FROM 'C:\Users\mahamud ali\Documents\SQL Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
			WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);

	SET @end_time = GETDATE();
	PRINT '---------------------------------'
	PRINT '>> Load Duration: ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ ' seconds';
	PRINT '---------------------------------'
		
		
	SET @start_time = GETDATE();

			--TRUNC & INSERT Bronze.crm_prd_info
		PRINT '>>Truncating table : Bronze.crm_prd_info';

			TRUNCATE TABLE Bronze.crm_prd_info;

		PRINT '>>Inserting data into : Bronze.crm_prd_info';

			BULK INSERT Bronze.crm_prd_info
			FROM 'C:\Users\mahamud ali\Documents\SQL Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
			WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);

	SET @end_time = GETDATE();
	PRINT '---------------------------------'
	PRINT '>> Load Duration: ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ ' seconds';
	PRINT '---------------------------------'


	SET @start_time = GETDATE();
		
			--TRUNC & INSERT Bronze.crm_sales_details
		PRINT '>>Truncating table : Bronze.crm_sales_details';

			TRUNCATE TABLE Bronze.crm_sales_details;

		PRINT '>>Inserting data into : Bronze.crm_sales_details';

			BULK INSERT Bronze.crm_sales_details
			FROM 'C:\Users\mahamud ali\Documents\SQL Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
			WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);

	SET @end_time = GETDATE();
	PRINT '---------------------------------'
	PRINT '>> Load Duration: ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ ' seconds';
	PRINT '---------------------------------'


		PRINT '----------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------------------';

	
	SET @start_time = GETDATE();

			--TRUNC & INSERT Bronze.erp_CUST_AZ12
		PRINT '>>Truncating table : Bronze.erp_CUST_AZ12';

			TRUNCATE TABLE Bronze.erp_CUST_AZ12;

		PRINT '>>Inserting data into : Bronze.erp_CUST_AZ12';

			BULK INSERT Bronze.erp_CUST_AZ12
			FROM 'C:\Users\mahamud ali\Documents\SQL Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
			WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);

	SET @end_time = GETDATE();
	PRINT '---------------------------------'
	PRINT '>> Load Duration: ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ ' seconds';
	PRINT '---------------------------------'



	SET @start_time = GETDATE();


			--TRUNC & INSERT Bronze.erp_LOC_A101
		PRINT '>>Truncating table : Bronze.erp_LOC_A101';

			TRUNCATE TABLE Bronze.erp_LOC_A101;

		PRINT '>>Inserting data into : Bronze.erp_LOC_A101';

			BULK INSERT Bronze.erp_LOC_A101
			FROM 'C:\Users\mahamud ali\Documents\SQL Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
			WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);

	SET @end_time = GETDATE();
	PRINT '---------------------------------'
	PRINT '>> Load Duration: ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ ' seconds';
	PRINT '---------------------------------'
	

	SET @start_time = GETDATE();

			--TRUNC & INSERT Bronze.erp_PX_CAT_G1V2
		PRINT '>>Truncating table : Bronze.erp_PX_CAT_G1V2';

			TRUNCATE TABLE Bronze.erp_PX_CAT_G1V2;

		PRINT '>>Inserting data into : Bronze.erp_PX_CAT_G1V2';

			BULK INSERT Bronze.erp_PX_CAT_G1V2
			FROM 'C:\Users\mahamud ali\Documents\SQL Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
			WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			);
	
	SET @end_time = GETDATE();
	PRINT '---------------------------------'
	PRINT '>> Load Duration: ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ ' seconds';
	PRINT '---------------------------------'
	
	SET @batch_end_time = GETDATE();
	PRINT '::::::::::::::::::::::::::::::::::::::::::::'
	PRINT 'Bronze layer completed'
	PRINT '>> Total Load Duration: ' + CAST (DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR)+ ' seconds';
	PRINT '::::::::::::::::::::::::::::::::::::::::::::'

	END TRY 
	BEGIN CATCH
		PRINT '===============================';
		PRINT 'ERROR OCCURED';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '===============================';
	END CATCH

	

END
