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
  lazy var store = TestStore(initialState: .init(config: config)) {
    EditorFeature()
  } withDependencies: { $0.continuousClock = ImmediateClock() }

  init() {}
}

final class EditorFeatureTests: XCTestCase {

  @MainActor
  func testValueChanged() async {
    let ctx = Context()
    await ctx.store.send(.valueChanged("12.34")) { state in
      state.value = "12.34"
    }
    await ctx.store.send(.valueChanged("")) { state in
      state.value = ""
    }
    await ctx.store.send(.valueChanged("abcdefg")) { state in
      state.value = "abcdefg"
    }
  }

  @MainActor
  func testAcceptButtonTapped() async {
    let ctx = Context()
    await ctx.store.send(.beginEditing(12.34)) { state in
      state.value = "12.34"
      state.focus = .value
    }
    await ctx.store.send(.acceptButtonTapped) { state in
      state.focus = nil
    }
  }

  @MainActor
  func testCancelButtonTapped() async {
    let ctx = Context()
    await ctx.store.send(.beginEditing(12.34)) { state in
      state.value = "12.34"
      state.focus = .value
    }
    await ctx.store.send(.acceptButtonTapped) { state in
      state.focus = nil
    }
  }

  @MainActor
  func testClearButtonTapped() async {
    let ctx = Context()
    await ctx.store.send(.valueChanged("12.34")) { state in
      state.value = "12.34"
    }

    await ctx.store.send(.clearButtonTapped) { state in
      state.value = ""
    }
  }

  @MainActor
  func testEditingValue() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<EditorFeature>

      var body: some SwiftUI.View {
        EditorView(store: store)
      }
    }

    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config)) {
      EditorFeature()
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    await view.store.send(.valueChanged("12.34")).finish()

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = EditorViewPreview.previews
      try withSnapshotTesting(record: .failed) {
        try assertSnapshot(matching: view)
      }
    }
  }
}
