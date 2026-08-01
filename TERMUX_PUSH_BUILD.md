# INVESTIGO — Termux থেকে GitHub push ও APK build

## ১) ZIP extract
```bash
pkg update -y
pkg install git unzip -y
termux-setup-storage
cd /sdcard/Download
unzip -o INVESTIGO_FINAL_TERMUX_GITHUB_SOURCE.zip -d INVESTIGO_FINAL
cd INVESTIGO_FINAL
```

## ২) GitHub repository-তে push
GitHub-এ একটি খালি repository তৈরি করুন। তারপর:
```bash
chmod +x push_to_github.sh
./push_to_github.sh https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
```

GitHub password চাওয়া হলে password-এর বদলে Personal Access Token ব্যবহার করুন।

## ৩) APK নেওয়া
1. GitHub repository খুলুন।
2. **Actions** → **Build Android APK** খুলুন।
3. সর্বশেষ সফল run খুলুন।
4. নিচের **Artifacts** থেকে `investigo-debug-apk` ডাউনলোড করুন।

## ৪) Release APK
Workflow manual run করলে `app-release.apk`-ও তৈরি হবে। এটি বর্তমানে unsigned release APK; Play Store বা production distribution-এর আগে নিজস্ব keystore দিয়ে signing করতে হবে।

## গুরুত্বপূর্ণ
- Android platform folder repository-তে না থাকলেও workflow `flutter create . --platforms=android` চালিয়ে তৈরি করবে।
- PDF-তে বাংলা font প্রথমবার build/runtime-এ Google Fonts source থেকে load হতে পারে। Offline production-এর জন্য Bengali font assets bundle করা উত্তম।
- বাস্তব Android ফোনে CD ও NCR-এর long-text pagination এবং print scaling পরীক্ষা করুন।
