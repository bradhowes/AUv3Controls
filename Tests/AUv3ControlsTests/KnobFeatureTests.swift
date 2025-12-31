import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let theme = Theme()
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  let config = KnobConfig()
  let mainQueue = DispatchQueue.test
  let tree: AUParameterTree

  lazy var test = TestStore(initialState: .init(parameter: param)) {
    KnobFeature() { [weak self] address in
      guard let self else { return }
      changed[address] = changed[address]! + 1
    }
  } withDependencies: {
    $0.continuousClock = ImmediateClock()
    $0.mainQueue = mainQueue.eraseToAnyScheduler()
  }

  lazy var live = Store(initialState: .init(parameter: param)) {
    KnobFeature()
  } withDependencies: {
    $0.continuousClock = ImmediateClock()
    $0.mainQueue = DispatchQueue.main.eraseToAnyScheduler()
  }

  var changed: [AUParameterAddress:Int] = [:]

  init() {
    tree = AUParameterTree.createTree(withChildren: [param])
    changed[1] = 0
    changed[2] = 0
  }
}

final class KnobFeatureTests: XCTestCase {

  @MainActor
  func testValueChanged() async {
    let ctx = Context()
    await ctx.test.send(.track(.dragChanged(0.36))) { state in
      state.track.norm = 0.3600000000000
      state.title.formattedValue = "36"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
    await ctx.test.receive(.title(.valueDisplayTimerFired)) {
      $0.title.formattedValue = nil
    }
    await ctx.test.send(.track(.dragChanged(0.0))) { state in
      state.track.norm = 0.0
      state.title.formattedValue = "0"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
    await ctx.test.receive(.title(.valueDisplayTimerFired)) { state in
      state.title.formattedValue = nil
    }
    XCTAssertEqual(ctx.changed[1], 2)
  }

    @MainActor
    func testDragChanged() async {
      let ctx = Context()
      await ctx.test.send(.track(.dragChanged(0.18))) { state in
        state.track.norm = 0.18
        state.title.formattedValue = "18"
      }
      await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
      await ctx.test.receive(.title(.valueDisplayTimerFired)) {
        $0.title.formattedValue = nil
      }
      await ctx.test.finish()
    }
  
    @MainActor
    func testDragEnded() async {
      let ctx = Context()
      await ctx.test.send(.track(.dragChanged(0.18))) { state in
        state.track.norm = 0.180000000000000
        state.title.formattedValue = "18"
      }
      await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
      await ctx.test.receive(.title(.valueDisplayTimerFired)) {
        $0.title.formattedValue = nil
      }
      await ctx.test.send(.track(.dragEnded(0.30))) { state in
        state.track.norm = 0.3
      }
      await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
      await ctx.test.receive(.title(.valueDisplayTimerFired))
      await ctx.test.finish()
    }

  @MainActor
  func testShowEditor() async {
    let ctx = Context()
    await ctx.test.send(.track(.dragChanged(0.36))) { state in
      state.track.norm = 0.3600000000000000
      state.title.formattedValue = "36"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
    await ctx.test.receive(.title(.valueDisplayTimerFired)) {
      $0.title.formattedValue = nil
    }

    await ctx.test.send(.title(.titleTapped(ctx.theme))) {
      $0.$valueEditorInfo.withLock {
        $0 = ValueEditorInfo(
          id: ctx.param.address,
          displayName: ctx.param.displayName,
          value: "36",
          theme: ctx.theme,
          decimalAllowed: .allowed,
          signAllowed: ctx.param.minValue < 0.0 ? .allowed : .none
        )
      }
    }

    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))

    XCTAssertEqual(ctx.changed[1], 1)
  }

  @MainActor
  func testShowEditorViaDoubleTap() async {
    let ctx = Context()

    _ = await ctx.test.withExhaustivity(.off(showSkippedAssertions: false)) {
      await ctx.test.send(.task(theme: ctx.theme)) {
        $0.theme = ctx.theme
      }
    }

    await ctx.test.send(.track(.dragChanged(0.36))) { state in
      state.track.norm = 0.3600000000000000
      state.title.formattedValue = "36"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.showValueMilliseconds))
    await ctx.test.receive(.title(.valueDisplayTimerFired)) {
      $0.title.formattedValue = nil
    }

    await ctx.test.send(.track(.viewTapped(times: 2))) {
      $0.$valueEditorInfo.withLock {
        $0 = ValueEditorInfo(
          id: ctx.param.address,
          displayName: ctx.param.displayName,
          value: "36",
          theme: ctx.theme,
          decimalAllowed: .allowed,
          signAllowed: ctx.param.minValue < 0.0 ? .allowed : .none
        )
      }
    }

    await ctx.test.send(.stopValueObservation) {
      $0.observerToken = nil
    }

    await ctx.test.finish()

    XCTAssertEqual(ctx.changed[1], 1)
  }

  @MainActor
  func testLoneStopObservation() async {
    let ctx = Context()
    await ctx.test.send(.stopValueObservation)
    await ctx.test.finish()
  }

  @MainActor
  func testChangedValue() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<KnobFeature>

      var body: some SwiftUI.View {
        KnobView(store: store)
      }
    }

    let view = MyView(store: ctx.live)

    await view.store.send(
      KnobFeature.Action.track(.dragChanged(0.3))).finish()

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = KnobViewPreview.previews
      try withSnapshotTesting(record: .failed) {
        try assertSnapshot(matching: view, size: .init(width: 220, height: 800))
      }
    }
  }
}
