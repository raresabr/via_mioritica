# Via Mioritica — repeatable release tasks (Faza 11: Firebase App Distribution)
#
# Requires: Firebase CLI (`npm install -g firebase-tools`) + `firebase login`
# once per machine. See README.md "Internal testing distribution" for the
# full one-time setup (Firebase project, tester group, app onboarding).

FIREBASE_PROJECT := via-mioritica-app
ANDROID_APP_ID   := 1:744736994673:android:4a2457b9fc0a670a4732d0
TESTER_GROUP     := testeri-interni
APK_PATH         := build/app/outputs/flutter-apk/app-release.apk

# Release notes default to the latest git commit message; override with
# `make distribute-android NOTES="text here"`.
NOTES ?= $(shell git log -1 --pretty=%B | head -1)

.PHONY: build-android distribute-android release-android clean-build

## Build the release APK.
build-android:
	flutter build apk --release

## Upload the already-built release APK to the Firebase App Distribution
## "Testeri Interni" group, with release notes.
distribute-android:
	firebase appdistribution:distribute $(APK_PATH) \
		--app $(ANDROID_APP_ID) \
		--groups $(TESTER_GROUP) \
		--release-notes "$(NOTES)" \
		--project $(FIREBASE_PROJECT)

## Full repeatable release flow: build, then distribute, in one command.
## Usage: make release-android NOTES="Fixed the map loading bug"
release-android: build-android distribute-android

clean-build:
	flutter clean
