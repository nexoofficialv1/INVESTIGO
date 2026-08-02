# Termux — one-time RC-1 push

```bash
pkg install git unzip rsync python -y
cd /sdcard/Download
unzip -o INVESTIGO_RC1_COMPLETE_SOURCE.zip
cd INVESTIGO_RC1_COMPLETE_SOURCE
bash PUSH_RC1_TO_GITHUB.sh
```

After the push, open GitHub → INVESTIGO → Actions → Build Android APK.
