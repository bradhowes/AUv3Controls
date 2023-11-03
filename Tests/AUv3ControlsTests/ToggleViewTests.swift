import XCTest
import ComposableArchitecture
import AVFoundation

@testable import AUv3Controls

@MainActor
final class ToggleViewTests: XCTestCase {

  let param = AUParameterTree.createBoolean(withIdentifier: "RETRIGGER", name: "Retrigger", address: 1)
  var tree: AUParameterTree!
  var store: TestStore<ToggleReducer.State, ToggleReducer.Action>!

  override func setUpWithError() throws {
    // NOTE: parameter needs to be part of a tree for KVO to work
    tree = AUParameterTree.createTree(withChildren: [param])
    store = TestStore(initialState: ToggleReducer.State(parameter: param)) {
      ToggleReducer()
    }
  }

  override func tearDownWithError() throws {
    tree = nil
  }

  func testInit() {
    XCTAssertEqual(1, store.state.parameter.address)
    XCTAssertEqual("Retrigger", store.state.parameter.displayName)
    XCTAssertEqual("RETRIGGER", store.state.parameter.identifier)
    XCTAssertEqual(0.0, store.state.parameter.minValue)
    XCTAssertEqual(1.0, store.state.parameter.maxValue)
    XCTAssertEqual(0.0, store.state.parameter.value)
    XCTAssertFalse(store.state.isOn)
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
  }

  func testToggleObservations() async {
    store.exhaustivity = .off
    let task = await store.send(.viewAppeared)
    store.exhaustivity = .on

    for value: AUValue in [1.0, 0.2, 0.9, 0.4, 0.6, 0.49, 0.5, -10.0, 1000.0] {
      param.setValue(value, originator: nil)
      await store.receive(.observedValueChanged(value)) {
        $0.isOn = (value >= 0.5)
      }
    }

    await store.send(.stoppedObserving) {
      $0.observerToken = nil
    }

    // Simulate view going away. Should tear down effect monitoring AUParameter
    await task.cancel()

    // Perform new change to show no effects are executed.
    param.setValue(0.0, originator: nil)
  }
}
