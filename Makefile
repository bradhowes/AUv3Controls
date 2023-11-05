PLATFORM_IOS = iOS Simulator,name=iPhone 14 Pro
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (3rd generation) (at 1080p)
TARGET = AUv3Controls
DOCC_DIR = ./docs
QUIET = -quiet
WORKSPACE = $(PWD)/.workspace

default: percentage

clean:
	rm -rf "$(PWD)/.DerivedData-macos" "$(PWD)/.DerivedData-ios" "$(PWD)/.DerivedData-tvos" "$(WORKSPACE)"

lint: clean
	@if command -v swiftlint; then swiftlint; fi

resolve-deps: lint
	xcodebuild \
		$(QUIET) \
		-resolvePackageDependencies \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET)

build-ios: resolve-deps
	xcodebuild build-for-testing \
		$(QUIET) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-ios" \
		-destination platform="$(PLATFORM_IOS)" \
		-enableCodeCoverage YES

test-ios: build-ios
	xcodebuild test-without-building \
		$(QUIET) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-ios" \
		-destination platform="$(PLATFORM_IOS)"

build-tvos: resolve-deps
	xcodebuild build-for-testing \
		$(QUIET) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-tvos" \
		-destination platform="$(PLATFORM_TVOS)" \
		-enableCodeCoverage YES

test-tvos: build-tvos
	xcodebuild test-without-building \
		$(QUIET) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-tvos" \
		-destination platform="$(PLATFORM_TVOS)"

build-macos: resolve-deps
	xcodebuild build-for-testing \
		$(QUIET) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-macos" \
		-destination platform="$(PLATFORM_MACOS)"

test-macos: build-macos
	xcodebuild test-without-building \
		$(QUIET) \
		-clonedSourcePackagesDirPath "$(WORKSPACE)" \
		-scheme $(TARGET) \
		-derivedDataPath "$(PWD)/.DerivedData-macos" \
		-destination platform="$(PLATFORM_MACOS)" \
		-enableCodeCoverage YES

coverage-ios: test-ios
	xcrun xccov view --report --only-targets $(PWD)/.DerivedData-ios/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

coverage-macos: test-macos
	xcrun xccov view --report --only-targets $(PWD)/.DerivedData-macos/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

percentage: coverage-ios
	awk '/ $(TARGET) / { if ($$3 > 0) print $$4; }' coverage.txt > percentage.txt
	cat percentage.txt

test: test-ios test-macos test-tvos

.PHONY: test test-ios test-macos test-tvos coverage percentage
