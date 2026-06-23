from pathlib import Path
import shutil
import datetime
import re

ROOT = Path(r"D:\body_battery")
GRADLE = ROOT / "android" / "app" / "build.gradle.kts"

backup_root = ROOT / "_backups" / ("v49_release_signing_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S"))
backup_root.mkdir(parents=True, exist_ok=True)

shutil.copy2(GRADLE, backup_root / "build.gradle.kts.bak")

text = GRADLE.read_text(encoding="utf-8-sig")

if "import java.util.Properties" not in text:
    text = "import java.util.Properties\nimport java.io.FileInputStream\n\n" + text

if "val keystoreProperties" not in text:
    block = '''
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
    text = text.replace("android {", block + "android {", 1)

if 'create("release")' not in text:
    signing_block = '''
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

'''
    if "buildTypes {" not in text:
        raise SystemExit("KHONG TIM THAY buildTypes { TRONG build.gradle.kts")

    text = text.replace("    buildTypes {", signing_block + "    buildTypes {", 1)

text = text.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)

if 'signingConfig = signingConfigs.getByName("release")' not in text:
    text = re.sub(
        r'(release\s*\{\s*)',
        r'\1\n            signingConfig = signingConfigs.getByName("release")',
        text,
        count=1
    )

GRADLE.write_text(text, encoding="utf-8")

print("PATCH V4.9 RELEASE SIGNING DONE")
print("BACKUP:", backup_root)
