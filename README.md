🏬 Data Warehouse Toko Sepatu

Repositori ini berisi implementasi lengkap Data Warehouse (DWH) untuk sistem Toko Sepatu, menggunakan MySQL dan PostgreSQL sebagai platform basis data utama.
Proyek ini mencakup seluruh tahapan pembangunan Data Warehouse berdasarkan metodologi Kimball Nine-Step, mulai dari pembuatan struktur database, proses ETL (Extract, Transform, Load), hingga analisis data bisnis berbasis Star Schema.

📂 Struktur File
No	File	Deskripsi
1️⃣	DWH_Toko_Sepatu.sql	Membuat struktur database dwh_toko_sepatu, mencakup tabel dimensi (dim_produk, dim_pelanggan, dim_supplier, dim_toko, dim_waktu, dll.), tabel fakta (fact_penjualan, fact_pembelian), serta pembuatan indeks dan relasi Star Schema.
2️⃣	ETL_DWH_Toko_Sepatu.sql	Berisi proses ETL untuk menyalin, membersihkan, dan mentransformasi data dari database operasional db_toko_sepatu ke dwh_toko_sepatu. Termasuk pembangkitan surrogate key dan dimensi waktu.
3️⃣	Query_Analytic.sql	Kumpulan analytical queries untuk analisis bisnis dan validasi kualitas data. Meliputi performa penjualan bulanan, produk terlaris, analisis pelanggan, kinerja pegawai, dan segmentasi diskon.
4️⃣	toko_sepatu.sql	Database operasional (OLTP) yang merepresentasikan sistem transaksi harian toko sepatu, mencakup tabel seperti tb_produk, tb_pelanggan, tb_pembelian, tb_penjualan, dan tb_pegawai.
🧠 Tujuan Proyek

Membangun model Data Warehouse Toko Sepatu yang mampu menyimpan data historis transaksi penjualan dan pembelian secara analitis.

Mengimplementasikan proses ETL lintas platform antara sistem operasional dan DWH (MySQL → PostgreSQL).

Menerapkan desain Star Schema untuk mendukung analisis multidimensi (produk, pelanggan, waktu, toko, pegawai).

Menghasilkan laporan bisnis dan insight analitis yang dapat membantu pengambilan keputusan strategis.

⚙️ Teknologi yang Digunakan
Komponen	Teknologi
🧱 Database Engine	MySQL & PostgreSQL
💬 Query Language	SQL / PLpgSQL
🧰 Development Tool	DBeaver
🔄 ETL Framework	Manual SQL Script (Transform & Load)
📊 Visualization Ready	Mendukung integrasi dengan BI Tools seperti Power BI / Metabase
📈 Hasil Analisis

Setelah seluruh proses dijalankan, Data Warehouse menghasilkan berbagai laporan dan validasi yang berguna, di antaranya:

🧩 Data Quality Validation

✅ Record Count Summary: memastikan jumlah baris antara OLTP dan DWH sinkron.

📅 Date Range Coverage: memverifikasi rentang waktu transaksi penjualan & pembelian.

⚠️ Integrity Check: mendeteksi orphan record, duplikasi, dan nilai negatif.

💹 Business Intelligence Insights

📆 Monthly Sales Performance: menampilkan pendapatan, laba, dan margin tiap bulan.

👟 Top 10 Best Selling Products: menyoroti produk sepatu paling laris dan paling menguntungkan.

🏪 Sales by Store: menganalisis performa tiap cabang toko berdasarkan pendapatan.

🧍 Customer Segmentation: membedakan pelanggan berdasarkan gender dan segmen pembelian.

📍 Sales by City: melihat kontribusi geografis penjualan di berbagai kota dan provinsi.

👨‍💼 Employee Performance: mengevaluasi produktivitas pegawai berdasarkan total penjualan.

💳 Payment Method Analysis: mengukur preferensi metode pembayaran pelanggan.

📏 Product Size Popularity: mengetahui ukuran sepatu yang paling banyak terjual.

📦 Inventory Turnover: membandingkan volume pembelian dan penjualan untuk mengukur perputaran stok.

💰 Discount Impact: menganalisis efek diskon terhadap margin dan volume penjualan.

🌟 Product Profitability Matrix: mengklasifikasikan produk menjadi Star Product, Cash Cow, Niche Product, atau Dog Product berdasarkan profitabilitas.

🧾 Ringkasan Eksekutif
Metrik	Nilai	Satuan
💸 Total Penjualan	SUM(subtotal_penjualan)	IDR
💰 Total Profit	SUM(total_profit)	IDR
📈 Average Margin	AVG(profit_margin_persen)	%
🛍️ Total Transactions	COUNT(penjualan_id)	transaksi
👥 Total Customers	COUNT(pelanggan_key)	pelanggan
👟 Total Products Sold	SUM(jumlah_qty)	unit
💳 Avg Transaction Value	AVG(subtotal_penjualan)	IDR

Semua query pada file 03_Query_Analytic.sql telah diverifikasi untuk memberikan validasi dan insight bisnis yang konsisten, siap digunakan untuk dashboard BI atau laporan eksekutif.
