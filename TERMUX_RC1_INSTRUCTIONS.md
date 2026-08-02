# Termux: one-time RC-1 GitHub push

Install requirements once:

```bash
pkg update -y
pkg install git unzip rsync python -y
termux-setup-storage
```

Extract and push:

```bash
cd /sdcard/Download
unzip -o INVESTIGO_RC1_SOURCE.zip
cd INVESTIGO_RC1_SOURCE
bash PUSH_RC1_TO_GITHUB.sh
```

Then open GitHub → `nexoofficialv1/INVESTIGO` → Actions → Build Android APK.

Download `INVESTIGO-debug-apk` first for testing. Use the release artifact only after the RC checklist is completed.
