#!/usr/bin/env python3
"""Patches the Flutter-generated Android project for flutter_local_notifications.

Idempotent: safe to run more than once. Run from the project root after
`flutter create`.
"""
import pathlib
import re
import sys

root = pathlib.Path('android/app')
manifest = root / 'src/main/AndroidManifest.xml'
if not manifest.exists():
    sys.exit('android/ not found - run `flutter create` first.')

# --- AndroidManifest.xml -----------------------------------------------------
m = manifest.read_text()
perms = [
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.VIBRATE',
]
for perm in perms:
    if perm not in m:
        m = m.replace('<application', f'<uses-permission android:name="{perm}"/>\n    <application', 1)

receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
if 'ScheduledNotificationReceiver' not in m:
    m = m.replace('</application>', receivers + '    </application>', 1)
m = re.sub(r'android:label="[^"]*"', 'android:label="Tasks for Allah"', m, count=1)
manifest.write_text(m)

# --- Gradle: core library desugaring ----------------------------------------
kts = root / 'build.gradle.kts'
groovy = root / 'build.gradle'
if kts.exists():
    g = kts.read_text()
    if 'isCoreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'(compileOptions\s*\{)', r'\1\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        kts.write_text(g)
elif groovy.exists():
    g = groovy.read_text()
    if 'coreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'(compileOptions\s*\{)', r'\1\n        coreLibraryDesugaringEnabled true', g, count=1)
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
        groovy.write_text(g)

print('Android project patched.')
