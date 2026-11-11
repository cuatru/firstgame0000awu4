WATCH_DESTINATION ?= generic/platform=watchOS Simulator

.PHONY: generate open build test

generate:
	@command -v xcodegen >/dev/null || (echo "Install XcodeGen: brew install xcodegen" && exit 1)
	xcodegen generate

open: generate
	open FlowWatch.xcodeproj

build: generate
	xcodebuild \
	  -project FlowWatch.xcodeproj \
	  -scheme FlowWatch \
	  -destination 'generic/platform=watchOS Simulator' \
	  CODE_SIGNING_ALLOWED=NO \
	  build

test: generate
	xcodebuild \
	  -project FlowWatch.xcodeproj \
	  -scheme FlowWatch \
	  -destination '$(WATCH_DESTINATION)' \
	  CODE_SIGNING_ALLOWED=NO \
	  test
