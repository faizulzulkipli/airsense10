# CPAP Data Manager — Render + Supabase

Aplikasi web (static site) untuk membaca data kad SD ResMed AirSense 10.

**Cara ia berfungsi**
1. Pengguna pilih folder kad SD (mengandungi `STR.edf` dan `DATALOG`) di browser.
2. JavaScript di browser membaca fail EDF dan mengekstrak ringkasan sahaja: tarikh, tempoh guna, tekanan median/95%/maks, leak median/95%/maks, AHI/AI/HI/OAI/CAI, serta titik graf diringkaskan (purata setiap 5 minit) dan senarai peristiwa apnea/hypopnea.
3. Hanya ringkasan itu dihantar ke Supabase PostgreSQL. Fail `.edf` mentah **tidak** dimuat naik ke mana-mana.
4. Satu malam ≈ 5–10 KB, jadi 10 tahun ≈ 20–40 MB (di bawah had 500 MB pelan percuma Supabase).

Render hanya menghos fail statik (`public/`). Tiada server, jadi tiada kos pelayan.

## Struktur
```
render.yaml        konfigurasi Render (static site)
build.js           tulis public/config.js daripada Environment Variables
schema.sql         jadual + keselamatan Supabase (jalankan sekali)
public/index.html  aplikasi penuh
public/config.js   diganti semasa build
```

## Langkah 1: Supabase
1. Buat projek di supabase.com.
2. *SQL Editor* → *New query* → tampal seluruh `schema.sql` → *Run*.
3. *Authentication* → *Providers* → Email: untuk ujian pantas, matikan *Confirm email*.
4. *Project Settings* → *API*: salin **Project URL** dan kunci **anon / publishable**.
   Jangan guna kunci `service_role` atau `secret` (build akan menolaknya).

## Langkah 2: Render
1. Muat naik folder ini ke repositori GitHub baharu.
2. Di render.com: *New* → *Blueprint* → pilih repositori (ia membaca `render.yaml`).
   (Atau *New* → *Static Site*: Build Command `node build.js`, Publish Directory `public`.)
3. Isi Environment Variables:
   - `SUPABASE_URL` = Project URL anda
   - `SUPABASE_ANON_KEY` = kunci anon/publishable
4. *Deploy*. Buka URL `.onrender.com` yang diberi.

Selepas itu, **Supabase → Authentication → URL Configuration → Site URL**: letak URL Render anda (perlu jika Confirm email dihidupkan).

## Langkah 3: Guna
1. Buat akaun, tambah **Patient**.
2. Tab **Import SD card** → pilih folder kad SD → *Read files* → semak pratonton → *Save to Supabase*.
3. Import semula pada masa depan selamat: hanya malam baharu ditambah.

Kad SD hanya menyimpan data terperinci untuk tempoh terhad, jadi import secara berkala (cth. sebulan sekali).

## Keselamatan
- Row Level Security aktif: setiap akaun hanya nampak pesakitnya sendiri.
- Kunci anon memang boleh didedahkan kepada browser; keselamatan data dijaga oleh RLS dan log masuk.

## Nota
- Ujian dibuat dengan fail EDF sintetik mengikut format ResMed. Cuba dengan kad sebenar dan banding beberapa malam dengan skrin mesin atau OSCAR.
- Paparan aplikasi dalam Bahasa Inggeris. Boleh ditukar ke Bahasa Melayu jika perlu.
- Ini alat paparan data, bukan alat diagnosis.
