# Android builds and releases

The **Android APK** workflow builds on GitHub's standard Linux runner. It runs only on manual requests and version tags, so ordinary pushes do not start builds.

## Build manually

Open **Actions → Android APK → Run workflow**, choose the branch, then run it. Download the APKs from the completed run's **Artifacts** section. Manual builds do not publish a release.

## Publish a release

After committing and pushing the app changes you want to ship:

```sh
git tag v1.0.0
git push origin v1.0.0
```

Tags must use `vMAJOR.MINOR.PATCH`. The tag determines the APK version name; the workflow run number supplies the base Android version code (Flutter adds an ABI-specific offset for each architecture). A successful build creates a GitHub Release containing three architecture-specific APKs and `SHA256SUMS.txt`. Re-running the same release replaces its assets. Do not rerun an older release after publishing a newer one, because run numbers increase independently of version names.

The workflow runs Flutter tests before building and keeps workflow artifacts for seven days. Release attachments remain available on the Releases page. Flutter is pinned to 3.50.0, matching the development SDK.

## Choose an APK

Each build uses `flutter build apk --release --split-per-abi` and produces:

- `YomiPeek-<version>-arm64-v8a.apk`: ARM 64-bit, for most modern phones.
- `YomiPeek-<version>-armeabi-v7a.apk`: ARM 32-bit, for older compatible devices.
- `YomiPeek-<version>-x86_64.apk`: x86 64-bit devices and emulators.

Install the APK matching your device's supported architecture. All three are signed with the same release key and are included in manual build artifacts and tag releases.

## Signing

Repository Actions secrets provide a dedicated release keystore:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded JKS keystore
- `ANDROID_KEYSTORE_PASSWORD`: keystore password
- `ANDROID_KEY_ALIAS`: key alias
- `ANDROID_KEY_PASSWORD`: key password

Keep an offline backup of the original keystore and passwords. Always use the same key for updates. CI refuses to build when any signing secret is absent.

Local builds can use an ignored `android/key.properties` file:

```properties
storeFile=/absolute/path/to/yomipeek-release.jks
storePassword=your-keystore-password
keyAlias=yomipeek
keyPassword=your-key-password
```

Without local signing configuration, local release builds retain the existing debug signing fallback. Debug-signed installations cannot be upgraded directly to the release-signed APK; uninstalling the debug app removes its local data, so back up anything you need first.
