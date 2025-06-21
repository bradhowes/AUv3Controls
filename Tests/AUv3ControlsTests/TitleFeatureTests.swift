import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  let clock = TestClock()
  let config = KnobConfig.default
  let mainQueue = DispatchQueue.test

  lazy var test = TestStore(initialState: .init(displayName: param.displayName)) {
    TitleFeature(formatter: KnobValueFormatter.general(1...4))
  } withDependencies: {
    $0.continuousClock = clock
    $0.mainQueue = mainQueue.eraseToAnyScheduler()
  }

  lazy var live = Store(initialState: .init(displayName: param.displayName)) {
    TitleFeature(formatter: KnobValueFormatter.general(1...4))
  } withDependencies: {
    $0.continuousClock = ImmediateClock()
    $0.mainQueue = DispatchQueue.main.eraseToAnyScheduler()
  }

  init() {}
}

final class TitleFeatureTests: XCTestCase {

  @MainActor
  func testInit() {
    let ctx = Context()
    XCTAssertNil(ctx.test.state.formattedValue)
  }
  
  @MainActor
  func testValueChanged() async {
    let ctx = Context()
    await ctx.test.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await ctx.clock.advance(by: .milliseconds(ctx.config.controlShowValueMilliseconds) / 2.0)
    await ctx.test.send(.valueChanged(56.78)) { state in
      state.formattedValue = "56.78"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
    await ctx.test.receive(.valueDisplayTimerFired) {
      $0.formattedValue = nil
    }
  }

  @MainActor
  func testStoppedShowingValue() async {
    let ctx = Context()
    await ctx.test.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await ctx.clock.run()
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
    await ctx.test.receive(.valueDisplayTimerFired) { state in
      state.formattedValue = nil
    }
  }

  @MainActor
  func testTapped() async {
    let ctx = Context()
    await ctx.test.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await ctx.test.send(.titleTapped) { state in
      state.formattedValue = nil
    }
    // Nothing should be running now.
  }

  @MainActor
  func testNormalRendering() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TitleFeature>
      
      var body: some SwiftUI.View {
        TitleView(store: store)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(displayName: ctx.param.displayName)) {
        TitleFeature(formatter: KnobValueFormatter.general(1...2))
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }
  
  @MainActor
  func testShowingValue() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<TitleFeature>

      var body: some SwiftUI.View {
        TitleView(store: store)
      }
    }

    let view = MyView(store: ctx.live)

    await view.store.send(TitleFeature.Action.valueChanged(12.34)).finish()

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = TitleViewPreview.previews
      try withSnapshotTesting(record: .failed) {
        try assertSnapshot(matching: view)
      }
    }
  }
}

struct MyView: SwiftUI.View {
  @State var store: StoreOf<TitleFeature>

  var body: some SwiftUI.View {
    TitleView(store: store)
  }
}
