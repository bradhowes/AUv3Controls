import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
final class ToggleFeatureTests: XCTestCase {
  let param = AUParameterTree.createBoolean(withIdentifier: "RETRIGGER", name: "Retrigger", address: 10)
  var tree: AUParameterTree!
  var store: TestStore<ToggleFeature.State, ToggleFeature.Action>!

  override func setUpWithError() throws {
    tree = AUParameterTree.createTree(withChildren: [param])
    store = TestStore(initialState: ToggleFeature.State(parameter: param)) {
      ToggleFeature()
    } withDependencies: { $0.continuousClock = ImmediateClock() }
  }

  override func tearDownWithError() throws {
  }

  func testInit() {
    XCTAssertEqual(10, store.state.parameter.address)
    XCTAssertEqual("Retrigger", store.state.parameter.displayName)
    XCTAssertEqual("RETRIGGER", store.state.parameter.identifier)
    XCTAssertEqual(0.0, store.state.parameter.minValue)
    XCTAssertEqual(1.0, store.state.parameter.maxValue)
    XCTAssertEqual(0.0, store.state.parameter.value)
    XCTAssertFalse(store.state.isOn)
  }

  func testToggleObservations() async {
    print("begin")
    store.exhaustivity = .off
    await store.send(.viewAppeared)
    store.exhaustivity = .on

    param.setValue(1.0, originator: nil)
    await store.receive(.observedValueChanged(1.0)) {
      $0.isOn = true
    }

    await store.send(.observationStopped) {
      $0.observerToken = nil
    }
    print("done")
  }

  func testToggling() async {
    store.exhaustivity = .off
    await store.send(.viewAppeared)

    await store.send(.toggleTapped) {
      $0.isOn = true
    }
    XCTAssertEqual(1.0, param.value)

    await store.send(.toggleTapped) {
      $0.isOn = false
    }
    XCTAssertEqual(0.0, param.value)

    await store.send(.observationStopped) {
      $0.observerToken = nil
    }
  }

#if os(iOS)

  func testOffRendering() async throws {
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<ToggleFeature>

      var body: some SwiftUI.View {
        ToggleView(store: store, theme: Theme())
      }
    }

    let view = MyView(store: Store(initialState: .init(parameter: param, isOn: false)) {
      ToggleFeature()
    })

    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))

    await view.store.send(.observationStopped).finish()
  }

  func testOnRendering() async throws {
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<ToggleFeature>

      var body: some SwiftUI.View {
        ToggleView(store: store, theme: Theme())
      }
    }

    let view = MyView(store: Store(initialState: .init(parameter: param, isOn: true)) {
      ToggleFeature()
    })

    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))

    await view.store.send(.observationStopped).finish()
  }


  func testToggleViewPreview() async throws {
    let view = ToggleViewPreview.previews
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))
  }

#endif
}
