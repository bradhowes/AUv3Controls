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
  lazy var config = KnobConfig(parameter: param, theme: Theme())
  lazy var store = TestStore(initialState: .init(config: config)) {
    TitleFeature()
  } withDependencies: {
    $0.continuousClock = clock
  }

  init() {}
}

final class TitleFeatureTests: XCTestCase {

  @MainActor
  func testInit() {
    let ctx = Context()
    XCTAssertNil(ctx.store.state.formattedValue)
  }
  
  @MainActor
  func testValueChanged() async {
    let ctx = Context()
    await ctx.store.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await ctx.clock.advance(by: .seconds(ctx.config.theme.controlShowValueDuration / 2.0))
    await ctx.store.send(.valueChanged(56.78)) { state in
      state.formattedValue = "56.78"
    }
    await ctx.clock.advance(by: .seconds(ctx.config.theme.controlShowValueDuration))
    await ctx.store.receive(.cancelValueDisplayTimer) {
      $0.formattedValue = nil
    }
  }

  @MainActor
  func testStoppedShowingValue() async {
    let ctx = Context()
    await ctx.store.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await ctx.clock.run()
    await ctx.store.receive(.cancelValueDisplayTimer) { state in
      state.formattedValue = nil
    }
  }

  @MainActor
  func testTapped() async {
    let ctx = Context()
    await ctx.store.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await ctx.store.send(.titleTapped) { state in
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
        TitleView(store: store, config: config)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config)) {
      TitleFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }

    await view.store.send(.cancelValueDisplayTimer).finish()
  }
  
  @MainActor
  func testShowingValue() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TitleFeature>
      
      var body: some SwiftUI.View {
        TitleView(store: store, config: config)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config)) {
      TitleFeature()
    } withDependencies: { 
      $0.continuousClock = ContinuousClock()
    })
    
    await view.store.send(.valueChanged(12.34)).finish()

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }

    await view.store.send(.cancelValueDisplayTimer).finish()
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
