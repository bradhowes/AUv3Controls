import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let config = KnobConfig()
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)

  func makeStore() -> TestStore<ControlFeature.State, ControlFeature.Action> {
    .init(initialState: .init(
      displayName: param.displayName,
      norm: 0,
      config: config
    )) {
      ControlFeature(formatter: KnobValueFormatter.general(), normValueTransform: .init(parameter: param))
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
  }
}

final class ControlFeatureTests: XCTestCase {

  @MainActor
  func testInit() {
    let ctx = Context()
    XCTAssertEqual(0.0, ctx.makeStore().state.track.norm)
  }
  
  @MainActor
  func testDragChanged() async {
    let ctx = Context()
    let store = ctx.makeStore()
    await store.send(.track(.dragChanged(0.18))) { state in
      state.track.norm = 0.18
      state.title.formattedValue = "18"
    }
    await store.receive(.title(.cancelValueDisplayTimer)) {
      $0.title.formattedValue = nil
    }
    await store.finish()
  }

  @MainActor
  func testDragEnded() async {
    let ctx = Context()
    let store = ctx.makeStore()
    await store.send(.track(.dragChanged(0.18))) { state in
      state.track.norm = 0.180000000000000
      state.title.formattedValue = "18"
    }
    await store.receive(.title(.cancelValueDisplayTimer)) {
      $0.title.formattedValue = nil
    }
    await store.send(.track(.dragEnded(0.30))) { state in
      state.track.norm = 0.3
    }
    await store.receive(.title(.cancelValueDisplayTimer))
    await store.finish()
  }

  @MainActor
  func testDragged() async throws {
    let ctx = Context()
    struct MyView: View {
      let config: KnobConfig
      @State var store: StoreOf<ControlFeature>
      var body: some View {
        ControlView(store: store)
      }
    }

    let view = MyView(config: ctx.config, store: Store(initialState: .init(
      displayName: ctx.param.displayName,
      norm: 0.0,
      config: ctx.config
    )) {
      ControlFeature(formatter: KnobValueFormatter.general(1...2), normValueTransform: .init(parameter: ctx.param))
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    await view.store.send(.track(.dragChanged(0.18))).finish()

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }
  
  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = ControlViewPreview.previews
      try withSnapshotTesting(record: .failed) {
        try assertSnapshot(matching: view)
      }
    }
  }
}
