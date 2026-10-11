#ios build
flutter build ios --no-codesign --release
mkdir Payload/
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r admin.ipa Payload/

#android build
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk admin.apk