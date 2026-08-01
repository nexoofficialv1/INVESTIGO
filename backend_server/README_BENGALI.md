# Investigation & Process Backend Server

এই backend ব্যবহার করলে app data নিজের server-এর PostgreSQL database-এ save হবে। একই data laptop/web app থেকেও দেখা যাবে।

## দরকার
- VPS বা hosting server
- Node.js 20+
- PostgreSQL 14+
- Domain/subdomain এবং SSL

## Setup

```bash
cd backend_server
cp .env.example .env
npm install
createdb investigation_process
psql "$DATABASE_URL" -f sql/schema.sql
npm start
```

## Test

Browser/Termux থেকে:

```bash
curl https://your-api-domain.com/health
```

App-এর Backend Settings screen-এ বসাবেন:

```text
Mode: Custom Server + PostgreSQL
API Base URL: https://your-api-domain.com
API Token: .env ফাইলের API_TOKEN অথবা login token
```

প্রথম phase-এ mobile app থেকে local cases upload হবে। পরের phase-এ CD, Statement, Forms, Evidence, Sketch Map, PDF/DOC file upload sync হবে।
