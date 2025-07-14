PLATFORM_IOS = iOS Simulator,name=iPad mini (A17 Pro)
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (3rd generation) (at 1080p)
TARGET = AUv3Controls
BUILD_FLAGS = -skipMacroValidation -skipPackagePluginValidation -scheme $(TARGET)
WORKSPACE = $(PWD)/.workspace
XCCOV = xcrun xccov view --report --only-targets

default: percentage

percentage: coverage-ios
	awk '/ $(TARGET) / { if ($$3 > 0) print $$4; }' coverage.txt > percentage.txt
	cat percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
    fi

coverage-ios: test-ios
	$(XCCOV) $(PWD)/.DerivedData-ios/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

coverage-macos: test-macos
	$(XCCOV) $(PWD)/.DerivedData-macos/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

coverage-tvos: test-tvos
	$(XCCOV) $(PWD)/.DerivedData-tvos/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

test: test-ios test-macos test-tvos

test-ios: lint
	set -o pipefail && xcodebuild test \
		$(BUILD_FLAGS) -enableCodeCoverage YES \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-derivedDataPath "$(PWD)/.DerivedData-ios" \
		-destination platform="$(PLATFORM_IOS)" \
		| xcbeautify --renderer github-actions

test-macos: lint
	set -o pipefail && xcodebuild test \
		$(BUILD_FLAGS) -enableCodeCoverage YES \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-derivedDataPath "$(PWD)/.DerivedData-macos" \
		-destination platform="$(PLATFORM_MACOS)" \
		| xcbeautify --renderer github-actions

test-tvos: lint
	set -o pipefail && xcodebuild test \
		$(BUILD_FLAGS) -enableCodeCoverage YES \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-derivedDataPath "$(PWD)/.DerivedData-tvos" \
		-destination platform="$(PLATFORM_TVOS)"
		| xcbeautify --renderer github-actions

lint: clean
	@if command -v swiftlint; then swiftlint; fi

docs:
	swift package --allow-writing-to-package-directory \
		generate-documentation \
		--target AUv3Controls \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path https://keystrokecountdown.com/AUv3Controls/ \
		--output-path ./docs

clean:
	rm -rf "$(PWD)/.DerivedData-macos" "$(PWD)/.DerivedData-ios" "$(PWD)/.DerivedData-tvos" "$(WORKSPACE)" \
	"$(PWD)/docs"

.PHONY: test test-ios test-macos test-tvos coverage percentage lint
