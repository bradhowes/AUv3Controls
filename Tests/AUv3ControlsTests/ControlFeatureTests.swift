import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
final class ControlFeatureTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var store: TestStore<ControlFeature.State, ControlFeature.Action>!

  override func setUpWithError() throws {
    isRecording = false
    config = KnobConfig(parameter: param, logScale: false, theme: Theme())
    store = TestStore(initialState: .init(config: config)) {
      ControlFeature(config: config)
    } withDependencies: { $0.continuousClock = ImmediateClock() }
  }
  
  override func tearDownWithError() throws {
  }
  
  func testInit() {
    XCTAssertEqual(0.0, store.state.track.norm)
  }
  
  func testDragChanged() async {
    await store.send(.track(.dragChanged(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))) { state in
      state.track.norm = 0.25
      state.track.lastDrag = .init(x: 40, y: -40)
      state.title.formattedValue = "25"
    }
  }

  func testDragEnded() async {
    await store.send(.track(.dragChanged(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))) { state in
      state.track.norm = 0.25
      state.track.lastDrag = .init(x: 40, y: -40)
      state.title.formattedValue = "25"
    }
    await store.send(.track(.dragEnded(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))) { state in
      state.track.norm = 0.25
      state.track.lastDrag = nil
      state.title.formattedValue = "25"
    }
  }

#if os(iOS)

  func testDragged() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<ControlFeature>

      var body: some SwiftUI.View {
        ControlView(store: store, config: config, proxy: nil)
      }
    }

    let view = MyView(config: config, store: Store(initialState: .init(config: config)) {
      ControlFeature(config: config)
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    view.store.send(.track(.dragChanged(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40))))

    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))

  }
  
  func testPreview() async throws {
    withDependencies { $0 = .live } operation: {
      let view = ControlViewPreview.previews
      assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                          traits: .init(userInterfaceStyle: .dark)))
    }
  }

#endif
}
