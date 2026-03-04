# Mobile Cashier (Kasir Pintar) 📱💰

Aplikasi Point of Sale (POS) mobile berbasis Flutter yang dirancang untuk membantu UMKM mengelola penjualan, stok barang, dan laporan keuangan secara real-time dan efisien.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Fitur Utama

- **Layar POS Modern**: Keranjang belanja interaktif dengan dukungan diskon dan berbagai metode pembayaran.
- **Scanner Barcode Terintegrasi**: Tambahkan produk ke keranjang hanya dengan memindai barcode/SKU menggunakan kamera.
- **Manajemen Stok Real-time**: 
  - Update stok otomatis setiap transaksi.
  - Fitur stok opname manual dengan alasan penyesuaian.
  - Riwayat pergerakan stok lengkap (sales, adjustment, return).
- **Laporan & Analitik**: Grafik pendapatan harian/mingguan/bulanan yang akurat serta ringkasan statistik penjualan.
- **Manajemen Produk Kompleks**: Dukungan kategori, mata uang IDR otomatis, dan peringatan stok menipis.
- **Keamanan PIN**: Keamanan akses akun menggunakan sistem PIN 6-digit.
- **Manajemen Pelanggan & Pegawai**: Database pelanggan setia dan pembagian peran (Admin, Kasir, Manager).

## 🚀 Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev) (v3.0+)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Local Database**: [SQFlite](https://pub.dev/packages/sqflite)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Animations**: [Flutter Animate](https://pub.dev/packages/flutter_animate)
- **Networking**: [Cached Network Image](https://pub.dev/packages/cached_network_image)
- **Scanner**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner)

## 🛠️ Cara Menjalankan

### Prasyarat
- Flutter SDK (Versi terbaru disarankan)
- Android Studio / VS Code
- Git

### Instalasi
1. Clone repositori ini:
   ```bash
   git clone https://github.com/username/mobile_cashier.git
   ```
2. Masuk ke direktori proyek:
   ```bash
   cd mobile_cashier
   ```
3. Instal dependensi:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## 📸 Demo Tampilan (Draft)
*(Silakan tambahkan screenshot aplikasi Anda di sini)*

- **Dashboard**: Ringkasan penjualan dan produk stok rendah.
- **POS**: Transaksi cepat dengan scan barcode.
- **Stock Management**: Pantau aliran keluar-masuk barang.

## 📄 Lisensi
Distribusi di bawah lisensi MIT. Lihat `LICENSE` untuk informasi lebih lanjut.

---

