PLATFORM_IOS = iOS Simulator,name=iPad mini (6th generation)
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (3rd generation) (at 1080p)
TARGET = AUv3Controls
BUILD_FLAGS = -quiet -skipMacroValidation
WORKSPACE = $(PWD)/.workspace
SNAPSHOT_ARTIFACTS = "${TMPDIR}/AUv3Controls/snapshots"

default: percentage

percentage: coverage-ios
	awk '/ $(TARGET) / { if ($$3 > 0) print $$4; }' coverage.txt > percentage.txt
	cat percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
    fi

coverage-ios: test-ios
	xcrun xccov view --report --only-targets $(PWD)/.DerivedData-ios/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

coverage-macos: test-macos
	xcrun xccov view --report --only-targets $(PWD)/.DerivedData-macos/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

coverage-tvos: test-tvos
	xcrun xccov view --report --only-targets $(PWD)/.DerivedData-tvos/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

test: test-ios test-macos test-tvos

test-ios: build-ios
	TEST_RUNNER_SNAPSHOT_ARTIFACTS="${SNAPSHOT_ARTIFACTS}" xcodebuild test-without-building \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-ios" \
		-destination platform="$(PLATFORM_IOS)" \
		-enableCodeCoverage YES

test-macos: build-macos
	TEST_RUNNER_SNAPSHOT_ARTIFACTS="${SNAPSHOT_ARTIFACTS}" xcodebuild test-without-building \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-macos" \
		-destination platform="$(PLATFORM_MACOS)" \
		-enableCodeCoverage YES

test-tvos: build-tvos
	TEST_RUNNER_SNAPSHOT_ARTIFACTS="${SNAPSHOT_ARTIFACTS}" xcodebuild test-without-building \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-tvos" \
		-destination platform="$(PLATFORM_TVOS)"

build-ios: resolve-deps
	xcodebuild build-for-testing \
		$(BUILD_FLAGS) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-ios" \
		-destination platform="$(PLATFORM_IOS)" \
		-enableCodeCoverage YES

build-macos: resolve-deps
	xcodebuild build-for-testing \
		$(BUILD_FLAGS) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-macos" \
		-destination platform="$(PLATFORM_MACOS)" \
		-enableCodeCoverage YES

build-tvos: resolve-deps
	xcodebuild build-for-testing \
		$(BUILD_FLAGS) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-tvos" \
		-destination platform="$(PLATFORM_TVOS)" \
		-enableCodeCoverage YES

resolve-deps: lint
	xcodebuild \
		$(BUILD_FLAGS) \
		-resolvePackageDependencies \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET)

lint: clean
	@if command -v swiftlint; then swiftlint; fi

clean:
	rm -rf "$(PWD)/.DerivedData-macos" "$(PWD)/.DerivedData-ios" "$(PWD)/.DerivedData-tvos" "$(WORKSPACE)"

.PHONY: test test-ios test-macos test-tvos coverage percentage
