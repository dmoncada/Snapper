SWIFT := xcrun swift
SOURCES := ./Snapper ./SnapperTests ./SnapperUITests ./SnapperWidget

TEST_DESTINATION ?= platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2

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

.PHONY: test
test: TEST_SCHEME = SnapperTests

.PHONY: test-ui
test-ui: TEST_SCHEME = SnapperUITests

test test-ui:
	@set -o pipefail; xcodebuild test \
		CODE_SIGN_STYLE='Automatic' \
		CODE_SIGN_IDENTITY='-' \
		-project Snapper.xcodeproj \
		-scheme $(TEST_SCHEME) \
		-configuration Debug \
		-destination '$(TEST_DESTINATION)' \
		-parallel-testing-enabled NO \
		$(TEST_RESULT_BUNDLE_ARG) \
		| xcbeautify
