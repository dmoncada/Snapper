SWIFT := "/usr/bin/swift"

.PHONY: check
check:
	@$(SWIFT) format lint \
		--strict \
		--parallel \
		--recursive \
		./Snapper

.PHONY: format
format:
	@$(SWIFT) format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Snapper

.PHONY: build
build:
	@xcodebuild build \
		CODE_SIGNING_ALLOWED='No' \
		-project Snapper.xcodeproj \
		-scheme Snapper \
		-configuration Debug \
		-destination 'generic/platform=iOS Simulator' \
		| xcbeautify
