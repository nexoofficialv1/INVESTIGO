# Online Backend Plan — Custom Server + PostgreSQL

Final architecture:

Mobile App / Web App → Node.js API Server → PostgreSQL → File Storage

## App behavior
- Default mode: Offline only
- Settings → Backend Server Setup
- Manually enter API Base URL, API Token, File Upload URL
- Test connection
- Enable sync
- Upload existing local cases

## First phase included
- Custom backend settings screen
- Test `/health`
- Upload local cases to backend
- Node.js Express backend
- PostgreSQL schema
- Basic web panel to view cases

## Later phases
- Auth login UI
- CD/statement/forms/evidence/sketch full sync
- PDF/DOC upload
- Conflict handling
- Audit log UI
- Web editing
