# Cashly V2

Cashly V2 adalah aplikasi Flutter + Supabase untuk mencatat arus kas pribadi sekaligus mengelola tabungan pribadi dan kelompok. Basis data disiapkan di Supabase, state memakai Riverpod, dan arsitektur dipisahkan ke `presentation / application / domain / infrastructure`.

## Fitur Utama
- Keuangan (cashflow): tambah pemasukan/pengeluaran dengan tanggal, kategori, dan catatan; ringkasan harian & bulanan; grafik mingguan; filter transaksi per tanggal; preset nominal cepat.
- Tabungan pribadi: buat tujuan dengan target & deadline; progress bar; detail transaksi setor/tarik; pull-to-refresh.
- Tabungan kelompok: buat kelompok dengan target total; tambah anggota (dengan target per anggota opsional); catat setor/tarik per anggota; ringkasan kontribusi & jumlah anggota; avatar anggota/kelompok opsional.
- Integrasi Supabase: seluruh data transaksi & tabungan tersimpan di tabel/view Supabase (lihat ERD di `Project_knowledge/ERD.md` dan skema di `Project_knowledge/finance_schema.sql.md`).
- Tech: Flutter 3.x (Dart ^3.9.2), Riverpod 3, Supabase Flutter 2.x, Google Fonts; GoRouter sudah terpasang bila ingin menambah rute.

## Struktur Repo
- `finance_app_cashlyv2/` — kode aplikasi Flutter.
- `Project_knowledge/` — PRD, ERD, dan dokumen skema database.
- `LICENSE`, `.gitignore`, `.vscode/` — housekeeping.

## Menjalankan Aplikasi
1) Pastikan Flutter 3.x terpasang (`flutter doctor`).
2) Masuk ke folder aplikasi dan ambil dependency:
   ```bash
   cd finance_app_cashlyv2
   flutter pub get
   ```
3) Siapkan kredensial Supabase (disarankan via `--dart-define`):
   ```bash
   flutter run ^
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co ^
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```
   Jika tidak diisi, nilai default di `lib/core/env.dart` akan dipakai (berisi key dev bawaan).
4) Jalankan di emulator/perangkat:
   ```bash
   flutter run
   ```

## Schema & Data
- Tabel utama: `cash_transactions`, `personal_saving_goals`, `personal_saving_entries`, `saving_groups`, `saving_group_members`, `saving_group_entries`.
- View ringkasan: `vw_cash_rollup`, `vw_recent_cash_transactions`, `vw_personal_goal_summary`, `vw_saving_group_summary`, `vw_saving_group_member_summary`.
- Detail ERD dan definisi kolom tersedia di `Project_knowledge/ERD.md` dan `Project_knowledge/finance_schema.sql.md`.

## Testing & Kualitas
- Jalankan pengujian: `flutter test`.
- Lint mengikuti `analysis_options.yaml` dan `flutter_lints`.

## Catatan Pengembangan
- Provider penting ada di `finance_app_cashlyv2/lib/application/providers.dart`.
- Repositori Supabase berada di `finance_app_cashlyv2/lib/infrastructure/supabase/`.
- Aset ikon/logo berada di `finance_app_cashlyv2/assets/`.
- Tidak ada autentikasi; diasumsikan satu pengguna per perangkat.
