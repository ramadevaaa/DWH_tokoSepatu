CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER src_toko_sepatu
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'toko_sepatu', port '5432');
CREATE USER MAPPING FOR CURRENT_USER
SERVER src_toko_sepatu
OPTIONS (user 'postgres', password '12345678');
IMPORT FOREIGN SCHEMA public
FROM SERVER src_toko_sepatu INTO staging;
SELECT COUNT(*) FROM staging.produk;
SELECT COUNT(*) FROM staging.pelanggan;
SELECT * FROM staging.penjualan LIMIT 5;


SET search_path TO dwh, staging;

-- =====================================
-- FIX STRUKTUR DWH
-- =====================================
ALTER TABLE dwh.dim_produk ADD COLUMN IF NOT EXISTS warna VARCHAR(50);
ALTER TABLE dwh.dim_produk ADD COLUMN IF NOT EXISTS kode_produk VARCHAR(20);
ALTER TABLE dwh.dim_pelanggan ADD COLUMN IF NOT EXISTS provinsi VARCHAR(50);
ALTER TABLE dwh.dim_supplier ADD COLUMN IF NOT EXISTS provinsi VARCHAR(50);
ALTER TABLE dwh.fact_penjualan ADD COLUMN IF NOT EXISTS no_penjualan VARCHAR(30);
ALTER TABLE dwh.fact_pembelian ADD COLUMN IF NOT EXISTS no_pembelian VARCHAR(30);

-- =====================================
-- DIM_WAKTU
-- =====================================
TRUNCATE TABLE dwh.dim_waktu RESTART IDENTITY CASCADE;

DO $$
DECLARE
    d DATE := '2020-01-01';
BEGIN
    WHILE d <= '2030-12-31' LOOP
        INSERT INTO dwh.dim_waktu (
            tanggal, hari_dalam_minggu, hari_dalam_bulan, hari_dalam_tahun,
            minggu_dalam_bulan, minggu_dalam_tahun, bulan, nama_bulan,
            bulan_tahun, kuartal, nama_kuartal, tahun, is_akhir_pekan
        )
        VALUES (
            d,
            TO_CHAR(d, 'Day'),
            EXTRACT(DAY FROM d)::SMALLINT,
            EXTRACT(DOY FROM d)::SMALLINT,
            CEIL(EXTRACT(DAY FROM d)/7.0)::SMALLINT,
            EXTRACT(WEEK FROM d)::SMALLINT,
            EXTRACT(MONTH FROM d)::SMALLINT,
            TO_CHAR(d, 'Month'),
            TO_CHAR(d, 'YYYY-MM'),
            CEIL(EXTRACT(MONTH FROM d)/3.0)::SMALLINT,
            'Q' || CEIL(EXTRACT(MONTH FROM d)/3.0)::INT,
            EXTRACT(YEAR FROM d)::SMALLINT,
            (EXTRACT(DOW FROM d) IN (0,6))
        );
        d := d + INTERVAL '1 day';
    END LOOP;
END $$;

-- =====================================
-- DIM_KATEGORI
-- =====================================
TRUNCATE TABLE dwh.dim_kategori RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_kategori (kategori_id, nama_kategori, effective_date, expiry_date, is_current)
SELECT id_kategori, nama_kategori, CURRENT_DATE, '9999-12-31', TRUE
FROM staging.kategori WHERE is_active = TRUE;

-- =====================================
-- DIM_TOKO
-- =====================================
TRUNCATE TABLE dwh.dim_toko RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_toko (toko_id, kode_toko, nama_toko, kota, provinsi, effective_date, expiry_date, is_current)
SELECT id_toko, kode_toko, nama_toko, kota, provinsi, CURRENT_DATE, '9999-12-31', TRUE
FROM staging.toko;

-- =====================================
-- DIM_METODE_PEMBAYARAN
-- =====================================
TRUNCATE TABLE dwh.dim_metode_pembayaran RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_metode_pembayaran (metode_id, nama_metode, deskripsi)
SELECT id_metode, nama_metode, 'Metode pembayaran: ' || nama_metode
FROM staging.metode_pembayaran;

-- =====================================
-- DIM_SUPPLIER
-- =====================================
TRUNCATE TABLE dwh.dim_supplier RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_supplier (supplier_id, nama_supplier, no_telp, kota, provinsi, rating_supplier)
SELECT id_supplier, nama_supplier, no_telp, kota, provinsi, 4.0
FROM staging.supplier;

-- =====================================
-- DIM_PEGAWAI
-- =====================================
TRUNCATE TABLE dwh.dim_pegawai RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_pegawai (pegawai_id, nama_pegawai, jabatan, no_telp, effective_date, expiry_date, is_current)
SELECT id_pegawai, nama_pegawai, jabatan, no_telp, CURRENT_DATE, '9999-12-31', TRUE
FROM staging.pegawai;

-- =====================================
-- DIM_PELANGGAN
-- =====================================
TRUNCATE TABLE dwh.dim_pelanggan RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_pelanggan (
    pelanggan_id, nama_pelanggan, jenis_kelamin, kota, provinsi, segment_pelanggan, effective_date, expiry_date, is_current
)
SELECT 
    id_pelanggan, nama_pelanggan, jenis_kelamin, kota, provinsi,
    CASE 
        WHEN tanggal_daftar >= CURRENT_DATE - INTERVAL '30 days' THEN 'New'
        WHEN (SELECT COUNT(*) FROM staging.penjualan p WHERE p.id_pelanggan = pel.id_pelanggan) >= 10 THEN 'VIP'
        ELSE 'Regular'
    END, CURRENT_DATE, '9999-12-31', TRUE
FROM staging.pelanggan pel;

-- =====================================
-- DIM_PRODUK
-- =====================================
TRUNCATE TABLE dwh.dim_produk RESTART IDENTITY CASCADE;
INSERT INTO dwh.dim_produk (
    produk_id, kode_produk, nama_produk, kategori_key, warna, harga_beli, harga_jual, deskripsi,
    margin_nominal, margin_persen, effective_date, expiry_date, is_current, version
)
SELECT 
    p.id_produk, p.kode_produk, p.nama_produk, dk.kategori_key, p.warna,
    p.harga_beli, p.harga_jual, p.deskripsi,
    (p.harga_jual - p.harga_beli),
    ROUND(((p.harga_jual - p.harga_beli)/NULLIF(p.harga_jual,0))*100,2),
    CURRENT_DATE, '9999-12-31', TRUE, 1
FROM staging.produk p
JOIN dwh.dim_kategori dk ON dk.kategori_id = p.id_kategori AND dk.is_current = TRUE;

-- =====================================
-- FACT_PENJUALAN
-- =====================================
TRUNCATE TABLE dwh.fact_penjualan RESTART IDENTITY;
INSERT INTO dwh.fact_penjualan (
    waktu_key, produk_key, pelanggan_key, pegawai_key, toko_key, metode_key,
    penjualan_id, no_penjualan, detail_penjualan_id, ukuran, jumlah_qty, harga_jual_satuan,
    diskon_item, subtotal_penjualan, harga_beli_satuan, total_hpp, total_profit, profit_margin_persen
)
SELECT 
    dw.waktu_key, dp.produk_key, dpl.pelanggan_key, dpg.pegawai_key, dt.toko_key, dm.metode_key,
    p.id_penjualan, p.no_penjualan, dpj.id_detail_penjualan, dpj.ukuran, dpj.jumlah,
    dpj.harga_satuan, dpj.diskon_item, dpj.subtotal,
    dp.harga_beli, (dp.harga_beli * dpj.jumlah),
    (dpj.subtotal - (dp.harga_beli * dpj.jumlah)),
    ROUND(((dpj.subtotal - (dp.harga_beli * dpj.jumlah))/NULLIF(dpj.subtotal,0))*100,2)
FROM staging.detail_penjualan dpj
JOIN staging.penjualan p ON dpj.id_penjualan = p.id_penjualan
JOIN dwh.dim_waktu dw ON dw.tanggal = p.tanggal_penjualan
JOIN dwh.dim_produk dp ON dp.produk_id = dpj.id_produk
LEFT JOIN dwh.dim_pelanggan dpl ON dpl.pelanggan_id = p.id_pelanggan
LEFT JOIN dwh.dim_pegawai dpg ON dpg.pegawai_id = p.id_pegawai
LEFT JOIN dwh.dim_toko dt ON dt.toko_id = p.id_toko
LEFT JOIN dwh.dim_metode_pembayaran dm ON dm.metode_id = p.id_metode
WHERE p.status = 'completed';

-- =====================================
-- FACT_PEMBELIAN
-- =====================================
TRUNCATE TABLE dwh.fact_pembelian RESTART IDENTITY;
INSERT INTO dwh.fact_pembelian (
    waktu_key, produk_key, supplier_key, pegawai_key, toko_key,
    pembelian_id, no_pembelian, detail_pembelian_id, ukuran, jumlah_qty, harga_beli_satuan, subtotal_pembelian
)
SELECT 
    dw.waktu_key, dp.produk_key, ds.supplier_key, dpg.pegawai_key, dt.toko_key,
    pb.id_pembelian, pb.no_pembelian, dpb.id_detail_pembelian, dpb.ukuran, dpb.jumlah, dpb.harga_satuan, dpb.subtotal
FROM staging.detail_pembelian dpb
JOIN staging.pembelian pb ON dpb.id_pembelian = pb.id_pembelian
JOIN dwh.dim_waktu dw ON dw.tanggal = pb.tanggal_pembelian
JOIN dwh.dim_produk dp ON dp.produk_id = dpb.id_produk
LEFT JOIN dwh.dim_supplier ds ON ds.supplier_id = pb.id_supplier
LEFT JOIN dwh.dim_pegawai dpg ON dpg.pegawai_id = pb.id_pegawai
LEFT JOIN dwh.dim_toko dt ON dt.toko_id = pb.id_toko
WHERE pb.status = 'completed';

-- =====================================
-- VIEW HASIL ETL
-- =====================================
CREATE OR REPLACE VIEW dwh.v_etl_summary AS
SELECT 
    'dim_waktu' AS table_name, COUNT(*) AS total_rows FROM dwh.dim_waktu
UNION ALL SELECT 'dim_kategori', COUNT(*) FROM dwh.dim_kategori
UNION ALL SELECT 'dim_toko', COUNT(*) FROM dwh.dim_toko
UNION ALL SELECT 'dim_produk', COUNT(*) FROM dwh.dim_produk
UNION ALL SELECT 'dim_supplier', COUNT(*) FROM dwh.dim_supplier
UNION ALL SELECT 'dim_pelanggan', COUNT(*) FROM dwh.dim_pelanggan
UNION ALL SELECT 'fact_penjualan', COUNT(*) FROM dwh.fact_penjualan
UNION ALL SELECT 'fact_pembelian', COUNT(*) FROM dwh.fact_pembelian;

-- Cek hasil akhir
SELECT * FROM dwh.v_etl_summary;
