# INVESTIGO Mobile — Bengali/English Build Source

Flutter ভিত্তিক পুলিশ তদন্ত সহায়ক মোবাইল অ্যাপ। UI-এর মূল গঠন বজায় রেখে বাংলা ও English ভাষা নির্বাচন রয়েছে।

## বর্তমান মডিউল
- Case entry ও case detail
- Case Diary (West Bengal Form No. 5363 / PRB Form No. 43)
- NCR prosecution report (West Bengal Form No. 5358 / PRB Form No. 41)
- Investigation, statements, notices/forms, evidence, sketch map
- UD case/inquest
- Reports, compliance, SOP, backup ও backend settings
- PDF preview/share এবং DOC export

## NCR
Dashboard-এ আলাদা **NCR** ট্যাব রয়েছে। Draft save/load, PDF preview, PDF share এবং DOC export করা যায়। NCR document A4 landscape-এ official multi-column grid অনুসরণ করে। বাংলা/English নির্বাচন অনুযায়ী heading ও labels বদলায়; user-entered content অপরিবর্তিত থাকে।

## Build
GitHub Actions স্বয়ংক্রিয়ভাবে Android platform files তৈরি করে debug APK build করে। বিস্তারিত `TERMUX_PUSH_BUILD.md`-এ।

## Verification required
Production ব্যবহারের আগে বাস্তব ডিভাইসে:
- long CD pagination
- NCR landscape print scaling
- বাংলা font rendering
- DOC → Word/LibreOffice rendering
- offline/online data flow
পরীক্ষা করা আবশ্যক।
