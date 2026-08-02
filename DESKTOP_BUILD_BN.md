# INVESTIGO Desktop Build — বাংলা নির্দেশিকা

## GitHub Actions build

v195 patch push হলে দুইটি workflow চলবে:

1. `Build Android APK`
2. `Build Windows Desktop`

Windows workflow সফল হলে Artifacts অংশে `INVESTIGO-Windows-v195` পাওয়া যাবে।

## চালানোর নিয়ম

1. Artifact ZIP download ও extract করুন।
2. Extracted folder-এর DLL এবং data folder একই জায়গায় রাখুন।
3. `INVESTIGO.exe` চালান।
4. কেবল নিজের trusted GitHub build-এর ক্ষেত্রে Windows SmartScreen যাচাই করে
   প্রয়োজন হলে `More info` → `Run anyway` ব্যবহার করুন।

## Windows verification checklist

- App launch এবং officer profile load
- Bengali/English language switch
- New Case ও Case Detail
- CD create/save/preview
- PDF preview/print/share
- DOC export এবং Word/LibreOffice-এ open
- UD এবং NCR
- Backup export/import
- App restart-এর পরে local data persistence

v195 একটি desktop foundation release। GitHub Actions build এবং Windows device
verification শেষ না হওয়া পর্যন্ত এটি production-final desktop release নয়।
