from pathlib import Path
import re

repo = Path.cwd()

# -----------------------------
# 1) Ensure icon asset is declared
# -----------------------------
pub = repo / "pubspec.yaml"
s = pub.read_text(encoding="utf-8")

if "assets/branding/investigo_store_icon.png" not in s:
    if "\nflutter:\n" in s:
        if re.search(r"(?m)^  assets:\s*$", s):
            s = re.sub(
                r"(?m)^  assets:\s*$",
                "  assets:\n    - assets/branding/investigo_store_icon.png",
                s,
                count=1,
            )
        else:
            s = s.replace(
                "\nflutter:\n",
                "\nflutter:\n  assets:\n    - assets/branding/investigo_store_icon.png\n",
                1,
            )

pub.write_text(s, encoding="utf-8")

# -----------------------------
# 2) Add Privacy Policy action
# -----------------------------
screen = repo / "lib/screens/license_screen.dart"
s = screen.read_text(encoding="utf-8")

if "static const String _privacyUrl" not in s:
    s = s.replace(
        "  static const String _licenseWhatsApp = '916295192839';\n",
        "  static const String _licenseWhatsApp = '916295192839';\n"
        "  static const String _privacyUrl = "
        "'https://nexoofficialv1.github.io/ASTRA-PRIVACY/investigo.html';\n",
        1,
    )

if "Future<void> _openPrivacyPolicy()" not in s:
    marker = "  Future<void> _copyDeviceCode(String value) async {\n"
    helper = """  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyUrl);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Privacy Policy.'),
        ),
      );
    }
  }

"""
    s = s.replace(marker, helper + marker, 1)

if "Privacy Policy" not in s:
    marker = """        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
"""
    card = """        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: InvestigoUi.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy & Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Read how INVESTIGO handles local case data, documents, backups and licensing information.',
                style: TextStyle(
                  color: InvestigoUi.muted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openPrivacyPolicy,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Open Privacy Policy'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
"""
    s = s.replace(marker, card, 1)

screen.write_text(s, encoding="utf-8")

print("INVESTIGO STORE COMPLIANCE PATCH APPLIED")
