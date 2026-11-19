// Render build step: tulis public/config.js daripada Environment Variables.
// Kunci "anon" memang direka untuk umum (dilindungi oleh RLS), tetapi kunci service_role TIDAK BOLEH digunakan di sini.
const fs = require('fs');
const url = (process.env.SUPABASE_URL || '').trim();
const key = (process.env.SUPABASE_ANON_KEY || '').trim();

if (!url || !key) {
  console.warn('SUPABASE_URL / SUPABASE_ANON_KEY tidak ditetapkan. Aplikasi akan minta nilai ini di skrin pertama.');
} else {
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.(co|in)\/?$/i.test(url)) { console.error('SUPABASE_URL tidak sah: ' + url); process.exit(1); }
  try {
    const role = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString()).role;
    if (role === 'service_role') { console.error('BERHENTI: ini kunci service_role. Guna kunci anon/publishable sahaja.'); process.exit(1); }
  } catch (e) { /* kunci format baharu (sb_publishable_...) bukan JWT, itu OK */ }
  if (/^sb_secret_/.test(key)) { console.error('BERHENTI: ini kunci secret. Guna kunci anon/publishable sahaja.'); process.exit(1); }
}
const out = 'window.APP_CONFIG = ' + JSON.stringify({ SUPABASE_URL: url.replace(/\/$/, ''), SUPABASE_ANON_KEY: key }) + ';\n';
fs.writeFileSync(__dirname + '/public/config.js', out);
console.log('public/config.js ditulis (' + (url ? 'Supabase ditetapkan' : 'kosong') + ').');
