import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import multer from 'multer';
import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import path from 'path';

const app = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const uploadDir = process.env.UPLOAD_DIR || 'uploads';
fs.mkdirSync(uploadDir, { recursive: true });
const upload = multer({ dest: uploadDir });

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '25mb' }));
app.use('/files', express.static(uploadDir));

const jwtSecret = process.env.JWT_SECRET || 'dev-secret-change-me';
const staticToken = process.env.API_TOKEN || '';

function tokenFor(officer) {
  return jwt.sign({ officerId: officer.id, email: officer.email }, jwtSecret, { expiresIn: '30d' });
}

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (staticToken && token === staticToken) {
    req.officerId = null;
    return next();
  }
  if (!token) return res.status(401).json({ error: 'Missing bearer token' });
  try {
    const payload = jwt.verify(token, jwtSecret);
    req.officerId = payload.officerId;
    return next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

app.get('/health', async (_req, res) => {
  const r = await pool.query('select now() as now');
  res.json({ ok: true, app: 'Investigation & Process Backend', time: r.rows[0].now });
});

app.post('/auth/register', async (req, res) => {
  const { email, password, profile = {} } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password required' });
  const hash = await bcrypt.hash(password, 10);
  const r = await pool.query(
    `insert into officers(email,password_hash,name,rank,police_station,district,mobile,raw_profile)
     values($1,$2,$3,$4,$5,$6,$7,$8)
     returning id,email,name,rank,police_station,district,mobile,raw_profile`,
    [email, hash, profile.name || '', profile.rank || '', profile.policeStation || profile.police_station || '', profile.district || '', profile.mobile || '', profile]
  );
  res.json({ officer: r.rows[0], token: tokenFor(r.rows[0]) });
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const r = await pool.query('select * from officers where email=$1', [email]);
  if (!r.rowCount) return res.status(401).json({ error: 'Invalid login' });
  const officer = r.rows[0];
  const ok = await bcrypt.compare(password || '', officer.password_hash || '');
  if (!ok) return res.status(401).json({ error: 'Invalid login' });
  res.json({ officer, token: tokenFor(officer) });
});

app.post('/api/sync/cases', requireAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('begin');
    let officerId = req.officerId;
    const officer = req.body.officer || {};
    if (!officerId) {
      const email = officer.email || `local-${uuidv4()}@local`;
      const up = await client.query(
        `insert into officers(email,name,rank,police_station,district,mobile,raw_profile)
         values($1,$2,$3,$4,$5,$6,$7)
         on conflict(email) do update set raw_profile=excluded.raw_profile, updated_at=now()
         returning id`,
        [email, officer.name || '', officer.rank || '', officer.policeStation || '', officer.district || '', officer.mobile || '', officer]
      );
      officerId = up.rows[0].id;
    }
    const cases = Array.isArray(req.body.cases) ? req.body.cases : [];
    for (const c of cases) {
      await client.query(
        `insert into cases(id,officer_id,ps_case_no,case_date,sections,complainant_name,accused_name,po,do_text,dr_text,gist,raw_data,updated_at)
         values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,now())
         on conflict(id) do update set
          ps_case_no=excluded.ps_case_no, case_date=excluded.case_date, sections=excluded.sections,
          complainant_name=excluded.complainant_name, accused_name=excluded.accused_name,
          po=excluded.po, do_text=excluded.do_text, dr_text=excluded.dr_text, gist=excluded.gist,
          raw_data=excluded.raw_data, updated_at=now()`,
        [
          c.id, officerId, c.psCaseNo || c.caseNo || '', c.caseDate || '', c.sections || '',
          c.complainantName || '', c.accusedName || '', c.placeOfOccurrence || c.po || '',
          c.dateOfOccurrence || c.doText || '', c.dateOfReporting || c.drText || '', c.gist || '', c,
        ]
      );
    }
    await client.query('insert into sync_logs(officer_id, action, status, message) values($1,$2,$3,$4)', [officerId, 'sync_cases', 'ok', `Synced ${cases.length} cases`]);
    await client.query('commit');
    res.json({ ok: true, count: cases.length });
  } catch (e) {
    await client.query('rollback');
    res.status(500).json({ error: e.message });
  } finally {
    client.release();
  }
});

app.get('/api/cases', requireAuth, async (req, res) => {
  const r = await pool.query('select * from cases where ($1::uuid is null or officer_id=$1) order by updated_at desc', [req.officerId]);
  res.json({ cases: r.rows });
});

app.post('/api/files', requireAuth, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'file required' });
  const caseId = req.body.case_id || null;
  const sourceType = req.body.source_type || 'document';
  const fileName = req.file.originalname || req.file.filename;
  await pool.query(
    'insert into generated_files(officer_id,case_id,source_type,source_id,file_name,mime_type,file_path) values($1,$2,$3,$4,$5,$6,$7)',
    [req.officerId, caseId, sourceType, req.body.source_id || null, fileName, req.file.mimetype, req.file.path]
  );
  res.json({ ok: true, file: { name: fileName, url: `/files/${path.basename(req.file.path)}` } });
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log(`Investigation backend running on ${port}`));

app.post('/api/license/request', requireAuth, async (req, res) => {
  const { plan = 'trial', fee_amount = '', payment_txn_id = '', activation_code = '', raw_data = {} } = req.body || {};
  const r = await pool.query(
    `insert into licenses(officer_id,plan,status,fee_amount,payment_txn_id,activation_code,raw_data)
     values($1,$2,$3,$4,$5,$6,$7)
     returning *`,
    [req.officerId, plan, 'pending_verification', fee_amount, payment_txn_id, activation_code, raw_data]
  );
  res.json({ ok: true, license: r.rows[0] });
});

app.get('/api/license/status', requireAuth, async (req, res) => {
  const r = await pool.query('select * from licenses where officer_id=$1 order by created_at desc limit 1', [req.officerId]);
  res.json({ license: r.rows[0] || null });
});
