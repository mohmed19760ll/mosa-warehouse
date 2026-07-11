-- silver layer stored procedure

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME ,@end_time DATETIME,@batch_start_time DATETIME, @batch_end_time DATETIME

    BEGIN TRY
     SET @batch_start_time = GETDATE();

     	PRINT '========================================';
		PRINT 'Loading silver Layer';
		PRINT '========================================';

		PRINT '----------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------------------';

        --Trunc & Insert silver.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info'
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting data into: silver.crm_cust_info'
        INSERT INTO silver.crm_cust_info(
                    cst_id,
                    cst_key,
                    cst_firstname,
                    cst_lastname,
                    cst_marital_status,
                    cst_gndr,
                    cst_create_date)
        SELECT 
                cst_id,
                cst_key,
                TRIM(cst_firstname) cst_fistname,
                TRIM(cst_lastname) cst_lastname,
            CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                 ELSE 'n/a'
            END cst_marital_status,
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                 ELSE 'n/a'
            END cst_gndr,
                cst_create_date
        FROM (
            SELECT 
                *,
                ROW_NUMBER() OVER( PARTITION BY cst_id ORDER BY cst_create_date DESC) dup_flag
                FROM Bronze.crm_cust_info
                WHERE cst_id is NOT NULL
              )t 
        WHERE dup_flag = 1 ;

    SET @end_time = GETDATE()
    PRINT '-----------------------------------'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
    PRINT '-----------------------------------'

        ---------------------------------------------------------------------------------------

        SET @start_time = GETDATE();

        --Trunc & Insert silver.crm_prd_info

        PRINT '>> Truncating Table: silver.crm_prd_info'
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting data into: silver.crm_prd_info'
        INSERT INTO silver.crm_prd_info(
								        prd_id,
								        cat_id,
								        prd_key,
								        prd_nm,
								        prd_cost,
								        prd_line,
								        prd_start_dt,
								        prd_end_dt)
        SELECT 
	        prd_id,
	        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, -- Extract Category ID
	        SUBSTRING(prd_KEY,7,LEN(prd_key)) AS prd_key,     --Extract Product Key
	        prd_nm,
	        ISNULL(prd_cost,0) AS prd_cost, --NULL Handling
        CASE UPPER(TRIM(prd_line))
	        WHEN  'M' THEN 'Mountain'
	        WHEN  'R' THEN 'Road'
	        WHEN  'S' THEN 'Other Sales'
	        WHEN  'T' THEN 'Touring'
	        ELSE 'n/a'                 --Data Normalize
        END prd_line,
	        prd_start_dt,
            DATEADD(DAY,-1,LEAD(prd_start_dt,1) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) prd_end_dt   --DATA Enrichment
        FROM Bronze.crm_prd_info  ;

    SET @end_time = GETDATE()
    PRINT '-----------------------------------'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
    PRINT '-----------------------------------'

        ---------------------------------------------------------------------------------------

        SET @start_time = GETDATE();

        --Trunc & Insert silver.crm_sales_details

        PRINT '>> Truncating Table: silver.crm_sales_details'
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting data into: silver.crm_sales_details'
        INSERT INTO silver.crm_sales_details(
                                             sls_ord_num,
                                             sls_prd_key,
                                             sls_cust_id,
                                             sls_order_dt,
                                             sls_ship_dt,
                                             sls_due_dt,
                                             sls_sales,
                                             sls_quantity,
                                             sls_price)

        SELECT 
	        sls_ord_num,
	        sls_prd_key,
	        sls_cust_id,
        CASE 
             WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
             ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
        END sls_order_dt,
        CASE 
             WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
             ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
        END sls_ship_dt,
        CASE 
             WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
             ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
        END sls_due_dt,
	        CASE 
             WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
             THEN  sls_quantity * ABS(sls_price)
             ELSE sls_sales
        END AS sls_sales,
	        sls_quantity,
        CASE WHEN sls_price IS NULL OR sls_price <= 0 
             THEN sls_sales / NULLIF(sls_quantity,0)
              ELSE sls_price
        END AS sls_price
        FROM Bronze.crm_sales_details  ;

    SET @end_time = GETDATE()
    PRINT '-----------------------------------'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
    PRINT '-----------------------------------'

        ---------------------------------------------------------------------------------------

        PRINT '----------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------------------';

        SET @start_time = GETDATE();

        --Trunc & Insert silver.erp_cust_az12

        PRINT '>> Truncating Table: silver.erp_cust_az12'
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting data into: silver.erp_cust_az12'
        INSERT INTO silver.erp_cust_az12(
                                         cid,
                                         bdate,
                                         gen)


        SELECT 
        CASE 
             WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
             ELSE cid
        END cid,
        CASE 
             WHEN bdate > GETDATE() THEN NULL
             ELSE bdate 
        END bdate,
        CASE 
            WHEN  UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
            WHEN  UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
            ELSE 'n/a'
        END gen
        FROM Bronze.erp_CUST_AZ12  ;

    SET @end_time = GETDATE()
    PRINT '-----------------------------------'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
    PRINT '-----------------------------------'

        ---------------------------------------------------------------------------------------
        SET @start_time = GETDATE();

        --Trunc & Insert silver.erp_loc_a101

        PRINT '>> Truncating Table: silver.erp_loc_a101'
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting data into: silver.erp_loc_a101'
        INSERT INTO silver.erp_loc_a101 (
                                         cid,
                                         cntry)


        SELECT 
        REPLACE(cid,'-','') cid,             
        CASE 
            WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
            WHEN UPPER(TRIM(cntry)) IN ('DE','GERMANY') THEN 'Germany'                           
            WHEN UPPER(TRIM(cntry)) IS NULL OR UPPER(TRIM(cntry)) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END cntry
        FROM Bronze.erp_LOC_A101  ;

    SET @end_time = GETDATE()
    PRINT '-----------------------------------'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
    PRINT '-----------------------------------'

        ---------------------------------------------------------------------------------------
        SET @start_time = GETDATE();

        --Trunc & Insert silver.erp_px_cat_g1v2

        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting data into: silver.erp_px_cat_g1v2'
        INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)

        SELECT 
        id,
        cat,                           
        subcat,
        maintenance
        FROM Bronze.erp_PX_CAT_G1V2  ;

    SET @end_time = GETDATE()
    PRINT '-----------------------------------'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'
    PRINT '-----------------------------------'

    -------------------------------------------------------------------------------------------------

    SET @batch_end_time = GETDATE()
    PRINT '==================================='
    PRINT 'Silver Layer completed'
    PRINT '>> Load duration ' + CAST (DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds'
    PRINT '==================================='
    END TRY
    BEGIN CATCH
          PRINT '=================================================';
          PRINT 'ERROR OCCURED';
          PRINT 'ERROR MESSAGE ' + ERROR_MESSAGE();
          PRINT 'ERROR NUMBER ' + CAST(ERROR_NUMBER() AS NVARCHAR);
          PRINT 'ERROR STATE ' + CAST(ERROR_STATE() AS NVARCHAR);
          PRINT '=================================================';
    END CATCH
END
