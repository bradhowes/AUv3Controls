import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  lazy var config = KnobConfig(parameter: param, theme: Theme())

  func makeStore() -> TestStore<ControlFeature.State, ControlFeature.Action> {
    .init(initialState: .init(config: config, value: 0)) {
      ControlFeature(config: config)
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
    await store.send(.track(.dragChanged(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))) { state in
      state.track.norm = 0.25
      state.track.lastDrag = .init(x: 40, y: -40)
      state.title.formattedValue = "25"
    }
    await store.receive(.title(.showValueTimerElapsed)) {
      $0.title.formattedValue = nil
    }
    await store.finish()
  }

  @MainActor
  func testDragEnded() async {
    let ctx = Context()
    let store = ctx.makeStore()
    await store.send(.track(.dragChanged(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))) { state in
      state.track.norm = 0.25
      state.track.lastDrag = .init(x: 40, y: -40)
      state.title.formattedValue = "25"
    }
    await store.receive(.title(.showValueTimerElapsed)) {
      $0.title.formattedValue = nil
    }
    await store.send(.track(.dragEnded(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))) { state in
      state.track.norm = 0.25
      state.track.lastDrag = nil
      state.title.formattedValue = "25"
    }
    await store.receive(.title(.showValueTimerElapsed)) {
      $0.title.formattedValue = nil
    }
  }

  @MainActor
  func testDragged() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<ControlFeature>

      var body: some SwiftUI.View {
        ControlView(store: store, config: config)
      }
    }

    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config, value: 0.0)) {
      ControlFeature(config: ctx.config)
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    await view.store.send(.track(.dragChanged(start: .init(x: 40, y: 0.0), position: .init(x: 40, y: -40)))).finish()

    try assertSnapshot(matching: view)
  }
  
  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = ControlViewPreview.previews
      try assertSnapshot(matching: view)
    }
  }
}
