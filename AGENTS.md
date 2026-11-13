# Android Development Environment

This is a Flutter project.

Android emulator:
- AVD: Medium_Phone_API_37.0
- Android SDK: /home/ibnufadhil/Android/Sdk

Development workflow:
1. Check available devices using `adb devices`.
2. If no emulator is running, launch it with:
   `flutter emulators --launch Medium_Phone_API_37.0`
3. Run the app using `flutter run -d <device-id>`.
4. Use ADB to inspect logs and capture screenshots.
5. Use Flutter integration tests to verify UI behavior.

When fixing UI issues, build and test the app on
the Android emulator when tool access permits.