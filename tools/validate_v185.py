from pathlib import Path
import sys

checks = {
    'version': ('pubspec.yaml', 'version: 1.8.0-rc.4+185'),
    'challan-safe-height': ('lib/services/pdf_service.dart', 'const bodyHeight = 300.0;'),
    'fsl-doc': ('lib/services/doc_export_service.dart', '_buildFslPackageDoc'),
    'a-form-doc': ('lib/services/doc_export_service.dart', '_buildAFormDoc'),
    'dashboard-final-docs': ('lib/screens/dashboard_screen.dart', '_openFinalCaseDocuments'),
    'doc-tests': ('test/doc_export_contract_test.dart', 'FSL DOC contains official packet sections'),
}
errors=[]
for name,(file,marker) in checks.items():
    p=Path(file)
    if not p.exists() or marker not in p.read_text(encoding='utf-8'):
        errors.append(name)
forms=Path('lib/screens/forms_screen.dart').read_text(encoding='utf-8')
if forms.count("bool get _isFsl =>") != 1:
    errors.append('duplicate-isFsl-getter')
if errors:
    print('V185 VALIDATION FAILED')
    for e in errors: print('ERROR', e)
    sys.exit(1)
print('V185 STRUCTURAL VALIDATION PASSED')
