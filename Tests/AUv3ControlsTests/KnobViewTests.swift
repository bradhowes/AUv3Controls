import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI
import XCTest

@testable import AUv3Controls


@MainActor
final class KnobViewTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var tree: AUParameterTree!
  var store: TestStore<KnobReducer.State, KnobReducer.Action>!

  func makeStore() {
    store = TestStore(initialState: KnobReducer.State(parameter: param, value: 0.0)) {
      KnobReducer(config: config)
    } withDependencies: { $0.continuousClock = ImmediateClock() }
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

  func testInit() {
    XCTAssertEqual(1, store.state.parameter.address)
    XCTAssertEqual("Release", store.state.parameter.displayName)
    XCTAssertEqual("RELEASE", store.state.parameter.identifier)
    XCTAssertEqual(0.0, store.state.parameter.minValue)
    XCTAssertEqual(100.0, store.state.parameter.maxValue)
    XCTAssertEqual(0.0, store.state.parameter.value)
    XCTAssertEqual(0.0, store.state.value)
  }

  func testDragChangedAffectedBySensitivity() async {
    config.touchSensitivity = 1.0
    makeStore()
    store.exhaustivity = .off

    await store.send(.dragChanged(start: .init(x: config.controlRadius, y: 0.0),
                                  position: .init(x: config.controlRadius,
                                                  y: -config.controlDiameter * 0.7))) { store in
      store.value = 70.0
      store.formattedValue = "70"
    }

    config.touchSensitivity = 2.0
    makeStore()
    store.exhaustivity = .off

    await store.send(.dragChanged(start: .init(x: config.controlRadius, y: 0.0),
                                  position: .init(x: config.controlRadius,
                                                  y: -config.controlDiameter * 0.7))) { store in
      store.value = 35.0
      store.formattedValue = "35"
    }
  }

  func testDragChangedAffectedByHorizontalOffset() async {
    config.touchSensitivity = 1.0

    for offset in [-10.0, 10.0] {
      makeStore()
      store.exhaustivity = .off
      await store.send(.dragChanged(start: .init(x: config.controlRadius, y: 0.0),
                                    position: .init(x: config.controlRadius + offset,
                                                    y: -config.controlDiameter * 0.7))) { store in
        store.value = 52.5
        store.formattedValue = "52.5"
        store.showingValue = true
      }
    }
  }

  func testDragEnded() async {
    await store.send(.dragEnded(start: .init(x: 0.0, y: 0.0), position: .init(x: 1.0, y: 2.0))) { store in
      store.lastDrag = nil
      store.formattedValue = "0"
      store.showingValue = true
    }
  }

  func testTemporarilyShowsValue() async {
    await store.send(.dragEnded(start: .init(x: 0.0, y: 0.0), position: .init(x: 1.0, y: 2.0))) { store in
      store.lastDrag = nil
      store.formattedValue = "0"
      store.showingValue = true
    }

    await store.receive(.showingValueTimerStopped) {
      $0.showingValue = false
    }
  }

  func testObservations() async {
    store.exhaustivity = .off
    let task = await store.send(.viewAppeared)
    store.exhaustivity = .off

    for value: AUValue in [1.0, 10.2, 50.0, 100.0] {
      param.setValue(value, originator: nil)
      await store.receive(.observedValueChanged(value)) {
        $0.value = Double(value)
      }
    }

    store.exhaustivity = .on

    await store.send(.stoppedObserving) {
      $0.observerToken = nil
    }

    // Simulate view going away. Should tear down effect monitoring AUParameter
    await task.cancel()

    // Perform new change to show no effects are executed.
    param.setValue(0.0, originator: nil)
  }

  func testLabelTapped() async {
    await store.send(.labelTapped) {
      $0.showingValueEditor = true
      $0.formattedValue = "0"
      $0.focusedField = .value
    }
  }

  func testCancelButtonTapped() async {
    store.exhaustivity = .on

    await store.send(.observedValueChanged(34)) {
      $0.value = 34
      $0.showingValue = true
      $0.formattedValue = "34"
    }

    await store.send(.labelTapped) {
      $0.showingValueEditor = true
      $0.focusedField = .value
    }

    await store.receive(.showingValueTimerStopped) {
      $0.showingValue = false
    }

    await store.send(.textChanged("1.25")) {
      $0.formattedValue = "1.25"
    }

    await store.send(.cancelButtonTapped) {
      $0.focusedField = nil
      $0.showingValueEditor = false
      $0.value = 34
    }
  }

  func testAcceptButtonTapped() async {
    await store.send(.textChanged("1.25")) {
      $0.formattedValue = "1.25"
    }

    await store.send(.acceptButtonTapped) {
      $0.showingValueEditor = true
      $0.value = 1.25
      $0.formattedValue = "1.25"
      $0.showingValue = true
      $0.showingValueEditor = false
      $0.focusedField = nil
      $0.norm = 0.0125
    }
  }

  func testClearButtonTapped() async {

    await store.send(.textChanged("1.25")) {
      $0.formattedValue = "1.25"
    }

    await store.send(.clearButtonTapped) {
      $0.formattedValue = ""
    }
  }
}
