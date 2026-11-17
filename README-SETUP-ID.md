# SocialSync — Social Media Management Platform (ITSB)

Dashboard tim marketing ITSB untuk merencanakan, mencatat, dan menganalisis konten media sosial (Instagram, TikTok, LinkedIn, YouTube, Facebook).

- **Hosting:** GitHub Pages (file statis `index.html`)
- **Login & database:** Supabase Auth + PostgreSQL, dengan Row Level Security (RLS)
- **Sinkron antar-anggota:** Supabase Realtime
- **Anti-pause:** GitHub Actions `keepalive.yml` (ping Supabase tiap 3 hari)

---

## 1. Fitur

| Menu | Isi |
|---|---|
| **Overview** | Ringkasan KPI (kartu bisa diklik untuk detail), grafik konten, penambahan followers, aktivitas terbaru |
| **Content Calendar** | Kalender tayang konten + tenggat tugas (☐) |
| **My Tasks** | To-do tim: tugas, PIC, tenggat, prioritas, status |
| **Content Tracker** | Daftar konten (ide → tayang), impor massal CSV/Excel/JSON |
| **Analytics** | Performa per konten (views, likes, komentar, share, saves), impor massal |
| **Reports** | Laporan akun berkala Instagram & TikTok (7/14/28/30/60/90/365 hari) + perbandingan periode |
| **Audience** | Followers per platform + kalkulator hitung mundur |
| **Programs** | Checklist video per prodi |
| **Settings** | Target KPI, tanggal mulai pencatatan, Tempat Sampah, cadangan data |

Fitur umum: pencarian di header, **Tempat Sampah** (data terhapus disimpan 30 hari), **Batalkan / Ctrl+Z** untuk hapus/ubah/tambah terakhir, dan tampilan responsif (HP & laptop).

### Sumber file impor yang didukung
- **Instagram:** Meta Business Suite → Insights → Content → Export (CSV)
- **TikTok:** aplikasi TikTok → Pengaturan dan privasi → Akun → Unduh data Anda (format **JSON**). Ekspor TikTok Studio hanya memuat sebagian konten.
- **LinkedIn:** Analitik halaman → Ekspor (XLSX). Pilih sheet *POSTING POPULER* lalu *POSTING PALING BARU*.
- Konten yang sudah ada (link sama, atau judul + tanggal sama) tidak digandakan.

---

## 2. Hak akses (role)

| Role | Bisa |
|---|---|
| `owner` | Semua, termasuk menghapus data di level database |
| `editor` | Menambah, mengubah, menghapus (ke Tempat Sampah), impor |
| `viewer` | **Hanya melihat.** Tombol tambah/ubah/hapus/impor disembunyikan, dan database juga menolak perubahan (RLS) |

Role tampil di kanan atas header setelah login.

---

## 3. Pemasangan baru

### A. Supabase
1. Buat project di https://supabase.com/ (sebaiknya memakai akun/organisasi milik ITSB, bukan akun pribadi).
2. **SQL Editor** → jalankan seluruh isi `supabase/schema.sql`.
3. **Database → Publications → supabase_realtime** → aktifkan tabel `app_data`.
4. **Authentication → Providers → Email**: aktifkan. Matikan *public sign-ups* setelah akun tim dibuat.
5. **Authentication → URL Configuration**: isi Site URL & Redirect URL dengan alamat GitHub Pages, misalnya `https://USERNAME.github.io/dashboard-itsb/`.
6. **Authentication → Users → Add user**: buat akun anggota tim.
7. Daftarkan setiap akun ke workspace (ganti `UUID_USER` dengan UUID dari daftar Users):

```sql
insert into public.workspace_members (workspace_id, user_id, role)
values ('c4966757-b261-46af-846e-812b2412a75d', 'UUID_USER', 'owner');  -- atau 'editor' / 'viewer'
```

### B. GitHub
1. Repository → **Settings → Secrets and variables → Actions** → buat dua secret:
   - `SUPABASE_URL` = `https://xxxx.supabase.co` (tanpa spasi, tanpa `/` di akhir)
   - `SUPABASE_ANON_KEY` = **Publishable key** (`sb_publishable_...`) dari Project Settings → API Keys.
   **Jangan pernah memakai Secret key / `service_role`.**
2. **Settings → Pages → Source: GitHub Actions.**
3. Pastikan dua workflow ada di `.github/workflows/`: `deploy.yml` dan `keepalive.yml`.
4. Buka tab **Actions** → *Deploy ITSB Dashboard to GitHub Pages* → **Run workflow**. Tunggu ✅.
5. Buka tab **Actions** → *Supabase keepalive* → **Run workflow** sekali untuk tes (log "HTTP 401" itu normal).

---

## 4. Memperbarui project yang sudah berjalan

1. **Jika ada perubahan database**, jalankan ulang `supabase/schema.sql` di SQL Editor. File ini aman dijalankan berulang kali dan tidak menghapus data.
2. Unggah `index.html` baru: **Add file → Upload files → Commit changes**. Pastikan nama filenya persis `index.html` (bukan `index (1).html`).
3. Tunggu ✅ di tab Actions, lalu buka dashboard dan tekan **Ctrl + Shift + R**.

---

## 5. Perawatan rutin

| Kapan | Apa |
|---|---|
| Tiap minggu | **Settings → Cadangan data → Ekspor cadangan (JSON)**, simpan di Google Drive tim. Paket gratis Supabase tidak punya backup otomatis. |
| Tiap akhir bulan | Catat followers semua platform di **Audience**. |
| Tiap 1–2 bulan | Pastikan workflow *Supabase keepalive* masih aktif. GitHub menonaktifkan workflow terjadwal jika repo tidak ada commit selama 60 hari. |
| Saat pergantian pengelola | Tambahkan pengelola baru sebagai `owner`, dan sebagai collaborator di GitHub. |

---

## 6. Pemecahan masalah

**Supabase "Project is paused"** → Supabase Dashboard → *Resume project*. Lalu cek workflow keepalive.

**Klik "Masuk" tidak terjadi apa-apa** → tekan F12 → Console. Jika muncul `Invalid supabaseUrl`, perbaiki secret `SUPABASE_URL`, lalu jalankan ulang deploy.

**"Akun berhasil login, tetapi belum memiliki akses"** → akun belum terdaftar di `workspace_members` (lihat langkah 3A.7).

**"Gagal menyimpan ke cloud"** → biasanya `schema.sql` versi terbaru belum dijalankan, atau akun berstatus `viewer`.

**Lupa password** → Supabase SQL Editor (ganti email & password baru):

```sql
update auth.users
set encrypted_password = extensions.crypt('PasswordBaru123!', extensions.gen_salt('bf')),
    updated_at = now()
where email = 'email@itsb.ac.id';
```

**Cek akun & role:**

```sql
select u.email, m.role
from auth.users u
left join public.workspace_members m on m.user_id = u.id;
```

---

## 7. Keamanan & batasan

- Publishable/anon key memang dirancang untuk dipakai di browser. Yang membatasi akses adalah RLS. Jangan memasukkan `service_role`/secret key ke website atau GitHub.
- Data tiap modul disimpan sebagai satu dokumen JSON. Jika dua orang menyimpan modul yang sama pada detik yang hampir bersamaan, simpanan terakhir bisa menimpa yang sebelumnya. Untuk tim besar, sebaiknya dimigrasikan ke tabel per baris.
- Angka followers bulan lalu dari kalkulator hitung mundur adalah **perkiraan**. Data LinkedIn hanya menghitung pengikut baru (tanpa yang berhenti mengikuti).
- Definisi "views" berbeda antar platform, jadi engagement rate antar platform tidak bisa dibandingkan secara langsung.
- Library eksternal dikunci versinya: supabase-js 2.119.0, Chart.js 4.4.1, SheetJS 0.20.3 (cadangan 0.18.5 bila CDN SheetJS tidak bisa diakses).
