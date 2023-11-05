import AVFoundation
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
final class KnobViewUITests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "BLAH", name: "Release", address: 100,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var tree: AUParameterTree!
  var store: Store<KnobReducer.State, KnobReducer.Action>!

  func makeStore() {
    store = Store(initialState: KnobReducer.State(parameter: param, value: 0.0)) {
      KnobReducer(config: config)
    }
  }

  override func setUpWithError() throws {
    config = KnobConfig(parameter: param, logScale: false, theme: Theme())
    // NOTE: parameter needs to be part of a tree for KVO to work
    tree = AUParameterTree.createTree(withChildren: [param])
    makeStore()
  }

  override func tearDownWithError() throws {
    tree = nil
  }

  func testInitialRendering() async throws {
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<KnobReducer>
      let config: KnobConfig

      var body: some SwiftUI.View {
        KnobView(store: store, config: config, scrollViewProxy: nil)
      }
    }

    let view = MyView(store: store, config: config)

#if os(iOS)
    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .dark)),
      named: "device")
#endif
  }

  /// FIXME: for some reason, when this is enabled, a toggle test fails (!) but *only* when running all
  /// tests. Running by itself is fine.
  func _testShowingValue() async throws {
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<KnobReducer>
      let config: KnobConfig

      var body: some SwiftUI.View {
        KnobView(store: store, config: config, scrollViewProxy: nil)
      }
    }

    let view = MyView(store: Store(initialState: KnobReducer.State(parameter: param, value: 0.0)) {
      KnobReducer(config: config)
    }, config: config)

    view.store.send(.observedValueChanged(50.0))

#if os(iOS)
    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .dark)),
      named: "device")
#endif
  }

  func testShowingEditor() async throws {
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<KnobReducer>
      let config: KnobConfig

      var body: some SwiftUI.View {
        KnobView(store: store, config: config, scrollViewProxy: nil)
      }
    }

    let view = MyView(store: Store(initialState: KnobReducer.State(parameter: param, value: 23.45)) {
      KnobReducer(config: config)
    }, config: config)

    view.store.send(.labelTapped)

#if os(iOS)
    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhoneSe), traits: .init(userInterfaceStyle: .dark)),
      named: "device")
#endif
  }
}
