CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS officers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  mobile TEXT,
  password_hash TEXT,
  name TEXT NOT NULL DEFAULT '',
  rank TEXT NOT NULL DEFAULT '',
  police_station TEXT NOT NULL DEFAULT '',
  district TEXT NOT NULL DEFAULT '',
  raw_profile JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cases (
  id TEXT PRIMARY KEY,
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  ps_case_no TEXT,
  case_date TEXT,
  sections TEXT,
  complainant_name TEXT,
  accused_name TEXT,
  po TEXT,
  do_text TEXT,
  dr_text TEXT,
  gist TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cd_entries (
  id TEXT PRIMARY KEY,
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  case_id TEXT REFERENCES cases(id) ON DELETE CASCADE,
  cd_no INTEGER,
  entry_no TEXT,
  entry_time TEXT,
  place_of_entry TEXT,
  synopsis_of_entry TEXT,
  proceedings_body TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS statements (
  id TEXT PRIMARY KEY,
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  case_id TEXT REFERENCES cases(id) ON DELETE CASCADE,
  witness_name TEXT,
  body TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS forms_notices (
  id TEXT PRIMARY KEY,
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  case_id TEXT REFERENCES cases(id) ON DELETE CASCADE,
  form_type TEXT,
  title TEXT,
  body TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS evidence_items (
  id TEXT PRIMARY KEY,
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  case_id TEXT REFERENCES cases(id) ON DELETE CASCADE,
  evidence_type TEXT,
  title TEXT,
  details TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sketch_maps (
  id TEXT PRIMARY KEY,
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  case_id TEXT REFERENCES cases(id) ON DELETE CASCADE,
  title TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS generated_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  case_id TEXT REFERENCES cases(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL,
  source_id TEXT,
  file_name TEXT NOT NULL,
  mime_type TEXT,
  file_path TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sync_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  officer_id UUID REFERENCES officers(id) ON DELETE SET NULL,
  device_id TEXT,
  action TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cases_officer ON cases(officer_id);
CREATE INDEX IF NOT EXISTS idx_cd_entries_case ON cd_entries(case_id);
CREATE INDEX IF NOT EXISTS idx_forms_case ON forms_notices(case_id);

CREATE TABLE IF NOT EXISTS licenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  officer_id UUID REFERENCES officers(id) ON DELETE CASCADE,
  plan TEXT NOT NULL DEFAULT 'trial',
  status TEXT NOT NULL DEFAULT 'pending',
  fee_amount TEXT,
  activation_code TEXT,
  payment_txn_id TEXT,
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS backup_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  officer_id UUID REFERENCES officers(id) ON DELETE SET NULL,
  backup_type TEXT NOT NULL DEFAULT 'local_json',
  file_name TEXT,
  message TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
