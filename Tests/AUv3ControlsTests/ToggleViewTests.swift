import AVFoundation
import Clocks
import ComposableArchitecture
import XCTest

@testable import AUv3Controls

@MainActor
final class ToggleViewTests: XCTestCase {
  let param = AUParameterTree.createBoolean(withIdentifier: "RETRIGGER", name: "Retrigger", address: 10)
  var tree: AUParameterTree!
  var store: TestStore<ToggleReducer.State, ToggleReducer.Action>!
  
  override func setUpWithError() throws {
    tree = AUParameterTree.createTree(withChildren: [param])
    store = TestStore(initialState: ToggleReducer.State(parameter: param)) {
      ToggleReducer()
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
    store.exhaustivity = .off
    await store.send(.viewAppeared)
    store.exhaustivity = .on

    param.setValue(1.0, originator: nil)
    await store.receive(.observedValueChanged(1.0)) {
      $0.isOn = true
    }

    await store.send(.stoppedObserving) {
      $0.observerToken = nil
    }
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

    await store.send(.stoppedObserving) {
      $0.observerToken = nil
    }
  }
}
