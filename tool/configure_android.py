#!/usr/bin/env python3
"""Apply the app's safe Android defaults after Flutter creates platform files."""

import json
import re
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
OLD_PACKAGE = "com.sharedbyatt.thai_for_myanmar"
APP_PACKAGE = "com.sharedbyatt.thaiformyanmar"
TEST_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"


def configure_brand_resources() -> None:
    res = ANDROID / "app/src/main/res"
    shutil.copytree(ROOT / "tool/android_brand", res, dirs_exist_ok=True)
    launch_background = """<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape><solid android:color="#111431" /></shape>
    </item>
    <item>
        <bitmap android:gravity="fill" android:src="@drawable/chang_thai_splash" />
    </item>
</layer-list>
"""
    for qualifier in ("drawable", "drawable-v21"):
        directory = res / qualifier
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "launch_background.xml").write_text(
            launch_background, encoding="utf-8"
        )

    for qualifier in ("values", "values-night"):
        styles = res / qualifier / "styles.xml"
        tree = ET.parse(styles)
        normal = tree.find("./style[@name='NormalTheme']/item[@name='android:windowBackground']")
        if normal is None:
            raise SystemExit(f"NormalTheme window background missing in {styles}.")
        normal.text = "@drawable/launch_background"
        tree.write(styles, encoding="utf-8")
        launch = tree.find("./style[@name='LaunchTheme']")
        if launch is None:
            raise SystemExit(f"LaunchTheme missing in {styles}.")
        for name, value in {
            "android:windowSplashScreenBackground": "#111431",
            "android:windowSplashScreenAnimatedIcon": "@mipmap/ic_launcher",
        }.items():
            ET.SubElement(launch, "item", name=name).text = value
        versioned = res / f"{qualifier}-v31"
        versioned.mkdir(exist_ok=True)
        ET.indent(tree, space="    ")
        tree.write(versioned / "styles.xml", encoding="utf-8")


def configure_android_controls(manifest_text: str, gradle: Path) -> str:
    app = gradle.parent
    controls = ROOT / "tool/android_controls"
    firebase = app / "google-services.json"
    firebase_enabled = firebase.is_file()
    if firebase_enabled:
        config = json.loads(firebase.read_text(encoding="utf-8"))
        if not any(
            row.get("client_info", {}).get("android_client_info", {}).get("package_name")
            == APP_PACKAGE
            for row in config.get("client", [])
        ):
            raise SystemExit("google-services.json does not match Chang Thai's package ID.")
        text = gradle.read_text(encoding="utf-8")
        if 'id("com.google.gms.google-services")' not in text:
            text = text.replace(
                "plugins {",
                'plugins {\n    id("com.google.gms.google-services") version "4.4.4"',
                1,
            )
            text += '\ndependencies {\n    implementation("com.google.firebase:firebase-messaging:25.0.1")\n}\n'
            gradle.write_text(text, encoding="utf-8")
        if 'firebase_messaging_auto_init_enabled' not in manifest_text:
            manifest_text = manifest_text.replace(
                "</application>",
                '    <meta-data android:name="firebase_messaging_auto_init_enabled" android:value="false" />\n'
                '    <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="chang_thai_announcements" />\n'
                '  </application>',
                1,
            )
    activity = app / "src/main/kotlin/com/sharedbyatt/thaiformyanmar"
    activity.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(controls / "MainActivity.kt", activity / "MainActivity.kt")
    implementation = "PushControlsFirebase.kt" if firebase_enabled else "PushControlsStub.kt"
    shutil.copyfile(controls / implementation, activity / "PushControls.kt")
    return manifest_text


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
                                          'android:label="Chang Thai"')
    manifest_text = manifest_text.replace(OLD_PACKAGE, APP_PACKAGE)
    if 'android.intent.action.TTS_SERVICE' not in manifest_text:
        tts_intent = ('<intent><action android:name="android.intent.action.TTS_SERVICE" />'
                      '</intent>')
        if '</queries>' in manifest_text:
            manifest_text = manifest_text.replace('</queries>', tts_intent + '\n</queries>', 1)
        else:
            manifest_text = manifest_text.replace('</manifest>',
                '<queries>' + tts_intent + '</queries>\n</manifest>', 1)
    manifest_text = re.sub(
        r'android:icon="[^"]+"', 'android:icon="@mipmap/ic_launcher"',
        manifest_text,
        count=1,
    )
    if "com.google.android.gms.ads.APPLICATION_ID" not in manifest_text:
        manifest_text = manifest_text.replace(
            "</application>",
            '    <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" '
            f'android:value="{TEST_ADMOB_APP_ID}" />\n  </application>',
        )
    # Supabase/app_links owns this callback; disable Flutter's competing handler.
    if 'android.permission.INTERNET' not in manifest_text:
        manifest_text = manifest_text.replace(
            '<application',
            '<uses-permission android:name="android.permission.INTERNET" />\n    <application',
            1,
        )
    if 'com.sharedbyatt.thaiformyanmar" android:host="league-callback' not in manifest_text:
        callback = '''
            <meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
            <intent-filter android:label="League sign-in">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="com.sharedbyatt.thaiformyanmar" android:host="league-callback" />
            </intent-filter>
        '''
        manifest_text, changed = re.subn(
            r'(<activity\b[^>]*android:name="\.MainActivity"[^>]*>)',
            lambda match: match.group(1) + callback,
            manifest_text,
            count=1,
        )
        if changed != 1:
            raise SystemExit("MainActivity missing; League callback was not configured.")
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

    manifest_text = configure_android_controls(manifest_text, gradle)
    manifest.write_text(manifest_text, encoding="utf-8")
    configure_brand_resources()
    print(f"Android defaults configured: {APP_PACKAGE}; AdMob remains test-only.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
