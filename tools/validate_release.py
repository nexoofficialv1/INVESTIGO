from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
errors = []
warnings = []

required_docs = [
    'Architecture.md', 'Phases.md', 'Database.md', 'Prompts.md',
    'Security.md', 'Error-handling.md'
]
for name in required_docs:
    path = root / name
    if not path.exists() or path.stat().st_size < 100:
        errors.append(f'missing-or-empty:{name}')

pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
if 'speech_to_text:' not in pubspec:
    errors.append('missing-dependency:speech_to_text')
version_match = re.search(r'^version:\s+([^\s]+)\s*$', pubspec, re.M)
if not version_match:
    errors.append('missing-version')
else:
    version = version_match.group(1)
    if not re.fullmatch(r'1\.(?:8|9)\.0-rc\.\d+\+\d+', version):
        errors.append(f'unexpected-version:{version}')

required_sources = [
    'lib/services/official_template_spec.dart',
    'lib/services/release_validation_service.dart',
    'lib/services/pdf_service.dart',
    'lib/services/doc_export_service.dart',
    'lib/screens/settings_screen.dart',
]
for name in required_sources:
    if not (root / name).exists():
        errors.append(f'missing-source:{name}')

pdf_text = (root / 'lib/services/pdf_service.dart').read_text(encoding='utf-8')
for marker in ['5371', '5370', '5363', '5203', '“A” FORM']:
    if marker not in pdf_text:
        errors.append(f'missing-template-marker:{marker}')

# The official Form 39 caption appears as ‘W.B.P Form No. 39’ in the
# supplied specimen. Accept harmless punctuation/case variants while still
# requiring the complete W.B.P + Form No. marker in the PDF renderer.
if not re.search(r'W\.B\.P\.?\s+Form\s+No\.', pdf_text, re.IGNORECASE):
    errors.append('missing-template-marker:W.B.P Form No.')

spec_text = (root / 'lib/services/official_template_spec.dart').read_text(encoding='utf-8')
for marker in ['cdColumnRatios', 'ncrColumnRatios', 'if5WitnessColumnRatios']:
    if marker not in spec_text:
        errors.append(f'missing-template-spec:{marker}')

if errors:
    print('RELEASE VALIDATION FAILED')
    for item in errors:
        print('ERROR', item)
    for item in warnings:
        print('WARN', item)
    sys.exit(1)

print('RELEASE VALIDATION PASSED')
print(' - required documentation present')
print(' - domain/template sources present')
print(' - official form markers present')
print(f' - version {version}')
