# Project: Personal Finance & Saving App (Flutter + Supabase)

## 1. Overview

Aplikasi mobile Flutter untuk:
- Mencatat pemasukan dan pengeluaran pribadi (cashflow harian).
- Mengelola tabungan:
  - Tabungan pribadi (per tujuan).
  - Tabungan bersama (group saving dengan anggota dan target per anggota).

User saat ini diasumsikan **satu orang per device**, tanpa proses login/auth.

## 2. High-Level Modes

Home memiliki **switch utama**:

- Mode 1: **Keuangan (Cashflow Pribadi)**
- Mode 2: **Tabungan (Savings)**

### 2.1. Mode 1 – Keuangan (Cashflow Pribadi)

Fungsi:
- Mencatat transaksi:
  - Jenis: pemasukan / pengeluaran.
  - Tanggal transaksi.
  - Kategori (contoh: Makan, Transport, Belanja, Gaji, dll).
  - Nominal.
  - Catatan (opsional).

Tampilan:
- List transaksi (sorted by tanggal desc).
- Ringkasan:
  - Total pemasukan hari ini / bulan ini.
  - Total pengeluaran hari ini / bulan ini.
  - Saldo (pemasukan - pengeluaran).

### 2.2. Mode 2 – Tabungan

Di dalam Mode Tabungan, ada dua sub-mode (bisa berupa TabView):

1. Tabungan Pribadi
2. Tabungan Kelompok

#### 2.2.1. Tabungan Pribadi

Fungsi:
- Membuat beberapa tujuan tabungan, contoh:
  - "Laptop baru"
  - "Dana darurat"
- Setiap tujuan punya:
  - Nama tujuan.
  - Deskripsi (opsional).
  - Target nominal.
  - Deadline (opsional).
- Mencatat transaksi tabungan:
  - Jenis: setor (deposit) / tarik (withdraw).
  - Nominal.
  - Catatan (opsional).

Tampilan:
- List tujuan tabungan dengan:
  - Nama tujuan.
  - Progress bar: total terkumpul / target.
  - Nominal terkumpul dan target.
- Detail tujuan:
  - Ringkasan progress.
  - List transaksi tabungan tujuan tersebut.

#### 2.2.2. Tabungan Kelompok

Konsep:
- User adalah **admin** untuk satu atau beberapa kelompok tabungan.
- Setiap kelompok punya:
  - Nama kelompok (misal: "Liburan Jogja Bareng").
  - Deskripsi (opsional).
  - Target total (misal: 7.000.000).
  - Deadline (opsional).
- Admin bisa menambah anggota:
  - Nama anggota.
  - Target per anggota (opsional, kalau kosong bisa diisi dengan logika: target_total / jumlah_anggota).
- Admin dapat mencatat transaksi per anggota:
  - Pilih kelompok.
  - Pilih anggota.
  - Jenis: setor (deposit) / tarik (withdraw).
  - Nominal.
  - Catatan (opsional).

Tampilan:
- List kelompok tabungan:
  - Nama, target total, total terkumpul, jumlah anggota.
- Detail kelompok (tab layout):
  - **Ringkasan**:
    - Target total.
    - Total terkumpul.
    - Progress bar.
  - **Anggota**:
    - List anggota dengan:
      - Nama.
      - Target per anggota (jika ada).
      - Total yang sudah disetor anggota.
      - Sisa target anggota.
  - **Transaksi**:
    - List semua transaksi kelompok (bisa difilter per anggota).

## 3. Screens & Navigation

### 3.1. HomeScreen

- AppBar:
  - Title: berubah sesuai mode (`Keuangan` / `Tabungan`).
- Body:
  - Switch:
    - Label kiri: "Keuangan"
    - Label kanan: "Tabungan"
  - Konten:
    - Jika mode `Keuangan` → tampil `PersonalCashflowView`.
    - Jika mode `Tabungan` → tampil `SavingsView`.

### 3.2. PersonalCashflowView

- Komponen:
  - Ringkasan keuangan (income, expense, balance).
  - List transaksi.
  - Floating Action Button (FAB) untuk tambah transaksi.
- Tambah transaksi:
  - Form (bottom sheet atau screen baru):
    - Date picker.
    - Dropdown type: pemasukan / pengeluaran.
    - Input kategori.
    - Input nominal.
    - Input catatan.

### 3.3. SavingsView

- `DefaultTabController` dengan 2 tab:
  - Tab 1: "Pribadi"
  - Tab 2: "Kelompok"

#### 3.3.1. SavingsPersonalView

- List tujuan tabungan.
- FAB → buat tujuan tabungan baru.
- Tap item → buka detail tujuan.

Detail tujuan:
- Ringkasan (progress, target, terkumpul).
- List transaksi.
- FAB → tambah transaksi (deposit/withdraw).

#### 3.3.2. SavingsGroupView

- List kelompok tabungan.
- FAB → buat kelompok baru.
- Tap item → buka GroupDetailScreen.

GroupDetailScreen:
- Header: nama kelompok + ringkasan (target total / terkumpul / progress).
- Tab 1: Ringkasan (global).
- Tab 2: Anggota (list anggota + progress per anggota).
- Tab 3: Transaksi (list transaksi).
- FAB → tambah transaksi:
  - Pilih anggota (dropdown).
  - Input nominal.
  - Jenis: setor / tarik.
  - Catatan.

## 4. Non-Goals (untuk saat ini)

- Tidak ada sistem login/auth.
- Tidak ada multi-device sync per account.
- Tidak ada notifikasi push.
- Tidak ada export ke PDF/Excel (future feature).

## 5. Data & Rules

- Semua nilai uang disimpan sebagai `numeric` di database.
- Field `type` memakai string dengan nilai terbatas:
  - Cashflow: `'income'`, `'expense'`.
  - Savings: `'deposit'`, `'withdraw'`.
- Perhitungan progress selalu dilakukan di layer aplikasi (atau via query agregasi).
