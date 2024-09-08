import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

final class KnobFeatureTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var store: TestStore<KnobFeature.State, KnobFeature.Action>!

  override func setUpWithError() throws {
    isRecording = false
    config = KnobConfig(parameter: param, theme: Theme())
    store = TestStore(initialState: .init(config: config)) {
      KnobFeature(config: config)
    } withDependencies: { $0.continuousClock = ImmediateClock() }
  }

  override func tearDownWithError() throws {
  }

  func testValueChanged() async {
    await store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.5
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "50"
    }
    await store.receive(.control(.title(.showValueTimerElapsed))) { state in
      state.control.title.formattedValue = nil
    }
  }

  func testValueEditing() async {
    await store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.5
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "50"
    }
    await store.receive(.control(.title(.showValueTimerElapsed))) { state in
      state.control.title.formattedValue = nil
    }
    await store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "50"
    }
  }

  func testAcceptValidEdit() async {
    await store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.5
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "50"
    }
    await store.receive(.control(.title(.showValueTimerElapsed))) { state in
      state.control.title.formattedValue = nil
    }
    await store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "50"
    }
    await store.send(.editor(.valueChanged("32.124"))) { state in
      state.editor.value = "32.124"
    }
    await store.send(.editor(.acceptButtonTapped)) { state in
      state.control.track.norm = 0.32124
      state.control.title.formattedValue = "32.124"
      state.editor.focus = nil
    }
  }

  func testAcceptInvalidEdit() async {
    await store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.5
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "50"
    }
    await store.receive(.control(.title(.showValueTimerElapsed))) { state in
      state.control.title.formattedValue = nil
    }
    await store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "50"
    }
    await store.send(.editor(.clearButtonTapped)) { state in
      state.editor.value = ""
    }
    await store.send(.editor(.acceptButtonTapped)) { state in
      state.control.track.norm = 0.5
      state.control.title.formattedValue = nil
      state.editor.focus = nil
    }
  }

  func testCancelEdit() async {
    await store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.5
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "50"
    }
    await store.receive(.control(.title(.showValueTimerElapsed))) { state in
      state.control.title.formattedValue = nil
    }
    await store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "50"
    }
    await store.send(.editor(.valueChanged("32.124"))) { state in
      state.editor.value = "32.124"
    }
    await store.send(.editor(.cancelButtonTapped)) { state in
      state.control.track.norm = 0.5
      state.control.title.formattedValue = nil
      state.editor.focus = nil
    }
  }

  @MainActor
  func testChangedValue() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<KnobFeature>

      var body: some SwiftUI.View {
        KnobView(store: store, config: config, proxy: nil)
      }
    }

    let view = MyView(config: config, store: Store(initialState: .init(config: config)) {
      KnobFeature(config: config)
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    await view.store.send(
      .control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))).finish()

    try assertSnapshot(matching: view)
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = KnobViewPreview.previews
      try assertSnapshot(matching: view)
    }
  }
}
