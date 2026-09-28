#!/usr/bin/env python3
"""Apply the app's safe Android defaults after Flutter creates platform files."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
OLD_PACKAGE = "com.sharedbyatt.thai_for_myanmar"
APP_PACKAGE = "com.sharedbyatt.thaiformyanmar"
TEST_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"


def main() -> int:
    manifest = ANDROID / "app/src/main/AndroidManifest.xml"
    gradle = ANDROID / "app/build.gradle.kts"
    if not manifest.exists() or not gradle.exists():
        raise SystemExit(
            "Android platform files are missing. Run flutter create for Android first."
        )

    gradle_text = gradle.read_text(encoding="utf-8")
    gradle_text = gradle_text.replace(OLD_PACKAGE, APP_PACKAGE)
    gradle.write_text(gradle_text, encoding="utf-8")

    manifest_text = manifest.read_text(encoding="utf-8")
    manifest_text = manifest_text.replace('android:label="thai_for_myanmar"',
                                          'android:label="Thai for Myanmar"')
    manifest_text = manifest_text.replace(OLD_PACKAGE, APP_PACKAGE)
    manifest_text = re.sub(
        r'android:icon="[^"]+"', 'android:icon="@drawable/ic_thai_myanmar"',
        manifest_text,
        count=1,
    )
    if "com.google.android.gms.ads.APPLICATION_ID" not in manifest_text:
        manifest_text = manifest_text.replace(
            "</application>",
            '    <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" '
            f'android:value="{TEST_ADMOB_APP_ID}" />\n  </application>',
        )
    manifest.write_text(manifest_text, encoding="utf-8")

    main_activity = ANDROID / "app/src/main/kotlin/com/sharedbyatt/thai_for_myanmar/MainActivity.kt"
    if main_activity.exists():
        new_activity = ANDROID / "app/src/main/kotlin/com/sharedbyatt/thaiformyanmar/MainActivity.kt"
        new_activity.parent.mkdir(parents=True, exist_ok=True)
        content = main_activity.read_text(encoding="utf-8").replace(OLD_PACKAGE, APP_PACKAGE)
        new_activity.write_text(content, encoding="utf-8")
        main_activity.unlink()
        old_parent = main_activity.parent
        if old_parent.exists() and not any(old_parent.iterdir()):
            old_parent.rmdir()

    icon = ANDROID / "app/src/main/res/drawable/ic_thai_myanmar.xml"
    icon.parent.mkdir(parents=True, exist_ok=True)
    icon.write_text(
        '''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  <path android:fillColor="#167D75" android:pathData="M0,0h108v108h-108z" />
  <path android:fillColor="#FFFFFF" android:pathData="M23,24c12,-3 22,0 31,7c9,-7 19,-10 31,-7v53c-12,-3 -22,0 -31,7c-9,-7 -19,-10 -31,-7z" />
  <path android:fillColor="#167D75" android:pathData="M30,34c8,-1 15,1 20,5v35c-6,-4 -12,-5 -20,-4z" />
  <path android:fillColor="#167D75" android:pathData="M58,39c6,-4 12,-6 20,-5v36c-8,-1 -14,0 -20,4z" />
</vector>\n''',
        encoding="utf-8",
    )
    print(f"Android defaults configured: {APP_PACKAGE}; AdMob remains test-only.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
