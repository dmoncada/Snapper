SWIFT := /usr/bin/swift
SOURCES := ./Snapper ./SnapperWidget ./SnapperUITests ./SnapperTests

TEST_DESTINATION ?= platform=iOS Simulator,name=iPhone 12 mini,OS=27.0

TEST_RESULT_BUNDLE_PATH ?=
TEST_RESULT_BUNDLE_ARG = $(if $(TEST_RESULT_BUNDLE_PATH),-resultBundlePath '$(TEST_RESULT_BUNDLE_PATH)')

.PHONY: check
check:
	@$(SWIFT) format lint \
		--strict \
		--parallel \
		--recursive \
		$(SOURCES)

.PHONY: format
format:
	@$(SWIFT) format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		$(SOURCES)

.PHONY: build
build:
	@set -o pipefail; xcodebuild build \
		CODE_SIGNING_ALLOWED='No' \
		-project Snapper.xcodeproj \
		-scheme Snapper \
		-configuration Debug \
		-destination 'generic/platform=iOS Simulator' \
		| xcbeautify

.PHONY: test test-unit test-ui
test: TEST_SCHEME = Snapper
test-unit: TEST_SCHEME = SnapperTests
test-ui: TEST_SCHEME = SnapperUITests
test test-unit test-ui:
	@set -o pipefail; xcodebuild test \
		CODE_SIGN_STYLE='Automatic' \
		CODE_SIGN_IDENTITY='-' \
		-project Snapper.xcodeproj \
		-scheme $(TEST_SCHEME) \
		-configuration Debug \
		-destination '$(TEST_DESTINATION)' \
		-parallel-testing-enabled NO $(TEST_RESULT_BUNDLE_ARG) \
		| xcbeautify
