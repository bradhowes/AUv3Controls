import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

final class EditorFeatureTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var store: TestStore<EditorFeature.State, EditorFeature.Action>!
  
  override func setUpWithError() throws {
    isRecording = false
    config = KnobConfig(parameter: param, theme: Theme())
    store = TestStore(initialState: .init()) {
      EditorFeature(config: config)
    } withDependencies: { $0.continuousClock = ImmediateClock() }
  }
  
  override func tearDownWithError() throws {
  }
  
  func testValueChanged() async {
    await store.send(.valueChanged("12.34")) { state in
      state.value = "12.34"
    }
    await store.send(.valueChanged("")) { state in
      state.value = ""
    }
    await store.send(.valueChanged("abcdefg")) { state in
      state.value = "abcdefg"
    }
  }

  func testAcceptButtonTapped() async {
    await store.send(.start(12.34)) { state in
      state.value = "12.34"
      state.focus = .value
    }
    await store.send(.acceptButtonTapped) { state in
      state.focus = nil
    }
  }

  func testCancelButtonTapped() async {
    await store.send(.start(12.34)) { state in
      state.value = "12.34"
      state.focus = .value
    }
    await store.send(.acceptButtonTapped) { state in
      state.focus = nil
    }
  }

  func testClearButtonTapped() async {
    await store.send(.valueChanged("12.34")) { state in
      state.value = "12.34"
    }

    await store.send(.clearButtonTapped) { state in
      state.value = ""
    }
  }

  func testEditingValue() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<EditorFeature>

      var body: some SwiftUI.View {
        EditorView(store: store, config: config)
      }
    }

    let view = MyView(config: config, store: Store(initialState: .init()) {
      EditorFeature(config: config)
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    view.store.send(.valueChanged("12.34"))

    try assertSnapshot(matching: view)
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = EditorViewPreview.previews
      try assertSnapshot(matching: view)
    }
  }
}
