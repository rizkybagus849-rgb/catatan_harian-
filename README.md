# Catatan Harian (Flutter)

Aplikasi mobile sederhana untuk menyimpan catatan harian beserta tanggal dan jam pembuatannya.

## Paket yang digunakan
| Paket | Fungsi di aplikasi |
|---|---|
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Menyimpan daftar catatan (JSON) di penyimpanan lokal perangkat, sehingga data tetap ada setelah aplikasi ditutup |
| [`intl`](https://pub.dev/packages/intl) | Memformat tanggal & jam dalam bahasa Indonesia (mis. "Selasa, 3 November 2026 • 09:15") |

## Fitur
- Menambah catatan (judul + isi) dengan tanggal otomatis
- Menampilkan tanggal hari ini dan jumlah catatan
- Mengedit catatan (ketuk kartu catatan)
- Menghapus catatan (geser ke kiri, konfirmasi, ada tombol URUNGKAN)
- Data tersimpan permanen

## Cara menjalankan
```bash
flutter create .        # sekali saja: membuat folder android/ios/dll (file lib & pubspec tidak ditimpa)
flutter pub get
flutter run             # pilih emulator / perangkat Android
flutter test            # menjalankan widget test
```

## Struktur
```
lib/main.dart          -> Model, penyimpanan, halaman utama, halaman editor
test/widget_test.dart  -> Uji otomatis tambah catatan
pubspec.yaml           -> Dependencies
```

## Skenario pengujian (isi kolom Hasil & tempel screenshot)
| No | Skenario | Hasil yang diharapkan | Hasil | Screenshot |
|---|---|---|---|---|
| 1 | Buka aplikasi pertama kali | Tampil pesan "Belum ada catatan" & tanggal hari ini | | |
| 2 | Tambah catatan dengan judul & isi | Catatan muncul di daftar beserta tanggal & jam | | |
| 3 | Simpan catatan dengan judul kosong | Muncul pesan "Judul wajib diisi" | | |
| 4 | Edit catatan | Perubahan tersimpan, tanggal asli tetap | | |
| 5 | Hapus catatan (geser kiri) | Muncul konfirmasi, catatan hilang dari daftar | | |
| 6 | Klik URUNGKAN setelah hapus | Catatan kembali | | |
| 7 | Tutup lalu buka ulang aplikasi | Semua catatan masih ada (shared_preferences) | | |
