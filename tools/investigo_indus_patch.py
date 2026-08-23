from pathlib import Path

p = Path("android/app/build.gradle.kts")
if not p.exists():
    raise SystemExit("ERROR: android/app/build.gradle.kts not found")

s = p.read_text()

s = s.replace(
    "compileSdk = flutter.compileSdkVersion",
    "compileSdk = 36"
)
s = s.replace(
    "minSdk = flutter.minSdkVersion",
    "minSdk = 24"
)
s = s.replace(
    "targetSdk = flutter.targetSdkVersion",
    "targetSdk = 36"
)

if "val keystoreProperties" not in s:
    s = (
        "import java.util.Properties\n"
        "import java.io.FileInputStream\n\n"
        'val keystoreProperties = Properties()\n'
        'val keystorePropertiesFile = rootProject.file("key.properties")\n'
        'keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n\n'
        + s
    )

if 'create("release")' not in s:
    marker = "    buildTypes {"

    signing = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

'''

    s = s.replace(marker, signing + marker, 1)

s = s.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)

p.write_text(s)

print("INVESTIGO INDUS ANDROID PATCH COMPLETE")
