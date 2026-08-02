from pathlib import Path
import re
import sys

errors = []

required = [
    "lib/services/pdf_service.dart",
    "pubspec.yaml",
    "tools/validate_release.py",
    "Architecture.md",
    "Phases.md",
    "Database.md",
    "Prompts.md",
    "Security.md",
    "Error-handling.md",
]

for file_name in required:
    if not Path(file_name).is_file():
        errors.append(f"missing:{file_name}")

pdf_path = Path("lib/services/pdf_service.dart")

if pdf_path.is_file():
    source = pdf_path.read_text(encoding="utf-8")

    # শুধু আগে দেখা নির্দিষ্ট ভুল pattern আটকাবে।
    invalid_patterns = [
        r"pw\.Text\(\s*[^,]+,\s*decoration\s*:",
        r"pw\.Text\([^)]*style:\s*bold\([^)]*\),\s*decoration\s*:",
        r"style:\s*bold\(11\.2\),\s*decoration:\s*pw\.TextDecoration\.underline",
    ]

    for pattern in invalid_patterns:
        if re.search(pattern, source, flags=re.DOTALL):
            errors.append(
                "pdf_service: Text decoration must be inside pw.TextStyle"
            )
            break

pubspec_path = Path("pubspec.yaml")
if pubspec_path.is_file():
    pubspec = pubspec_path.read_text(encoding="utf-8")
    if not re.search(
        r"^version:\s*1\.8\.0-rc\.\d+\+\d+\s*$",
        pubspec,
        flags=re.MULTILINE,
    ):
        errors.append("pubspec:invalid RC semantic version")

if errors:
    print("PREFLIGHT FAILED")
    for error in errors:
        print("ERROR", error)
    sys.exit(1)

print("PREFLIGHT PASSED")
