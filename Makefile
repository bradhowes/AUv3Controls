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

docc:
	DOCC_JSON_PRETTYPRINT="YES" \
	swift package \
		--allow-writing-to-directory $(DOCC_DIR) \
		generate-documentation \
		--target $(TARGET) \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path swift-math-parser \
		--output-path $(DOCC_DIR)

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
		-destination platform="$(PLATFORM_IOS)"

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
		-destination platform="$(PLATFORM_TVOS)"

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

test-linux: lint
	docker build -t swiftlang -f swiftlang.dockerfile .
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift57 \
		bash -c 'make test-swift'

test-swift: lint
	swift test --parallel

coverage: test-macos
	xcrun xccov view --report --only-targets $(PWD)/.DerivedData-macos/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

percentage: coverage
	awk '/ $(TARGET) / { if ($$3 > 0) print $$4; }' coverage.txt > percentage.txt
	cat percentage.txt

test: test-ios test-tvos percentage

.PHONY: test test-ios test-macos test-tvos coverage percentage test-linux test-swift
