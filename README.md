# CPAP Data Manager — Render + Supabase (paparan gaya OSCAR)

Aplikasi web (static site) untuk membaca data kad SD ResMed AirSense 10.

## Cara ia berfungsi
1. Pengguna pilih folder kad SD (`STR.edf` + `DATALOG`) di browser.
2. JavaScript di browser membaca fail EDF dan hanya mengekstrak ringkasan:
   - **STR.edf:** tempoh guna, mask on/off, AHI/AI/HI, **tetapan mesin** (mod, EPR, julat tekanan, ramp).
   - **PLD.edf (2 saat):** tekanan topeng, tekanan EPR, tekanan sasaran, leak, kadar pernafasan, isi padu tidal, ventilasi minit, snore, flow limitation. Daripada data penuh ini dikira **min / median / 90% / 95% / maks / purata** setiap malam, dan graf disimpan sebagai **purata setiap 1 minit**.
   - **EVE.edf:** setiap apnea (OA, CA, UA), hypopnea dan RERA dengan masa dan tempoh.
   - **CSL.edf:** tempoh Cheyne-Stokes (jika ada).
3. Hanya ringkasan itu dihantar ke Supabase. Fail `.edf` mentah **tidak** dimuat naik.

Saiz: kira-kira 20–30 KB satu malam, jadi 10 tahun ≈ 70–110 MB (had pelan percuma Supabase ialah 500 MB). Untuk lebih kecil, ubah `SERIES_STEP` di bahagian atas skrip `public/index.html` (2 = separuh saiz, 5 = satu perlima).

## Skrin
- **Overview:** trend guna, event/jam mengikut jenis (OA/CA/H/UA/RERA), tekanan, leak, kadar pernafasan, isi padu tidal, ventilasi minit, snore dan flow limitation.
- **Daily:** seperti paparan harian OSCAR. Carta bersusun dengan paksi masa yang sama (peristiwa, tekanan + EPR + sasaran, leak, kadar pernafasan, isi padu tidal, ventilasi minit, snore, flow limitation), zum 4 jam / 2 jam / 1 jam / 30 minit dengan penggelongsor, pecahan peristiwa, tetapan mesin, statistik isyarat malam itu, dan senarai peristiwa. Butang ← → untuk malam sebelum/seterusnya.
- **Statistics:** jadual Last night / 7 / 30 / 90 / 1 tahun / Semua (usaha, AHI, OA/CA/H/UA/RERA, RDI, tekanan, leak, pernafasan), serta jadual setiap malam dan eksport CSV.
- **Report:** laporan boleh cetak / simpan PDF untuk doktor.

## Dua gaya paparan (pilih di bahagian atas kanan)
Pilihan **OSCAR style / SleepHQ style** diingat oleh browser. Data yang sama, cara analisis berbeza.

| | OSCAR style | SleepHQ style |
|---|---|---|
| Tab | Overview, Daily, Statistics | Dashboard, Daily, Compare |
| Fokus | Butiran teknikal dan semua isyarat | Ringkasan mudah, skor, pemerhatian |
| Daily | Semua carta isyarat | Skor malam, pemerhatian, carta peristiwa + tekanan + leak. Butang "Show all signals" untuk selebihnya |

**SleepHQ style** merangkumi:
- **Therapy score (0–100):** penggunaan 40 mata, AHI 30, leak 20, berapa kali topeng ditanggalkan 10. Ini anggaran kami sendiri, **bukan** skor SleepHQ atau myAir.
- **Insights:** pemerhatian automatik dalam ayat biasa (patuhan 4 jam/70% malam, AHI dan trend, jenis peristiwa dominan, apnea pusat, leak tinggi, tekanan mencecah had maksimum, malam terbaik/terburuk).
- **Kalendar berwarna** mengikut guna / AHI / leak. Klik hari untuk buka malam itu.
- **Perbandingan dengan tempoh sebelumnya** (anak panah naik/turun hijau atau merah) pada kad Dashboard.
- **Compare:** banding dua julat tarikh bersebelahan (skor, guna, AHI, setiap jenis peristiwa, leak, tekanan, pernafasan) dengan perubahan dan peratus, serta carta peristiwa A lawan B.

SleepHQ ialah perkhidmatan berasingan dengan algoritma sendiri. Gaya ini terinspirasi oleh susun atur dan jenis ringkasan yang serupa, bukan salinan; skor dan pemerhatian dikira oleh aplikasi ini. Pemerhatian bukan nasihat perubatan.

## Tab Report (laporan klinik, boleh cetak / simpan PDF)
Pilih julat tarikh, tarikh temu janji (pilihan), tekan **Generate**, kemudian **Print / Save as PDF**. Laporan ada 7 bahagian dan pecah halaman dengan kemas:
1. **Therapy summary:** nama / tarikh lahir / temu janji, berapa malam berturut-turut ≥ 4 jam dan AHI < 5, "Worth raising with your doctor", patuhan (nota Medicare 4 jam / 70%), kad ringkasan (AHI, patuhan, guna median, leak, tekanan avg/P95, kadar pernafasan, isi padu tidal, peristiwa dominan) dan tetapan terkini.
2. **Findings:** item WATCH / NOTE (lonjakan leak, kadar pernafasan di luar 12–20, AHI ≥ 5, di bawah 4 jam, apnea pusat dominan, sebaran tekanan, leak biasa di bawah 24), "What's going well", "Nights that stood out" dan **Questions for your appointment** yang dijana daripada item WATCH.
3. **Period finding + Event distribution + Period trends** (dengan sparkline dan arah) dan **Most recent night** (jadual peristiwa, masa dalam apnea, leak/tekanan/pernafasan/isi padu/snore/flow limitation: purata, P95, maks).
4. **Nightly log:** setiap malam dengan bar skala AHI 0–5, jam, leak, P95, tekanan, peristiwa; median tempoh.
5. **Machine settings:** tetapan terkini dan **perubahan tetapan sepanjang tempoh**.
6. **Kalendar 90 malam** (AHI < 5 / 5–15 / 15–30 / 30+, boleh dibaca dalam cetakan hitam putih).
7. **Time-series malam terkini:** tekanan, leak (garisan 24 L/min dan minit di atasnya), kadar pernafasan (jalur rujukan 12–20), serta penafian.

Nama peranti dalam laporan datang daripada medan **Device model** pada tab Patients (cth. "AirSense 10 AutoSet").
Nota: kod tetapan yang aplikasi tidak pasti maknanya (cth. jenis tiub) dipaparkan sebagai "code N", bukan diteka. Semak nama Mask Type / EPR / Humidity pada laporan pertama dengan skrin mesin anda.

## Yang BELUM ada berbanding OSCAR
- **Gelombang aliran (flow waveform, 25 Hz dari fail BRP):** tidak disimpan kerana satu malam ≈ 2 juta titik (beratus MB untuk setahun). Beritahu jika mahu pilihan "lihat gelombang aliran daripada kad SD tanpa simpan".
- **Unintentional leak** (leak tolak ventilasi topeng): memerlukan profil topeng. Paparan ialah jumlah leak seperti di skrin mesin.
- Oksimetri (SAD.edf), dan bar penanda peristiwa pada gelombang aliran.

## Struktur
```
render.yaml        konfigurasi Render (static site)
build.js           tulis public/config.js daripada Environment Variables
schema.sql         jadual + keselamatan Supabase
public/index.html  aplikasi penuh
public/config.js   diganti semasa build
```

## Langkah 1: Supabase
1. Buat projek di supabase.com.
2. *SQL Editor* → *New query* → tampal seluruh `schema.sql` → *Run*.
   **Jika sudah jalankan versi lama:** jalankan semula fail ini. Ia selamat dan hanya menambah lajur baharu (event count, statistik, tetapan). Data lama kekal, tetapi untuk dapat graf penuh bagi malam lama, import semula kad SD dengan "Only import nights not already saved" **dinyahtanda**.
3. *Authentication* → *Providers* → Email: untuk ujian pantas, matikan *Confirm email*.
4. *Project Settings* → *API*: salin **Project URL** dan kunci **anon / publishable**. Jangan guna `service_role` atau `secret` (build menolaknya).

## Langkah 2: Render
1. Muat naik folder ini ke repositori GitHub.
2. Render → *New* → *Blueprint* → pilih repositori (membaca `render.yaml`). Atau *New* → *Static Site*: Build Command `node build.js`, Publish Directory `public`.
3. Isi Environment Variables: `SUPABASE_URL` dan `SUPABASE_ANON_KEY`.
4. *Deploy*, kemudian letak URL Render di Supabase → Authentication → URL Configuration → Site URL.

## Langkah 3: Guna
1. Buat akaun, tambah **Patient**.
2. **Import SD card** → pilih folder kad SD → *Read files* → semak pratonton (termasuk anggaran KB satu malam) → *Save to Supabase*.
3. Import semula pada masa depan selamat: hanya malam baharu ditambah.

Kad SD hanya menyimpan data terperinci untuk tempoh terhad, jadi import secara berkala (cth. sebulan sekali).

## Keselamatan
Row Level Security aktif: setiap akaun hanya nampak pesakitnya sendiri. Kunci anon memang boleh didedahkan kepada browser.

## Nota
- Diuji dengan fail EDF sintetik mengikut format ResMed dan data Supabase tiruan. Cuba dengan kad sebenar dan banding beberapa malam dengan OSCAR. Label isyarat, unit (leak L/s, isi padu L) dan nama peristiwa ialah tempat yang paling mungkin berbeza antara firmware.
- Paparan dalam Bahasa Inggeris. Boleh ditukar ke Bahasa Melayu jika perlu.
- Alat paparan data, bukan alat diagnosis.
