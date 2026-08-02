from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
errors: list[str] = []

required = [
    'pubspec.yaml',
    'lib/services/pdf_service.dart',
    'lib/screens/settings_screen.dart',
    'lib/models/officer_profile.dart',
    'Architecture.md',
    'Phases.md',
    'Database.md',
    'Prompts.md',
    'Security.md',
    'Error-handling.md',
]
for name in required:
    if not (root / name).is_file():
        errors.append(f'missing:{name}')

pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
if not re.search(r'^version:\s*1\.8\.0-rc\.\d+\+\d+\s*$', pubspec, re.M):
    errors.append('invalid-rc-version')

pdf_path = root / 'lib/services/pdf_service.dart'
if pdf_path.is_file():
    pdf = pdf_path.read_text(encoding='utf-8')
    invalid_exact_patterns = [
        "style: bold(11.2), decoration: pw.TextDecoration.underline",
        "style: normal(11.2), decoration: pw.TextDecoration.underline",
    ]
    for pattern in invalid_exact_patterns:
        if pattern in pdf:
            errors.append('pdf-decoration-outside-text-style')
            break
    for marker in [
        'West Bengal Form No- 5203',
        '“A” FORM',
        'West Bengal Form No- 5371',
        'West Bengal form No. 5363',
    ]:
        if marker not in pdf:
            errors.append(f'missing-pdf-marker:{marker}')

all_dart = '\n'.join(
    path.read_text(encoding='utf-8')
    for path in (root / 'lib').rglob('*.dart')
)
for forbidden in ['Kalna Police Station', 'Purba Bardhaman']:
    if forbidden in all_dart:
        errors.append(f'hardcoded-station-data:{forbidden}')

if errors:
    print('PREFLIGHT FAILED')
    for error in errors:
        print('ERROR', error)
    sys.exit(1)

print('PREFLIGHT PASSED')
