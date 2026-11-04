# ITSB Social Media Dashboard — GitHub Pages + Supabase

Dashboard single-page ini memakai GitHub Pages untuk hosting dan Supabase Auth + PostgreSQL untuk login serta penyimpanan bersama. Semua anggota dalam workspace yang sama melihat data yang sama.

## Arsitektur
- GitHub Pages: file statis `index.html` (kode website).
- Supabase Auth: login email/password untuk admin tim.
- Supabase `app_data`: data JSON per modul (`settings`, `tracker`, `insight`, `followers`, `prodi`).
- Supabase `workspace_members`: daftar anggota dan role (`owner`, `editor`, `viewer`).
- Row Level Security (RLS): user hanya bisa membaca workspace tempat dia terdaftar; editor/owner dapat mengubah data; viewer hanya membaca.
- Supabase Realtime: perubahan anggota lain ditampilkan otomatis.

## A. Siapkan Supabase
1. Buat project di https://supabase.com/ (gunakan organisasi ITSB bila tersedia).
2. Buka SQL Editor, jalankan seluruh isi `supabase/schema.sql`.
3. Buka Project Settings → API. Salin Project URL dan anon/publishable key. **Jangan pernah memasukkan `service_role` key ke website atau GitHub.**
4. Buka Authentication → Providers → Email, aktifkan Email provider. Nonaktifkan public sign-ups setelah akun tim dibuat/diundang.
5. Buka Authentication → URL Configuration. Tambahkan URL GitHub Pages ke Site URL dan Redirect URLs, misalnya `https://USERNAME.github.io/REPOSITORY/`.
6. Undang anggota tim melalui Authentication → Users → Add user / Invite user. Atur password sesuai kebijakan ITSB.
7. Salin UUID setiap user dari daftar Users. Di SQL Editor jalankan insert berikut untuk setiap anggota (gunakan workspace ID di bawah).

Workspace ID: `c4966757-b261-46af-846e-812b2412a75d`

```sql
insert into public.workspace_members (workspace_id, user_id, role)
values ('c4966757-b261-46af-846e-812b2412a75d', 'UUID_USER', 'owner'); -- owner pertama
-- Untuk anggota lain, gunakan role 'editor' atau 'viewer'.
```

8. Di Database → Publications, pastikan tabel `app_data` masuk ke publication `supabase_realtime`.

## B. Konfigurasi website
1. Duplikat `config.example.js` menjadi `config.js`.
2. Isi `url` dan `anonKey` dari Supabase. `workspaceId` sudah disediakan; jangan diubah kecuali schema dan seluruh akun anggota juga disesuaikan.
3. Simpan `SUPABASE_URL` dan `SUPABASE_ANON_KEY` sebagai GitHub Actions Secrets: Repository → Settings → Secrets and variables → Actions → New repository secret. Nama secret harus persis sama. Anon/publishable key memang dirancang untuk frontend; RLS-lah yang membatasi akses. **Jangan gunakan `service_role` key.**

## C. Deploy ke GitHub Pages
1. Buat repository GitHub, misalnya `itsb-social-media-dashboard`.
2. Upload seluruh isi folder ini ke root repository.
3. Pastikan workflow `.github/workflows/deploy.yml` ikut terunggah. Workflow akan membuat `config.js` ketika deployment berjalan.
4. Repository → Settings → Pages → Build and deployment → Source: **GitHub Actions**.
5. Tunggu deployment selesai, lalu buka URL GitHub Pages.
6. Uji login dengan dua akun berbeda dan pastikan data yang ditambahkan di akun pertama muncul di akun kedua.

## D. Cara kerja data dan migrasi
- Saat pertama login, dashboard mengambil data workspace dari Supabase.
- Jika suatu key belum ada di cloud, dashboard mencoba mengimpor salinan `localStorage` dari browser tersebut satu kali untuk key itu. Jika dashboard lama dibuka dengan alamat `file://` atau origin berbeda, browser tidak membagikan localStorage antar-origin. Dalam kondisi itu, ekspor data lama dari browser lama terlebih dahulu, lalu gunakan Pengaturan → Cadangan data → pilih file JSON pada dashboard baru. Jangan mulai input data baru sebelum migrasi selesai.
- Setelah itu, perubahan disimpan ke Supabase dan dibagikan ke seluruh anggota workspace.
- Fitur Pengaturan → Cadangan data mengunduh JSON untuk backup manual.

## Keamanan & batasan
- Jangan pernah commit password, service-role key, access token, atau kredensial admin.
- GitHub Pages bersifat hosting statis; data tidak disimpan di GitHub. Data operasional disimpan di Supabase.
- Untuk penggunaan internal, batasi anggota lewat Supabase Auth + `workspace_members`; jangan mengandalkan repository privat sebagai pengamanan data aplikasi.
- Saat ini data tiap modul disimpan sebagai satu dokumen JSON per workspace. Ini sesuai untuk dashboard tim kecil/menengah; jika kelak butuh audit trail, histori perubahan per baris, approval, atau data sangat besar, migrasikan ke tabel relasional.
- Jangan jalankan dua versi dashboard berbeda untuk workspace yang sama sebelum memastikan skema datanya kompatibel.
