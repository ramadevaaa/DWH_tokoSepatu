# 🏬 Data Warehouse Toko Sepatu  

![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-blue?logo=postgresql)
![MySQL](https://img.shields.io/badge/Source-MySQL-orange?logo=mysql)
![DBeaver](https://img.shields.io/badge/Tool-DBeaver-green?logo=dbeaver)
![ETL Process](https://img.shields.io/badge/ETL-Implemented-success)
![Status](https://img.shields.io/badge/Project_Status-Completed-brightgreen)

Repositori ini berisi implementasi lengkap **Data Warehouse (DWH)** untuk sistem **Toko Sepatu**, dibangun menggunakan **MySQL** sebagai database operasional dan **PostgreSQL** sebagai target Data Warehouse.  
Proyek ini menerapkan metodologi **Kimball Nine-Step**, mencakup perancangan struktur database, proses **ETL (Extract–Transform–Load)**, serta analisis bisnis berbasis **Star Schema** untuk mendukung pengambilan keputusan strategis.

---

## 📦 Struktur Folder  

| 📁 Folder / File | Deskripsi |
|------------------|-----------|
| `scripts/DWH_Toko_Sepatu.sql` | Membuat struktur database `dwh_toko_sepatu` (dimensi, fakta, dan index). |
| `scripts/ETL_DWH_Toko_Sepatu.sql` | Proses ETL dari `db_toko_sepatu` → `dwh_toko_sepatu`. |
| `scripts/Query_Analytic.sql` | Query analisis dan validasi kualitas data. |
| `scripts/toko_sepatu.sql` | Database operasional OLTP. |
| `docs/DWH_Design_Diagram.png` | (Opsional) Diagram Star Schema DWH. |
| `docs/ERD_Toko_Sepatu.png` | (Opsional) ERD database operasional. |
| `README.md` | Dokumentasi utama proyek. |

---

## 🎯 Tujuan Proyek  

| Tujuan | Penjelasan |
|--------|-------------|
| 🧱 **Membangun Model DWH** | Menyimpan data historis transaksi penjualan & pembelian secara analitis. |
| 🔄 **Implementasi ETL Lintas Platform** | Menyelaraskan data dari MySQL (OLTP) ke PostgreSQL (DWH). |
| 🌟 **Desain Star Schema** | Mendukung analisis multidimensi: produk, pelanggan, waktu, toko, pegawai. |
| 💹 **Analisis Bisnis Terukur** | Menghasilkan laporan & insight strategis untuk pengambilan keputusan. |

---

## ⚙️ Teknologi yang Digunakan  

| Komponen | Teknologi |
|-----------|------------|
| 🧱 Database Engine | MySQL (OLTP), PostgreSQL (DWH) |
| 💬 Query Language | SQL / PLpgSQL |
| 🧰 Tool | DBeaver (untuk migrasi & ETL) |
| 🔄 ETL Framework | Manual SQL Transformation |
| 📊 BI Integration | Power BI / Metabase (opsional) |

---

## 📂 Struktur File SQL  

| No | File | Deskripsi |
|----|------|------------|
| 1️⃣ | **DWH_Toko_Sepatu.sql** | Membuat struktur database `dwh_toko_sepatu`, mencakup tabel dimensi (`dim_produk`, `dim_pelanggan`, `dim_toko`, `dim_waktu`, `dim_supplier`, dll.) dan tabel fakta (`fact_penjualan`, `fact_pembelian`) lengkap dengan relasi dan indeks. |
| 2️⃣ | **ETL_DWH_Toko_Sepatu.sql** | Melakukan proses **ETL (Extract, Transform, Load)** dari `db_toko_sepatu` ke `dwh_toko_sepatu`, termasuk transformasi data, pembentukan dimensi waktu, serta perhitungan HPP dan margin. |
| 3️⃣ | **Query_Analytic.sql** | Kumpulan *analytical queries* untuk validasi data dan analisis bisnis seperti performa penjualan, produk terlaris, segmentasi pelanggan, dan profitabilitas produk. |
| 4️⃣ | **toko_sepatu.sql** | Database sumber (OLTP) berisi tabel transaksi harian dan master data seperti `tb_produk`, `tb_pelanggan`, `tb_penjualan`, `tb_pembelian`, `tb_pegawai`. |

---

## 🧩 Data Quality Validation  

| Validasi | Fungsi |
|-----------|---------|
| ✅ **Record Count Summary** | Mengecek kesesuaian jumlah baris antara OLTP dan DWH. |
| 📅 **Date Range Coverage** | Memastikan kelengkapan periode waktu transaksi. |
| ⚠️ **Integrity Check** | Mendeteksi *orphan key*, nilai negatif, dan duplikasi data. |

---

## 📊 Business Intelligence Insights  

| Analisis | Deskripsi |
|-----------|------------|
| 📆 **Monthly Sales Performance** | Total transaksi, pendapatan, dan profit per bulan. |
| 👟 **Top 10 Best Selling Products** | Produk sepatu paling laris dan menguntungkan. |
| 🏪 **Sales by Store** | Analisis performa tiap cabang toko. |
| 🧍 **Customer Segmentation** | Segmentasi pelanggan berdasarkan gender & tipe pembelian. |
| 📍 **Sales by City** | Distribusi penjualan berdasarkan wilayah. |
| 👨‍💼 **Employee Performance** | Kontribusi pegawai terhadap total penjualan. |
| 💳 **Payment Method Analysis** | Proporsi transaksi per metode pembayaran. |
| 📏 **Product Size Popularity** | Ukuran sepatu dengan penjualan tertinggi. |
| 📦 **Inventory Turnover** | Perbandingan pembelian dan penjualan untuk menghitung rotasi stok. |
| 💰 **Discount Impact** | Dampak diskon terhadap margin dan total penjualan. |
| 🌟 **Product Profitability Matrix** | Klasifikasi produk menjadi *Star*, *Cash Cow*, *Niche*, atau *Dog*. |

---

## 🧾 Ringkasan Eksekutif  

| Metrik | Nilai (Contoh) | Satuan |
|--------|----------------|--------|
| 💸 **Total Penjualan** | ± 120.000.000 | IDR |
| 💰 **Total Profit** | ± 28.500.000 | IDR |
| 📈 **Average Margin** | 23.75 | % |
| 🛍️ **Total Transactions** | 420 | transaksi |
| 👥 **Total Customers** | 185 | pelanggan |
| 👟 **Total Products Sold** | 1.275 | unit |
| 💳 **Average Transaction Value** | ± 285.000 | IDR |

> 💡 *Nilai di atas bersifat ilustratif. Hasil aktual diambil dari eksekusi file* `03_Query_Analytic.sql`.

---

## ✅ Status Proyek  

| Status | Keterangan |
|--------|-------------|
| 🟢 **ETL Process** | Berhasil dilakukan antara MySQL → PostgreSQL |
| 🧮 **Data Validation** | Semua uji validasi dan integritas lulus |
| 📊 **Analytic Queries** | Berhasil menghasilkan insight dan laporan |
| 🚀 **Project Status** | Completed & siap diintegrasikan ke BI Tools |

---

## 🌐 Integrasi BI (Opsional)  

| Tools | Fungsi |
|--------|--------|
| **Power BI** | Visualisasi performa penjualan, pelanggan, dan produk. |
| **Metabase** | Dashboard analisis interaktif untuk tim bisnis. |

---

