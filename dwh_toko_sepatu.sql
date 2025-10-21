CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dwh;
SET search_path TO dwh, public;

-- ============================================================================
-- DIMENSIONS
-- ============================================================================

-- 1) DIM_WAKTU
CREATE TABLE dwh.dim_waktu (
  waktu_key        SERIAL PRIMARY KEY,
  tanggal          DATE NOT NULL UNIQUE,
  -- components (tanpa padding dengan FM)
  hari_dalam_minggu VARCHAR(10) NOT NULL,
  hari_dalam_bulan  SMALLINT NOT NULL,
  hari_dalam_tahun  SMALLINT NOT NULL,
  minggu_dalam_bulan SMALLINT NOT NULL,
  minggu_dalam_tahun SMALLINT NOT NULL,
  bulan             SMALLINT NOT NULL,
  nama_bulan        VARCHAR(20) NOT NULL,
  bulan_tahun       VARCHAR(7) NOT NULL, -- YYYY-MM
  kuartal           SMALLINT NOT NULL,
  nama_kuartal      VARCHAR(6) NOT NULL, -- Q1..Q4
  tahun             SMALLINT NOT NULL,
  is_akhir_pekan    BOOLEAN NOT NULL,
  is_hari_libur     BOOLEAN DEFAULT FALSE,
  nama_hari_libur   VARCHAR(100),
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_waktu_tanggal       ON dwh.dim_waktu(tanggal);
CREATE INDEX idx_dim_waktu_tahun_bulan   ON dwh.dim_waktu(tahun, bulan);
CREATE INDEX idx_dim_waktu_kuartal       ON dwh.dim_waktu(tahun, kuartal);

-- 2) DIM_KATEGORI (SCD2-ready)
CREATE TABLE dwh.dim_kategori (
  kategori_key  SERIAL PRIMARY KEY,
  kategori_id   INTEGER NOT NULL,
  nama_kategori VARCHAR(50) NOT NULL,
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date    DATE NOT NULL DEFAULT '9999-12-31',
  is_current     BOOLEAN NOT NULL DEFAULT TRUE,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX ux_dim_kategori_bk_range
  ON dwh.dim_kategori (kategori_id, effective_date, expiry_date);
CREATE INDEX idx_dim_kategori_current ON dwh.dim_kategori(is_current);

-- 3) DIM_TOKO (SCD2-ready)
CREATE TABLE dwh.dim_toko (
  toko_key   SERIAL PRIMARY KEY,
  toko_id    INTEGER NOT NULL,
  kode_toko  VARCHAR(20),
  nama_toko  VARCHAR(100),
  kota       VARCHAR(50),
  provinsi   VARCHAR(50),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date    DATE NOT NULL DEFAULT '9999-12-31',
  is_current     BOOLEAN NOT NULL DEFAULT TRUE,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX ux_dim_toko_bk_range
  ON dwh.dim_toko (toko_id, effective_date, expiry_date);
CREATE INDEX idx_dim_toko_current ON dwh.dim_toko(is_current);

-- 4) DIM_METODE_PEMBAYARAN (SCD1)
CREATE TABLE dwh.dim_metode_pembayaran (
  metode_key   SERIAL PRIMARY KEY,
  metode_id    INTEGER NOT NULL UNIQUE,
  nama_metode  VARCHAR(50) NOT NULL,
  deskripsi    TEXT,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5) DIM_SUPPLIER (SCD1)
CREATE TABLE dwh.dim_supplier (
  supplier_key  SERIAL PRIMARY KEY,
  supplier_id   INTEGER NOT NULL UNIQUE,
  nama_supplier VARCHAR(100) NOT NULL,
  no_telp       VARCHAR(20),
  kota          VARCHAR(50),
  rating_supplier NUMERIC(3,2),
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_dim_supplier_id ON dwh.dim_supplier(supplier_id);

-- 6) DIM_PEGAWAI (SCD2-ready)
CREATE TABLE dwh.dim_pegawai (
  pegawai_key  SERIAL PRIMARY KEY,
  pegawai_id   INTEGER NOT NULL,
  nama_pegawai VARCHAR(100),
  jabatan      VARCHAR(50),
  no_telp      VARCHAR(20),
  -- manager_key didefer: isi saat ETL jika ada hierarki
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date    DATE NOT NULL DEFAULT '9999-12-31',
  is_current     BOOLEAN NOT NULL DEFAULT TRUE,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX ux_dim_pegawai_bk_range
  ON dwh.dim_pegawai (pegawai_id, effective_date, expiry_date);
CREATE INDEX idx_dim_pegawai_current ON dwh.dim_pegawai(is_current);

-- 7) DIM_PELANGGAN (SCD2-ready)
CREATE TABLE dwh.dim_pelanggan (
  pelanggan_key  SERIAL PRIMARY KEY,
  pelanggan_id   INTEGER NOT NULL,
  nama_pelanggan VARCHAR(100),
  jenis_kelamin  VARCHAR(10),
  kota           VARCHAR(50),
  segment_pelanggan VARCHAR(20),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date    DATE NOT NULL DEFAULT '9999-12-31',
  is_current     BOOLEAN NOT NULL DEFAULT TRUE,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX ux_dim_pelanggan_bk_range
  ON dwh.dim_pelanggan (pelanggan_id, effective_date, expiry_date);
CREATE INDEX idx_dim_pelanggan_current ON dwh.dim_pelanggan(is_current);
CREATE INDEX idx_dim_pelanggan_kota    ON dwh.dim_pelanggan(kota);

-- 8) DIM_PRODUK (SCD2-ready; margin diisi via ETL atau view)
CREATE TABLE dwh.dim_produk (
  produk_key   SERIAL PRIMARY KEY,
  produk_id    INTEGER NOT NULL,
  nama_produk  VARCHAR(100) NOT NULL,
  kategori_key INTEGER NOT NULL REFERENCES dwh.dim_kategori(kategori_key),
  harga_beli   NUMERIC(12,2) NOT NULL,
  harga_jual   NUMERIC(12,2) NOT NULL,
  deskripsi    TEXT,
  -- kolom margin disiapkan (diisi ETL)
  margin_persen  NUMERIC(5,2),
  margin_nominal NUMERIC(12,2),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date    DATE NOT NULL DEFAULT '9999-12-31',
  is_current     BOOLEAN NOT NULL DEFAULT TRUE,
  version        INTEGER NOT NULL DEFAULT 1,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX ux_dim_produk_bk_range
  ON dwh.dim_produk (produk_id, effective_date, expiry_date);
CREATE INDEX idx_dim_produk_current   ON dwh.dim_produk(is_current);
CREATE INDEX idx_dim_produk_kategori  ON dwh.dim_produk(kategori_key);
CREATE INDEX idx_dim_produk_nama      ON dwh.dim_produk(nama_produk);

-- ============================================================================
-- FACTS (grain = per item)
-- ============================================================================

-- FACT_PENJUALAN
CREATE TABLE dwh.fact_penjualan (
  penjualan_fact_key BIGSERIAL PRIMARY KEY,
  -- FKs
  waktu_key     INTEGER NOT NULL REFERENCES dwh.dim_waktu(waktu_key),
  produk_key    INTEGER NOT NULL REFERENCES dwh.dim_produk(produk_key),
  pelanggan_key INTEGER     REFERENCES dwh.dim_pelanggan(pelanggan_key),
  pegawai_key   INTEGER     REFERENCES dwh.dim_pegawai(pegawai_key),
  toko_key      INTEGER     REFERENCES dwh.dim_toko(toko_key),
  metode_key    INTEGER     REFERENCES dwh.dim_metode_pembayaran(metode_key),
  -- degenerate
  penjualan_id        INTEGER NOT NULL,
  detail_penjualan_id INTEGER NOT NULL,
  -- measures
  ukuran       SMALLINT,           -- konsisten dengan OLTP (35..45)
  jumlah_qty   INTEGER  NOT NULL CHECK (jumlah_qty > 0),
  harga_jual_satuan   NUMERIC(12,2) NOT NULL CHECK (harga_jual_satuan >= 0),
  diskon_item         NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (diskon_item >= 0),
  subtotal_penjualan  NUMERIC(12,2) NOT NULL CHECK (subtotal_penjualan >= 0),
  -- derived (isi saat ETL)
  harga_beli_satuan   NUMERIC(12,2),
  total_hpp           NUMERIC(12,2),
  total_profit        NUMERIC(12,2),
  profit_margin_persen NUMERIC(5,2),
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  etl_batch_id INTEGER,
  source_system VARCHAR(50) DEFAULT 'toko_sepatu'
);
CREATE INDEX idx_fp_waktu    ON dwh.fact_penjualan(waktu_key);
CREATE INDEX idx_fp_produk   ON dwh.fact_penjualan(produk_key);
CREATE INDEX idx_fp_pelanggan ON dwh.fact_penjualan(pelanggan_key);
CREATE INDEX idx_fp_toko     ON dwh.fact_penjualan(toko_key);
CREATE INDEX idx_fp_metode   ON dwh.fact_penjualan(metode_key);
CREATE INDEX idx_fp_trans    ON dwh.fact_penjualan(penjualan_id);
CREATE INDEX idx_fp_comp     ON dwh.fact_penjualan(waktu_key, produk_key);

-- FACT_PEMBELIAN
CREATE TABLE dwh.fact_pembelian (
  pembelian_fact_key BIGSERIAL PRIMARY KEY,
  -- FKs
  waktu_key    INTEGER NOT NULL REFERENCES dwh.dim_waktu(waktu_key),
  produk_key   INTEGER NOT NULL REFERENCES dwh.dim_produk(produk_key),
  supplier_key INTEGER     REFERENCES dwh.dim_supplier(supplier_key),
  pegawai_key  INTEGER     REFERENCES dwh.dim_pegawai(pegawai_key),
  toko_key     INTEGER     REFERENCES dwh.dim_toko(toko_key),
  -- degenerate
  pembelian_id        INTEGER NOT NULL,
  detail_pembelian_id INTEGER NOT NULL,
  -- measures
  ukuran         SMALLINT,
  jumlah_qty     INTEGER NOT NULL CHECK (jumlah_qty > 0),
  harga_beli_satuan  NUMERIC(12,2) NOT NULL CHECK (harga_beli_satuan >= 0),
  subtotal_pembelian NUMERIC(12,2) NOT NULL CHECK (subtotal_pembelian >= 0),
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  etl_batch_id INTEGER,
  source_system VARCHAR(50) DEFAULT 'toko_sepatu'
);
CREATE INDEX idx_fpb_waktu   ON dwh.fact_pembelian(waktu_key);
CREATE INDEX idx_fpb_produk  ON dwh.fact_pembelian(produk_key);
CREATE INDEX idx_fpb_supplier ON dwh.fact_pembelian(supplier_key);
CREATE INDEX idx_fpb_toko    ON dwh.fact_pembelian(toko_key);
CREATE INDEX idx_fpb_trans   ON dwh.fact_pembelian(pembelian_id);
CREATE INDEX idx_fpb_comp    ON dwh.fact_pembelian(waktu_key, produk_key);
