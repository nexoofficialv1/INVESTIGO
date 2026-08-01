# INVESTIGO bilingual work — started

Implemented in this working patch:

- Persistent বাংলা / English language preference using SharedPreferences.
- Language chooser on the dashboard without changing the existing layout structure.
- App title, main navigation and New Case button switch language immediately.
- Official CD PDF header, status row, enquiry headings and signature label switch language.
- Existing CD table proportions, borders and line structure are untouched.

Still pending before final APK:

- Translate every remaining screen, form, notice and report string.
- Apply the same language switch to DOC export and every PDF generator.
- Integrate the v0.9.4 preview-stability changes.
- Flutter analyze, tests, Android build and real-device long-CD verification.
