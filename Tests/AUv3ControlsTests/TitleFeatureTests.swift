import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

final class TitleFeatureTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var store: TestStore<TitleFeature.State, TitleFeature.Action>!
  let clock = TestClock()

  override func setUpWithError() throws {
    isRecording = false
    config = KnobConfig(parameter: param, theme: Theme())
    store = TestStore(initialState: .init()) {
      TitleFeature(config: config)
    } withDependencies: {
      $0.continuousClock = clock
    }
  }
  
  override func tearDownWithError() throws {
  }
  
  func testInit() {
    XCTAssertNil(store.state.formattedValue)
  }
  
  func testValueChanged() async {
    await store.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await store.send(.valueChanged(12.3456789)) { state in
      state.formattedValue = "12.346"
    }
    await store.send(.valueChanged(0.0)) { state in
      state.formattedValue = "0"
    }
  }

  func testStoppedShowingValue() async {
    await store.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await clock.run()
    await store.receive(.showValueTimerElapsed) { state in
      state.formattedValue = nil
    }
    await clock.advance(by: .seconds(1))
    await clock.run()
  }

  func testTapped() async {
    await store.send(.valueChanged(12.34)) { state in
      state.formattedValue = "12.34"
    }
    await store.send(.titleTapped) { state in
      state.formattedValue = nil
    }
  }

  func testNormalRendering() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TitleFeature>
      
      var body: some SwiftUI.View {
        TitleView(store: store, config: config)
      }
    }
    
    let view = MyView(config: config, store: Store(initialState: .init()) {
      TitleFeature(config: config)
    })
    
    try assertSnapshot(matching: view)

    await view.store.send(.showValueTimerElapsed).finish()
  }
  
  func testShowingValue() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TitleFeature>
      
      var body: some SwiftUI.View {
        TitleView(store: store, config: config)
      }
    }
    
    let view = MyView(config: config, store: Store(initialState: .init()) {
      TitleFeature(config: config)
    } withDependencies: { 
      $0.continuousClock = ContinuousClock()
    })
    
    await view.store.send(.valueChanged(12.34)).finish()

    try assertSnapshot(matching: view)

    await view.store.send(.showValueTimerElapsed).finish()
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = TitleViewPreview.previews
      try assertSnapshot(matching: view)
    }
  }
}
