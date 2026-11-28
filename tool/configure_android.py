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
ADMOB_APP_ID = "ca-app-pub-7351657203026829~5088783830"
TEST_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"


def configure_brand_resources() -> None:
    res = ANDROID / "app/src/main/res"
    for resource in (
        "mipmap-anydpi-v26/ic_launcher.xml",
        "mipmap-anydpi-v26/ic_launcher_round.xml",
        "drawable/chang_thai_launcher_background.xml",
        "drawable/chang_thai_launcher_foreground.xml",
        "drawable/chang_thai_launcher_monochrome.xml",
        "drawable/chang_thai_startup_icon.xml",
    ):
        (res / resource).unlink(missing_ok=True)
    shutil.copytree(ROOT / "tool/android_brand", res, dirs_exist_ok=True)
    adaptive = res / "mipmap-anydpi-v26"
    adaptive.mkdir(parents=True, exist_ok=True)
    icon_xml = """<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/white" />
    <foreground android:drawable="@drawable/chang_thai_launcher_icon" />
</adaptive-icon>
"""
    for filename in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (adaptive / filename).write_text(icon_xml, encoding="utf-8")
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
        normal.text = "#111431"
        launch = tree.find("./style[@name='LaunchTheme']")
        if launch is None:
            raise SystemExit(f"LaunchTheme missing in {styles}.")
        disable_preview = launch.find("item[@name='android:windowDisablePreview']")
        if disable_preview is None:
            disable_preview = ET.SubElement(launch, "item", name="android:windowDisablePreview")
        disable_preview.text = "true"
        startup = tree.find("./style[@name='StartupTheme']")
        if startup is None:
            startup = ET.SubElement(tree.getroot(), "style", name="StartupTheme", parent="LaunchTheme")
        for name, value in {
            "android:windowIsTranslucent": "true",
            "android:windowBackground": "@android:color/transparent",
        }.items():
            item = startup.find(f"item[@name='{name}']")
            if item is None:
                item = ET.SubElement(startup, "item", name=name)
            item.text = value
        tree.write(styles, encoding="utf-8")
        for item in list(launch):
            if item.get("name") == "android:windowBackground":
                item.text = "#111431"
        # Android 12+ shows a system launch window. Leave it unbranded so
        # MainActivity can display the full artwork as the only branded splash.
        for name, value in {
            "android:windowSplashScreenBackground": "#111431",
            "android:windowSplashScreenAnimatedIcon": "@android:color/transparent",
        }.items():
            ET.SubElement(launch, "item", name=name).text = value
        versioned = res / f"{qualifier}-v31"
        versioned.mkdir(exist_ok=True)
        ET.indent(tree, space="    ")
        tree.write(versioned / "styles.xml", encoding="utf-8")


def configure_release_keep_rules(app: Path) -> None:
    # WorkManager's Room database is created by reflection during Android startup.
    # Flutter automatically includes app/proguard-rules.pro in the release build.
    rules = (
        "-keep class androidx.work.impl.WorkDatabase { *; }",
        "-keep class androidx.work.impl.WorkDatabase_Impl { *; }",
    )
    proguard = app / "proguard-rules.pro"
    existing = proguard.read_text(encoding="utf-8") if proguard.is_file() else ""
    missing = [rule for rule in rules if rule not in existing.splitlines()]
    if missing:
        with proguard.open("a", encoding="utf-8") as output:
            if existing and not existing.endswith("\n"):
                output.write("\n")
            output.write("\n".join(missing) + "\n")


def configure_android_controls(manifest_text: str, gradle: Path) -> str:
    app = gradle.parent
    controls = ROOT / "tool/android_controls"
    firebase = app / "google-services.json"
    bundled_config = controls / "google-services.json"
    if not firebase.is_file() and bundled_config.is_file():
        shutil.copyfile(bundled_config, firebase)
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
    for filename in ("MainActivity.kt", "StartupActivity.kt"):
        shutil.copyfile(controls / filename, activity / filename)
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

    configure_release_keep_rules(gradle.parent)

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
    manifest_text = re.sub(r'\s+android:roundIcon="[^"]+"', "", manifest_text)
    manifest_text = manifest_text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher"', 1)
    if "com.google.android.gms.ads.APPLICATION_ID" not in manifest_text:
        manifest_text = manifest_text.replace(
            "</application>",
            '    <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" '
            f'android:value="{ADMOB_APP_ID}" />\n  </application>',
        )
    manifest_text = manifest_text.replace(TEST_ADMOB_APP_ID, ADMOB_APP_ID)
    if 'com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT' not in manifest_text:
        manifest_text = manifest_text.replace(
            "</application>",
            '    <meta-data android:name="com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT" '
            'android:value="true" />\n  </application>',
        )
    debug_manifest = manifest.parent.parent / "debug" / "AndroidManifest.xml"
    if debug_manifest.is_file():
        debug_text = debug_manifest.read_text(encoding="utf-8")
        if "com.google.android.gms.ads.APPLICATION_ID" not in debug_text:
            debug_text = debug_text.replace(
                '<manifest ',
                '<manifest xmlns:tools="http://schemas.android.com/tools" ',
                1,
            ) if 'xmlns:tools=' not in debug_text else debug_text
            debug_text = debug_text.replace(
                "</manifest>",
                '    <application><meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" '
                f'android:value="{TEST_ADMOB_APP_ID}" tools:replace="android:value" />'
                '</application>\n</manifest>',
            )
            debug_manifest.write_text(debug_text, encoding="utf-8")
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

    if 'android:name=".StartupActivity"' not in manifest_text:
        launcher_filter = r'<intent-filter>\s*<action android:name="android.intent.action.MAIN"\s*/>\s*<category android:name="android.intent.category.LAUNCHER"\s*/>\s*</intent-filter>'
        manifest_text, changed = re.subn(launcher_filter, "", manifest_text, count=1)
        if changed != 1:
            raise SystemExit("The Android launcher intent filter is missing.")
        startup_activity = '''
        <activity
            android:name=".StartupActivity"
            android:exported="true"
            android:taskAffinity=""
            android:launchMode="singleTop"
            android:theme="@style/StartupTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        '''
        manifest_text = manifest_text.replace("</application>", startup_activity + "</application>", 1)
    manifest_text = configure_android_controls(manifest_text, gradle)
    manifest.write_text(manifest_text, encoding="utf-8")
    configure_brand_resources()
    print(f"Android defaults configured: {APP_PACKAGE}; production ads require explicit build flags and published settings.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
