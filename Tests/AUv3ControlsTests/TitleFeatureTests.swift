import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
final class TitleFeatureTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var store: TestStore<TitleFeature.State, TitleFeature.Action>!
  
  override func setUpWithError() throws {
    config = KnobConfig(parameter: param, logScale: false, theme: Theme())
    store = TestStore(initialState: .init()) {
      TitleFeature(config: config)
    } withDependencies: { $0.continuousClock = ImmediateClock() }
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
    await store.receive(.stoppedShowingValue) {
      $0.formattedValue = nil
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
    
#if os(iOS)
    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .dark)))
#endif
    
    view.store.send(.stoppedShowingValue)
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
    
    view.store.send(.valueChanged(12.34))
    
#if os(iOS)
    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .dark)))
#endif
    
    await view.store.send(.stoppedShowingValue).finish()
  }
}