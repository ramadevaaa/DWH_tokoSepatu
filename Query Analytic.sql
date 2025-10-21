-- ============================================================================
-- ANALYTICAL QUERIES & VALIDATION
-- Data Warehouse: Toko Sepatu
-- Purpose: Business Intelligence & Data Quality Validation
-- ============================================================================

-- ============================================================================
-- PART 1: DATA QUALITY VALIDATION QUERIES
-- ============================================================================

-- Query 1: Record Count Summary per Table
SELECT 
    '=== RECORD COUNT SUMMARY ===' AS report_section;

SELECT * FROM dwh.v_etl_summary ORDER BY table_name;

-- Query 2: Date Range Coverage
SELECT 
    '=== DATE RANGE COVERAGE ===' AS report_section;

SELECT 
    'Penjualan' AS transaction_type,
    MIN(dw.tanggal) AS earliest_date,
    MAX(dw.tanggal) AS latest_date,
    COUNT(DISTINCT dw.tanggal) AS total_days,
    COUNT(*) AS total_transactions
FROM dwh.fact_penjualan fp
JOIN dwh.dim_waktu dw ON fp.waktu_key = dw.waktu_key
UNION ALL
SELECT 
    'Pembelian',
    MIN(dw.tanggal),
    MAX(dw.tanggal),
    COUNT(DISTINCT dw.tanggal),
    COUNT(*)
FROM dwh.fact_pembelian fpb
JOIN dwh.dim_waktu dw ON fpb.waktu_key = dw.waktu_key;

-- Query 3: Check for Negative Values
SELECT 
    '=== NEGATIVE VALUES CHECK ===' AS report_section;

SELECT 
    'Penjualan - Negative Profit' AS check_name,
    COUNT(*) AS count,
    ROUND(SUM(total_profit), 2) AS total_amount
FROM dwh.fact_penjualan
WHERE total_profit < 0
UNION ALL
SELECT 
    'Penjualan - Zero Quantity',
    COUNT(*),
    0
FROM dwh.fact_penjualan
WHERE jumlah_qty <= 0
UNION ALL
SELECT 
    'Pembelian - Zero Quantity',
    COUNT(*),
    0
FROM dwh.fact_pembelian
WHERE jumlah_qty <= 0;

-- Query 4: Referential Integrity Check
SELECT 
    '=== REFERENTIAL INTEGRITY ===' AS report_section;

SELECT 
    'fact_penjualan - orphaned produk_key' AS check_name,
    COUNT(*) AS orphan_count
FROM dwh.fact_penjualan fp
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.dim_produk dp WHERE dp.produk_key = fp.produk_key
)
UNION ALL
SELECT 
    'fact_penjualan - orphaned pelanggan_key',
    COUNT(*)
FROM dwh.fact_penjualan fp
WHERE pelanggan_key IS NOT NULL 
  AND NOT EXISTS (
    SELECT 1 FROM dwh.dim_pelanggan WHERE pelanggan_key = fp.pelanggan_key
)
UNION ALL
SELECT 
    'fact_pembelian - orphaned supplier_key',
    COUNT(*)
FROM dwh.fact_pembelian fpb
WHERE supplier_key IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM dwh.dim_supplier WHERE supplier_key = fpb.supplier_key
);

-- Query 5: Duplicate Detection
SELECT 
    '=== DUPLICATE DETECTION ===' AS report_section;

SELECT 
    'fact_penjualan duplicates' AS check_name,
    COUNT(*) AS duplicate_count
FROM (
    SELECT detail_penjualan_id, COUNT(*) AS cnt
    FROM dwh.fact_penjualan
    GROUP BY detail_penjualan_id
    HAVING COUNT(*) > 1
) dup
UNION ALL
SELECT 
    'fact_pembelian duplicates',
    COUNT(*)
FROM (
    SELECT detail_pembelian_id, COUNT(*) AS cnt
    FROM dwh.fact_pembelian
    GROUP BY detail_pembelian_id
    HAVING COUNT(*) > 1
) dup;

-- ============================================================================
-- PART 2: BUSINESS INTELLIGENCE QUERIES
-- ============================================================================

-- Query 6: Monthly Sales Performance (Revenue & Profit)
SELECT 
    '=== MONTHLY SALES PERFORMANCE ===' AS report_section;

SELECT 
    dw.tahun,
    dw.bulan,
    dw.nama_bulan,
    COUNT(DISTINCT fp.penjualan_id) AS total_transaksi,
    SUM(fp.jumlah_qty) AS total_qty_terjual,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_hpp), 2) AS total_hpp,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.profit_margin_persen), 2) AS avg_margin_persen,
    ROUND(SUM(fp.subtotal_penjualan) / COUNT(DISTINCT fp.penjualan_id), 2) AS avg_transaction_value
FROM dwh.fact_penjualan fp
JOIN dwh.dim_waktu dw ON fp.waktu_key = dw.waktu_key
WHERE dw.tahun = 2024
GROUP BY dw.tahun, dw.bulan, dw.nama_bulan
ORDER BY dw.tahun, dw.bulan;

-- Query 7: Top 10 Best Selling Products
SELECT 
    '=== TOP 10 BEST SELLING PRODUCTS ===' AS report_section;

SELECT 
    dp.kode_produk,
    dp.nama_produk,
    dk.nama_kategori,
    dp.warna,
    SUM(fp.jumlah_qty) AS total_qty_sold,
    COUNT(DISTINCT fp.penjualan_id) AS times_purchased,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.profit_margin_persen), 2) AS avg_margin_persen
FROM dwh.fact_penjualan fp
JOIN dwh.dim_produk dp ON fp.produk_key = dp.produk_key
JOIN dwh.dim_kategori dk ON dp.kategori_key = dk.kategori_key
GROUP BY dp.kode_produk, dp.nama_produk, dk.nama_kategori, dp.warna
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 8: Sales by Category
SELECT 
    '=== SALES BY CATEGORY ===' AS report_section;

SELECT 
    dk.nama_kategori,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.profit_margin_persen), 2) AS avg_margin_persen,
    ROUND(SUM(fp.subtotal_penjualan) * 100.0 / 
        (SELECT SUM(subtotal_penjualan) FROM dwh.fact_penjualan), 2) AS revenue_contribution_pct
FROM dwh.fact_penjualan fp
JOIN dwh.dim_produk dp ON fp.produk_key = dp.produk_key
JOIN dwh.dim_kategori dk ON dp.kategori_key = dk.kategori_key
GROUP BY dk.nama_kategori
ORDER BY total_revenue DESC;

-- Query 9: Sales by Store (Toko)
SELECT 
    '=== SALES BY STORE ===' AS report_section;

SELECT 
    dt.kode_toko,
    dt.nama_toko,
    dt.kota,
    dt.provinsi,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.harga_jual_satuan), 2) AS avg_selling_price
FROM dwh.fact_penjualan fp
JOIN dwh.dim_toko dt ON fp.toko_key = dt.toko_key
WHERE dt.is_current = TRUE
GROUP BY dt.kode_toko, dt.nama_toko, dt.kota, dt.provinsi
ORDER BY total_revenue DESC;

-- Query 10: Customer Segmentation Analysis
SELECT 
    '=== CUSTOMER SEGMENTATION ===' AS report_section;

SELECT 
    dpl.segment_pelanggan,
    dpl.jenis_kelamin,
    COUNT(DISTINCT dpl.pelanggan_key) AS total_customers,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(AVG(fp.subtotal_penjualan), 2) AS avg_transaction_value,
    ROUND(SUM(fp.subtotal_penjualan) / COUNT(DISTINCT dpl.pelanggan_key), 2) AS revenue_per_customer
FROM dwh.fact_penjualan fp
JOIN dwh.dim_pelanggan dpl ON fp.pelanggan_key = dpl.pelanggan_key
WHERE dpl.is_current = TRUE
GROUP BY dpl.segment_pelanggan, dpl.jenis_kelamin
ORDER BY total_revenue DESC;

-- Query 11: Sales by City (Geographic Analysis)
SELECT 
    '=== SALES BY CUSTOMER CITY ===' AS report_section;

SELECT 
    dpl.provinsi,
    dpl.kota,
    COUNT(DISTINCT dpl.pelanggan_key) AS total_customers,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.subtotal_penjualan), 2) AS avg_transaction_value
FROM dwh.fact_penjualan fp
JOIN dwh.dim_pelanggan dpl ON fp.pelanggan_key = dpl.pelanggan_key
WHERE dpl.is_current = TRUE
GROUP BY dpl.provinsi, dpl.kota
ORDER BY total_revenue DESC
LIMIT 15;

-- Query 12: Employee Performance (Sales by Pegawai)
SELECT 
    '=== EMPLOYEE SALES PERFORMANCE ===' AS report_section;

SELECT 
    dpg.nama_pegawai,
    dpg.jabatan,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty_sold,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.subtotal_penjualan), 2) AS avg_transaction_value,
    ROUND(SUM(fp.subtotal_penjualan) / NULLIF(COUNT(DISTINCT dw.tanggal), 0), 2) AS avg_daily_sales
FROM dwh.fact_penjualan fp
JOIN dwh.dim_pegawai dpg ON fp.pegawai_key = dpg.pegawai_key
JOIN dwh.dim_waktu dw ON fp.waktu_key = dw.waktu_key
WHERE dpg.is_current = TRUE
GROUP BY dpg.nama_pegawai, dpg.jabatan
ORDER BY total_revenue DESC;

-- Query 13: Payment Method Analysis
SELECT 
    '=== PAYMENT METHOD ANALYSIS ===' AS report_section;

SELECT 
    dm.nama_metode,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(AVG(fp.subtotal_penjualan), 2) AS avg_transaction_value,
    ROUND(SUM(fp.subtotal_penjualan) * 100.0 / 
        (SELECT SUM(subtotal_penjualan) FROM dwh.fact_penjualan), 2) AS revenue_share_pct
FROM dwh.fact_penjualan fp
JOIN dwh.dim_metode_pembayaran dm ON fp.metode_key = dm.metode_key
GROUP BY dm.nama_metode
ORDER BY total_revenue DESC;

-- Query 14: Product Size Analysis
SELECT 
    '=== PRODUCT SIZE POPULARITY ===' AS report_section;

SELECT 
    fp.ukuran,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty_sold,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(AVG(fp.harga_jual_satuan), 2) AS avg_price,
    ROUND(SUM(fp.jumlah_qty) * 100.0 / 
        (SELECT SUM(jumlah_qty) FROM dwh.fact_penjualan), 2) AS qty_share_pct
FROM dwh.fact_penjualan fp
GROUP BY fp.ukuran
ORDER BY fp.ukuran;

-- Query 15: Quarterly Performance Comparison
SELECT 
    '=== QUARTERLY PERFORMANCE ===' AS report_section;

SELECT 
    dw.tahun,
    dw.kuartal,
    dw.nama_kuartal,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.profit_margin_persen), 2) AS avg_margin_persen,
    -- YoY Growth (if previous year data exists)
    ROUND(
        (SUM(fp.subtotal_penjualan) - 
         LAG(SUM(fp.subtotal_penjualan)) OVER (PARTITION BY dw.kuartal ORDER BY dw.tahun))
        / NULLIF(LAG(SUM(fp.subtotal_penjualan)) OVER (PARTITION BY dw.kuartal ORDER BY dw.tahun), 0) 
        * 100, 2
    ) AS yoy_growth_pct
FROM dwh.fact_penjualan fp
JOIN dwh.dim_waktu dw ON fp.waktu_key = dw.waktu_key
GROUP BY dw.tahun, dw.kuartal, dw.nama_kuartal
ORDER BY dw.tahun, dw.kuartal;

-- Query 16: Weekday vs Weekend Sales
SELECT 
    '=== WEEKDAY VS WEEKEND ANALYSIS ===' AS report_section;

SELECT 
    CASE WHEN dw.is_akhir_pekan THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(AVG(fp.subtotal_penjualan), 2) AS avg_transaction_value,
    ROUND(SUM(fp.total_profit), 2) AS total_profit
FROM dwh.fact_penjualan fp
JOIN dwh.dim_waktu dw ON fp.waktu_key = dw.waktu_key
GROUP BY dw.is_akhir_pekan
ORDER BY day_type;

-- Query 17: Supplier Performance Analysis
SELECT 
    '=== SUPPLIER PERFORMANCE ===' AS report_section;

SELECT 
    ds.nama_supplier,
    ds.kota,
    ds.rating_supplier,
    COUNT(DISTINCT fpb.pembelian_id) AS total_purchases,
    SUM(fpb.jumlah_qty) AS total_qty_purchased,
    ROUND(SUM(fpb.subtotal_pembelian), 2) AS total_purchase_value,
    ROUND(AVG(fpb.harga_beli_satuan), 2) AS avg_purchase_price,
    COUNT(DISTINCT dp.produk_key) AS unique_products_supplied
FROM dwh.fact_pembelian fpb
JOIN dwh.dim_supplier ds ON fpb.supplier_key = ds.supplier_key
JOIN dwh.dim_produk dp ON fpb.produk_key = dp.produk_key
GROUP BY ds.nama_supplier, ds.kota, ds.rating_supplier
ORDER BY total_purchase_value DESC;

-- Query 18: Inventory Turnover Analysis (Pembelian vs Penjualan)
SELECT 
    '=== INVENTORY TURNOVER ANALYSIS ===' AS report_section;

SELECT 
    dp.kode_produk,
    dp.nama_produk,
    dk.nama_kategori,
    COALESCE(pembelian.total_qty_beli, 0) AS qty_purchased,
    COALESCE(penjualan.total_qty_jual, 0) AS qty_sold,
    COALESCE(pembelian.total_qty_beli, 0) - COALESCE(penjualan.total_qty_jual, 0) AS estimated_stock,
    CASE 
        WHEN COALESCE(pembelian.total_qty_beli, 0) > 0 
        THEN ROUND(COALESCE(penjualan.total_qty_jual, 0) * 100.0 / pembelian.total_qty_beli, 2)
        ELSE 0 
    END AS turnover_rate_pct,
    ROUND(COALESCE(penjualan.total_revenue, 0), 2) AS total_revenue,
    ROUND(COALESCE(penjualan.total_profit, 0), 2) AS total_profit
FROM dwh.dim_produk dp
JOIN dwh.dim_kategori dk ON dp.kategori_key = dk.kategori_key
LEFT JOIN (
    SELECT 
        produk_key,
        SUM(jumlah_qty) AS total_qty_beli
    FROM dwh.fact_pembelian
    GROUP BY produk_key
) pembelian ON dp.produk_key = pembelian.produk_key
LEFT JOIN (
    SELECT 
        produk_key,
        SUM(jumlah_qty) AS total_qty_jual,
        SUM(subtotal_penjualan) AS total_revenue,
        SUM(total_profit) AS total_profit
    FROM dwh.fact_penjualan
    GROUP BY produk_key
) penjualan ON dp.produk_key = penjualan.produk_key
WHERE dp.is_current = TRUE
ORDER BY turnover_rate_pct DESC
LIMIT 20;

-- Query 19: Discount Impact Analysis
SELECT 
    '=== DISCOUNT IMPACT ANALYSIS ===' AS report_section;

SELECT 
    CASE 
        WHEN fp.diskon_item = 0 THEN 'No Discount'
        WHEN fp.diskon_item <= 10000 THEN 'Low Discount (<=10K)'
        WHEN fp.diskon_item <= 20000 THEN 'Medium Discount (10K-20K)'
        ELSE 'High Discount (>20K)'
    END AS discount_category,
    COUNT(DISTINCT fp.penjualan_id) AS total_transactions,
    SUM(fp.jumlah_qty) AS total_qty,
    ROUND(SUM(fp.diskon_item), 2) AS total_discount_given,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.profit_margin_persen), 2) AS avg_margin_pct
FROM dwh.fact_penjualan fp
GROUP BY 
    CASE 
        WHEN fp.diskon_item = 0 THEN 'No Discount'
        WHEN fp.diskon_item <= 10000 THEN 'Low Discount (<=10K)'
        WHEN fp.diskon_item <= 20000 THEN 'Medium Discount (10K-20K)'
        ELSE 'High Discount (>20K)'
    END
ORDER BY total_revenue DESC;

-- Query 20: Product Profitability Matrix
SELECT 
    '=== PRODUCT PROFITABILITY MATRIX ===' AS report_section;

SELECT 
    dp.kode_produk,
    dp.nama_produk,
    dk.nama_kategori,
    SUM(fp.jumlah_qty) AS qty_sold,
    ROUND(SUM(fp.subtotal_penjualan), 2) AS total_revenue,
    ROUND(SUM(fp.total_profit), 2) AS total_profit,
    ROUND(AVG(fp.profit_margin_persen), 2) AS avg_margin_pct,
    CASE 
        WHEN SUM(fp.subtotal_penjualan) > (SELECT AVG(revenue) FROM (
            SELECT SUM(subtotal_penjualan) AS revenue 
            FROM dwh.fact_penjualan 
            GROUP BY produk_key
        ) x) 
        AND AVG(fp.profit_margin_persen) > (SELECT AVG(profit_margin_persen) FROM dwh.fact_penjualan)
        THEN 'Star Product'
        
        WHEN SUM(fp.subtotal_penjualan) > (SELECT AVG(revenue) FROM (
            SELECT SUM(subtotal_penjualan) AS revenue 
            FROM dwh.fact_penjualan 
            GROUP BY produk_key
        ) x) 
        THEN 'Cash Cow'
        
        WHEN AVG(fp.profit_margin_persen) > (SELECT AVG(profit_margin_persen) FROM dwh.fact_penjualan)
        THEN 'Niche Product'
        
        ELSE 'Dog Product'
    END AS product_category
FROM dwh.fact_penjualan fp
JOIN dwh.dim_produk dp ON fp.produk_key = dp.produk_key
JOIN dwh.dim_kategori dk ON dp.kategori_key = dk.kategori_key
WHERE dp.is_current = TRUE
GROUP BY dp.kode_produk, dp.nama_produk, dk.nama_kategori
ORDER BY total_profit DESC
LIMIT 20;

-- ============================================================================
-- FINAL SUMMARY REPORT
-- ============================================================================

SELECT 
    '=== EXECUTIVE SUMMARY ===' AS report_section;

SELECT 
    'Total Penjualan' AS metric,
    ROUND(SUM(subtotal_penjualan), 2)::TEXT AS value,
    'IDR' AS unit
FROM dwh.fact_penjualan
UNION ALL
SELECT 
    'Total Profit',
    ROUND(SUM(total_profit), 2)::TEXT,
    'IDR'
FROM dwh.fact_penjualan
UNION ALL
SELECT 
    'Average Margin',
    ROUND(AVG(profit_margin_persen), 2)::TEXT,
    '%'
FROM dwh.fact_penjualan
UNION ALL
SELECT 
    'Total Transactions',
    COUNT(DISTINCT penjualan_id)::TEXT,
    'transaksi'
FROM dwh.fact_penjualan
UNION ALL
SELECT 
    'Total Customers',
    COUNT(DISTINCT pelanggan_key)::TEXT,
    'pelanggan'
FROM dwh.fact_penjualan
UNION ALL
SELECT 
    'Total Products Sold',
    SUM(jumlah_qty)::TEXT,
    'unit'
FROM dwh.fact_penjualan
UNION ALL
SELECT 
    'Average Transaction Value',
    ROUND(AVG(subtotal_penjualan), 2)::TEXT,
    'IDR'
FROM dwh.fact_penjualan;

SELECT 'ETL & Analytics Validation Completed!' AS status;