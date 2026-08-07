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

.PHONY: bump-build build-android distribute-android release-android clean-build

## Auto-increments the build number (the `+N` after the version name) in
## pubspec.yaml, e.g. 1.0.0+2 -> 1.0.0+3, so every release shows up as a
## new, distinct build in Firebase App Distribution without having to
## remember to bump it by hand. The version *name* (1.0.0) is untouched —
## bump that manually in pubspec.yaml only for real version bumps.
bump-build:
	@current=$$(grep '^version:' pubspec.yaml | sed -E 's/^version: [0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)$$/\1/'); \
	name=$$(grep '^version:' pubspec.yaml | sed -E 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+$$/\1/'); \
	next=$$((current + 1)); \
	sed -i '' -E "s/^version: .+/version: $${name}+$${next}/" pubspec.yaml; \
	echo "Bumped build number: $${name}+$${current} -> $${name}+$${next}"

## Build the release APK. Always bumps the build number first (see
## `bump-build`), so re-running this produces a new build number each time.
build-android: bump-build
	flutter build apk --release

## Upload the already-built release APK to the Firebase App Distribution
## "Testeri Interni" group, with release notes.
distribute-android:
	firebase appdistribution:distribute $(APK_PATH) \
		--app $(ANDROID_APP_ID) \
		--groups $(TESTER_GROUP) \
		--release-notes "$(NOTES)" \
		--project $(FIREBASE_PROJECT)

## Full repeatable release flow: build (with auto-bumped build number),
## then distribute, in one command.
## Usage: make release-android NOTES="Fixed the map loading bug"
release-android: build-android distribute-android

clean-build:
	flutter clean
