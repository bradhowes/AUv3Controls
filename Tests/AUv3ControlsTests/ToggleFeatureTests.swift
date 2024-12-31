import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let param = AUParameterTree.createBoolean(withIdentifier: "RETRIGGER", name: "Retrigger", address: 10)
  lazy var tree = AUParameterTree.createTree(withChildren: [param])

  func makeStore() -> TestStoreOf<ToggleFeature> {
    TestStore(initialState: ToggleFeature.State(parameter: tree.parameter(withAddress: 10)!, theme: Theme())) {
      ToggleFeature()
    }
  }
}

final class ToggleFeatureTests: XCTestCase {

  @MainActor
  func testInit() {
    let ctx = Context()
    let store = ctx.makeStore()
    XCTAssertEqual(10, store.state.parameter.address)
    XCTAssertEqual("Retrigger", store.state.parameter.displayName)
    XCTAssertEqual("RETRIGGER", store.state.parameter.identifier)
    XCTAssertEqual(0.0, store.state.parameter.minValue)
    XCTAssertEqual(1.0, store.state.parameter.maxValue)
    XCTAssertEqual(0.0, store.state.parameter.value)
    XCTAssertFalse(store.state.isOn)
  }

  @MainActor
  func testToggleObservations() async {
    let ctx = Context()
    let store = ctx.makeStore()

    _ = await store.withExhaustivity(.off) {
      await store.send(.task)
    }

    ctx.param.setValue(1.0, originator: nil)
    await store.receive(.observedValueChanged(1.0))
    await store.receive(.animatedObservedValueChanged(true)) { $0.isOn = true }

    ctx.param.setValue(0.0, originator: nil)
    await store.receive(.observedValueChanged(0.0))
    await store.receive(.animatedObservedValueChanged(false)) { $0.isOn = false }

    await store.send(.stopValueObservation) {
      $0.observerToken = nil
    }
  }

  @MainActor
  func testToggling() async {
    let ctx = Context()
    let store = ctx.makeStore()

    _ = await store.withExhaustivity(.off) {
      await store.send(.task)
    }

    await store.send(.toggleTapped) {
      $0.isOn = true
    }
    XCTAssertEqual(1.0, ctx.param.value)

    await store.send(.toggleTapped) {
      $0.isOn = false
    }
    XCTAssertEqual(0.0, ctx.param.value)

    await store.send(.stopValueObservation) {
      $0.observerToken = nil
    }
  }

  @MainActor
  func testOffRendering() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      @State var store: StoreOf<ToggleFeature>

      var body: some SwiftUI.View {
        ToggleView(store: store)
      }
    }

    let view = MyView(store: Store(initialState: .init(parameter: ctx.param, theme: Theme(), isOn: false)) {
      ToggleFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }

    await view.store.send(.stopValueObservation).finish()
  }

  @MainActor
  func testOnRendering() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      @State var store: StoreOf<ToggleFeature>

      var body: some SwiftUI.View {
        ToggleView(store: store)
      }
    }

    let view = MyView(store: Store(initialState: .init(parameter: ctx.param, theme: Theme(), isOn: true)) {
      ToggleFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }

    await view.store.send(.stopValueObservation).finish()
  }

  @MainActor
  func testToggleViewPreview() async throws {
    let view = ToggleViewPreview.previews
    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }
}
