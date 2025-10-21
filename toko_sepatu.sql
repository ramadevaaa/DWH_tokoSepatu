
CREATE TABLE kategori (
    id_kategori SERIAL PRIMARY KEY,
    nama_kategori VARCHAR(50) NOT NULL,
    deskripsi TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- Table: toko
CREATE TABLE toko (
    id_toko SERIAL PRIMARY KEY,
    kode_toko VARCHAR(10) UNIQUE NOT NULL,
    nama_toko VARCHAR(100) NOT NULL,
    kota VARCHAR(50) NOT NULL,
    provinsi VARCHAR(50) NOT NULL,
    no_telp VARCHAR(20)
);

-- Table: produk
CREATE TABLE produk (
    id_produk SERIAL PRIMARY KEY,
    kode_produk VARCHAR(20) UNIQUE NOT NULL,
    nama_produk VARCHAR(100) NOT NULL,
    id_kategori INT REFERENCES kategori(id_kategori),
    warna VARCHAR(50) NOT NULL,
    harga_beli DECIMAL(12,2) NOT NULL,
    harga_jual DECIMAL(12,2) NOT NULL,
    deskripsi TEXT
);

-- Table: supplier
CREATE TABLE supplier (
    id_supplier SERIAL PRIMARY KEY,
    kode_supplier VARCHAR(20) UNIQUE NOT NULL,
    nama_supplier VARCHAR(100) NOT NULL,
    kota VARCHAR(50) NOT NULL,
    provinsi VARCHAR(50) NOT NULL,
    no_telp VARCHAR(20)
);

-- Table: pegawai
CREATE TABLE pegawai (
    id_pegawai SERIAL PRIMARY KEY,
    nip VARCHAR(20) UNIQUE NOT NULL,
    nama_pegawai VARCHAR(100) NOT NULL,
    jabatan VARCHAR(50) NOT NULL,
    id_toko INT REFERENCES toko(id_toko),
    no_telp VARCHAR(20)
);

-- Table: pelanggan
CREATE TABLE pelanggan (
    id_pelanggan SERIAL PRIMARY KEY,
    kode_pelanggan VARCHAR(20) UNIQUE NOT NULL,
    nama_pelanggan VARCHAR(100) NOT NULL,
    jenis_kelamin VARCHAR(15),
    kota VARCHAR(50) NOT NULL,
    provinsi VARCHAR(50) NOT NULL,
    no_telp VARCHAR(20),
    tanggal_daftar DATE DEFAULT CURRENT_DATE
);

-- Table: metode_pembayaran
CREATE TABLE metode_pembayaran (
    id_metode SERIAL PRIMARY KEY,
    nama_metode VARCHAR(50) NOT NULL
);

-- Table: pembelian
CREATE TABLE pembelian (
    id_pembelian SERIAL PRIMARY KEY,
    no_pembelian VARCHAR(30) UNIQUE NOT NULL,
    id_supplier INT REFERENCES supplier(id_supplier),
    id_pegawai INT REFERENCES pegawai(id_pegawai),
    id_toko INT REFERENCES toko(id_toko),
    tanggal_pembelian DATE NOT NULL,
    total_pembelian DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'completed'
);

-- Table: detail_pembelian
CREATE TABLE detail_pembelian (
    id_detail_pembelian SERIAL PRIMARY KEY,
    id_pembelian INT REFERENCES pembelian(id_pembelian) ON DELETE CASCADE,
    id_produk INT REFERENCES produk(id_produk),
    ukuran INT NOT NULL CHECK (ukuran BETWEEN 35 AND 45),
    jumlah INT NOT NULL CHECK (jumlah > 0),
    harga_satuan DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL
);

-- Table: penjualan
CREATE TABLE penjualan (
    id_penjualan SERIAL PRIMARY KEY,
    no_penjualan VARCHAR(30) UNIQUE NOT NULL,
    id_pelanggan INT REFERENCES pelanggan(id_pelanggan),
    id_pegawai INT REFERENCES pegawai(id_pegawai),
    id_toko INT REFERENCES toko(id_toko),
    id_metode INT REFERENCES metode_pembayaran(id_metode),
    tanggal_penjualan DATE NOT NULL,
    total_penjualan DECIMAL(12,2),
    diskon DECIMAL(12,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'completed'
);

-- Table: detail_penjualan
CREATE TABLE detail_penjualan (
    id_detail_penjualan SERIAL PRIMARY KEY,
    id_penjualan INT REFERENCES penjualan(id_penjualan) ON DELETE CASCADE,
    id_produk INT REFERENCES produk(id_produk),
    ukuran INT NOT NULL CHECK (ukuran BETWEEN 35 AND 45),
    jumlah INT NOT NULL CHECK (jumlah > 0),
    harga_satuan DECIMAL(12,2) NOT NULL,
    diskon_item DECIMAL(12,2) DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL
);

-- Table: stok
CREATE TABLE stok (
    id_produk INT REFERENCES produk(id_produk),
    id_toko INT REFERENCES toko(id_toko),
    ukuran INT NOT NULL CHECK (ukuran BETWEEN 35 AND 45),
    jumlah INT DEFAULT 0,
    PRIMARY KEY (id_produk, id_toko, ukuran)
);

-- =====================================================
-- SECTION 2: CREATE INDEXES
-- =====================================================

CREATE INDEX idx_produk_kategori ON produk(id_kategori);
CREATE INDEX idx_pegawai_toko ON pegawai(id_toko);
CREATE INDEX idx_pelanggan_kota ON pelanggan(kota);
CREATE INDEX idx_pembelian_tanggal ON pembelian(tanggal_pembelian);
CREATE INDEX idx_penjualan_tanggal ON penjualan(tanggal_penjualan);

-- =====================================================
-- SECTION 3: INSERT MASTER DATA
-- =====================================================

-- Insert kategori
INSERT INTO kategori (nama_kategori, deskripsi) VALUES
('Kasual', 'Sepatu untuk penggunaan sehari-hari'),
('Formal', 'Sepatu untuk acara formal dan kantor'),
('Olahraga', 'Sepatu untuk aktivitas olahraga'),
('Perempuan', 'Sepatu khusus wanita'),
('Anak-anak', 'Sepatu untuk anak-anak');

-- Insert toko
INSERT INTO toko (kode_toko, nama_toko, kota, provinsi, no_telp) VALUES
('TK001', 'Toko Sepatu Jakarta', 'Jakarta', 'DKI Jakarta', '021-5551001'),
('TK002', 'Toko Sepatu Bandung', 'Bandung', 'Jawa Barat', '022-5552001'),
('TK003', 'Toko Sepatu Surabaya', 'Surabaya', 'Jawa Timur', '031-5553001');

-- Insert metode_pembayaran
INSERT INTO metode_pembayaran (nama_metode) VALUES
('Cash'),
('Debit Card'),
('Credit Card'),
('Transfer Bank'),
('E-Wallet');

-- Insert supplier
INSERT INTO supplier (kode_supplier, nama_supplier, kota, provinsi, no_telp) VALUES
('SUP-001', 'PT Sepatu Makmur', 'Jakarta', 'DKI Jakarta', '021-7890001'),
('SUP-002', 'CV Sepatu Jaya', 'Bandung', 'Jawa Barat', '022-7890002'),
('SUP-003', 'Grosir Sepatu Nusantara', 'Surabaya', 'Jawa Timur', '031-7890003'),
('SUP-004', 'PT Laris Footwear', 'Yogyakarta', 'DI Yogyakarta', '0274-7890004'),
('SUP-005', 'UD Kaki Sehat', 'Medan', 'Sumatera Utara', '061-7890005');

-- Insert pegawai
INSERT INTO pegawai (nip, nama_pegawai, jabatan, id_toko, no_telp) VALUES
('PEG-001', 'Andi Saputra', 'Manajer', 1, '081234567801'),
('PEG-002', 'Budi Santoso', 'Kasir', 1, '081234567802'),
('PEG-003', 'Citra Dewi', 'Kasir', 1, '081234567803'),
('PEG-004', 'Dewi Lestari', 'Manajer', 2, '081234567804'),
('PEG-005', 'Eko Prasetyo', 'Kasir', 2, '081234567805'),
('PEG-006', 'Fajar Hidayat', 'Kasir', 2, '081234567806'),
('PEG-007', 'Gita Wulandari', 'Manajer', 3, '081234567807'),
('PEG-008', 'Hadi Kurniawan', 'Kasir', 3, '081234567808'),
('PEG-009', 'Indah Permata', 'Kasir', 3, '081234567809');

-- Insert produk (50 products using loop)
DO $$
DECLARE
    i INT;
    kategori_id INT;
    warna_list TEXT[] := ARRAY['Hitam', 'Putih', 'Coklat', 'Merah', 'Biru', 'Abu-abu', 'Navy', 'Hijau'];
    nama_kategori TEXT;
BEGIN
    FOR i IN 1..50 LOOP
        kategori_id := ((i - 1) % 5) + 1;
        
        CASE kategori_id
            WHEN 1 THEN nama_kategori := 'Sepatu Kasual';
            WHEN 2 THEN nama_kategori := 'Sepatu Formal';
            WHEN 3 THEN nama_kategori := 'Sepatu Olahraga';
            WHEN 4 THEN nama_kategori := 'Heels Wanita';
            ELSE nama_kategori := 'Sepatu Anak';
        END CASE;
        
        INSERT INTO produk (kode_produk, nama_produk, id_kategori, warna, harga_beli, harga_jual, deskripsi)
        VALUES (
            'PRD-' || LPAD(i::TEXT, 5, '0'),
            nama_kategori || ' Model ' || i,
            kategori_id,
            warna_list[((i - 1) % 8) + 1],
            (100000 + (i * 5000))::DECIMAL(12,2),
            ((100000 + (i * 5000)) * 1.5)::DECIMAL(12,2),
            'Deskripsi produk ' || nama_kategori || ' model ' || i
        );
    END LOOP;
END $$;

-- Insert pelanggan (100 customers using loop)
DO $$
DECLARE
    i INT;
    gender TEXT;
    kota_list TEXT[] := ARRAY['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Medan', 'Bogor', 'Semarang', 'Solo', 'Malang', 'Denpasar'];
    provinsi_list TEXT[] := ARRAY['DKI Jakarta', 'Jawa Barat', 'Jawa Timur', 'DI Yogyakarta', 'Sumatera Utara', 'Jawa Barat', 'Jawa Tengah', 'Jawa Tengah', 'Jawa Timur', 'Bali'];
    nama_depan TEXT[] := ARRAY['Andi', 'Budi', 'Citra', 'Dewi', 'Eko', 'Fajar', 'Gita', 'Hadi', 'Indah', 'Joko'];
    nama_belakang TEXT[] := ARRAY['Saputra', 'Susanto', 'Hidayat', 'Lestari', 'Prasetyo', 'Wulandari', 'Permata', 'Santoso'];
    kota_idx INT;
BEGIN
    FOR i IN 1..100 LOOP
        gender := CASE WHEN (i % 3) = 0 THEN 'Laki-laki' ELSE 'Perempuan' END;
        kota_idx := ((i - 1) % 10) + 1;
        
        INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, jenis_kelamin, kota, provinsi, no_telp, tanggal_daftar)
        VALUES (
            'CUST-' || LPAD(i::TEXT, 5, '0'),
            nama_depan[((i - 1) % 10) + 1] || ' ' || nama_belakang[((i - 1) % 8) + 1],
            gender,
            kota_list[kota_idx],
            provinsi_list[kota_idx],
            '0813' || LPAD((30000000 + i)::TEXT, 8, '0'),
            ('2023-01-01'::DATE + (i * 3 || ' days')::INTERVAL)::DATE
        );
    END LOOP;
END $$;

-- =====================================================
-- SECTION 4: GENERATE TRANSACTION DATA (1 YEAR - 2024)
-- =====================================================

-- Generate PEMBELIAN (250 transactions throughout 2024)
DO $$
DECLARE
    i INT;
    tgl DATE;
BEGIN
    FOR i IN 1..250 LOOP
        tgl := '2024-01-01'::DATE + ((i - 1) || ' days')::INTERVAL;
        
        INSERT INTO pembelian (no_pembelian, id_supplier, id_pegawai, id_toko, tanggal_pembelian, total_pembelian, status)
        VALUES (
            'PBL-2024-' || LPAD(i::TEXT, 5, '0'),
            ((i - 1) % 5) + 1,  -- Cycle through 5 suppliers
            ((i - 1) % 9) + 1,  -- Cycle through 9 employees
            ((i - 1) % 3) + 1,  -- Cycle through 3 stores
            tgl,
            0,  -- Will be calculated from details
            'completed'
        );
    END LOOP;
    RAISE NOTICE 'Generated 250 pembelian records';
END $$;

-- Generate DETAIL_PEMBELIAN (750 details = 250 x 3 items average)
DO $$
DECLARE
    i INT;
    pembelian_id INT;
    produk_id INT;
    ukuran_val INT;
    jumlah_val INT;
    harga_beli_val DECIMAL(12,2);
    subtotal_val DECIMAL(12,2);
    ukuran_list INT[] := ARRAY[38, 39, 40];
BEGIN
    FOR i IN 1..750 LOOP
        pembelian_id := ((i - 1) / 3) + 1;
        produk_id := ((i - 1) % 50) + 1;
        ukuran_val := ukuran_list[((i - 1) % 3) + 1];
        jumlah_val := 5 + (i % 15);  -- 5-20 units
        
        SELECT harga_beli INTO harga_beli_val FROM produk WHERE id_produk = produk_id;
        subtotal_val := harga_beli_val * jumlah_val;
        
        INSERT INTO detail_pembelian (id_pembelian, id_produk, ukuran, jumlah, harga_satuan, subtotal)
        VALUES (pembelian_id, produk_id, ukuran_val, jumlah_val, harga_beli_val, subtotal_val);
    END LOOP;
    RAISE NOTICE 'Generated 750 detail_pembelian records';
END $$;

-- Update total_pembelian
UPDATE pembelian p SET total_pembelian = (
    SELECT COALESCE(SUM(subtotal), 0) FROM detail_pembelian WHERE id_pembelian = p.id_pembelian
);

-- Generate PENJUALAN (500 transactions throughout 2024)
DO $$
DECLARE
    i INT;
    tgl DATE;
    diskon_val DECIMAL(12,2);
BEGIN
    FOR i IN 1..500 LOOP
        tgl := '2024-01-01'::DATE + ((i - 1) || ' days')::INTERVAL;
        diskon_val := CASE WHEN (i % 10) = 0 THEN 10000 + ((i % 5) * 5000) ELSE 0 END;
        
        INSERT INTO penjualan (no_penjualan, id_pelanggan, id_pegawai, id_toko, id_metode, tanggal_penjualan, total_penjualan, diskon, status)
        VALUES (
            'PNJ-2024-' || LPAD(i::TEXT, 5, '0'),
            ((i - 1) % 100) + 1,  -- Cycle through 100 customers
            ((i - 1) % 9) + 1,    -- Cycle through 9 employees
            ((i - 1) % 3) + 1,    -- Cycle through 3 stores
            ((i - 1) % 5) + 1,    -- Cycle through 5 payment methods
            tgl,
            0,  -- Will be calculated
            diskon_val,
            'completed'
        );
    END LOOP;
    RAISE NOTICE 'Generated 500 penjualan records';
END $$;

-- Generate DETAIL_PENJUALAN (1000 details = 500 x 2 items average)
DO $$
DECLARE
    i INT;
    penjualan_id INT;
    produk_id INT;
    ukuran_val INT;
    jumlah_val INT;
    harga_jual_val DECIMAL(12,2);
    diskon_item_val DECIMAL(12,2);
    subtotal_val DECIMAL(12,2);
    ukuran_list INT[] := ARRAY[38, 39, 40];
BEGIN
    FOR i IN 1..1000 LOOP
        penjualan_id := ((i - 1) / 2) + 1;
        produk_id := ((i - 1) % 50) + 1;
        ukuran_val := ukuran_list[((i - 1) % 3) + 1];
        jumlah_val := 1 + (i % 3);  -- 1-3 units
        
        SELECT harga_jual INTO harga_jual_val FROM produk WHERE id_produk = produk_id;
        diskon_item_val := CASE WHEN (i % 5) = 0 THEN 5000 + ((i % 3) * 2500) ELSE 0 END;
        subtotal_val := (harga_jual_val * jumlah_val) - diskon_item_val;
        
        IF subtotal_val < 0 THEN
            subtotal_val := harga_jual_val * jumlah_val * 0.5;
        END IF;
        
        INSERT INTO detail_penjualan (id_penjualan, id_produk, ukuran, jumlah, harga_satuan, diskon_item, subtotal)
        VALUES (penjualan_id, produk_id, ukuran_val, jumlah_val, harga_jual_val, diskon_item_val, subtotal_val);
    END LOOP;
    RAISE NOTICE 'Generated 1000 detail_penjualan records';
END $$;

-- Update total_penjualan
UPDATE penjualan p SET total_penjualan = (
    SELECT COALESCE(SUM(subtotal), 0) - p.diskon FROM detail_penjualan WHERE id_penjualan = p.id_penjualan
);
