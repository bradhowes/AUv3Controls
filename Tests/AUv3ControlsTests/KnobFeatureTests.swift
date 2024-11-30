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
    KnobFeature(config: config)
  } withDependencies: { $0.continuousClock = ImmediateClock() }

  init() {}
}

final class KnobFeatureTests: XCTestCase {

  @MainActor
  func testValueChanged() async {
    let ctx = Context()
    await ctx.store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.36000000000000004
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "36"
    }
    await ctx.store.receive(.control(.title(.cancelValueDisplayTimer))) { state in
      state.control.title.formattedValue = nil
    }
  }

  @MainActor
  func testValueEditing() async {
    let ctx = Context()
    await ctx.store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.36000000000000004
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "36"
    }
    await ctx.store.receive(.control(.title(.cancelValueDisplayTimer))) { state in
      state.control.title.formattedValue = nil
    }
    await ctx.store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "36"
    }
  }

  @MainActor
  func SKIP_testAcceptValidEdit() async {
    let ctx = Context()
    await ctx.store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.5
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "50"
    }
    await ctx.store.receive(.control(.title(.cancelValueDisplayTimer))) { state in
      state.control.title.formattedValue = nil
    }
    await ctx.store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "50"
    }
    await ctx.store.send(.editor(.valueChanged("32.124"))) { state in
      state.editor.value = "32.124"
    }
    await ctx.store.send(.editor(.acceptButtonTapped)) { state in
      state.control.track.norm = 0.32124
      state.control.title.formattedValue = "32.124"
      state.editor.focus = nil
    }
    await ctx.store.receive(.control(.title(.cancelValueDisplayTimer))) {
      $0.control.title.formattedValue = nil
    }
  }

  @MainActor
  func testAcceptInvalidEdit() async {
    let ctx = Context()
    await ctx.store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.36000000000000004
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "36"
    }
    await ctx.store.receive(.control(.title(.cancelValueDisplayTimer))) { state in
      state.control.title.formattedValue = nil
    }
    await ctx.store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "36"
    }
    await ctx.store.send(.editor(.clearButtonTapped)) { state in
      state.editor.value = ""
    }
    await ctx.store.send(.editor(.acceptButtonTapped)) { state in
      state.control.track.norm = 0.36000000000000004
      state.control.title.formattedValue = nil
      state.editor.focus = nil
    }
  }

  @MainActor
  func testCancelEdit() async {
    let ctx = Context()
    await ctx.store.send(.control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))) { state in
      state.control.track.norm = 0.36000000000000004
      state.control.track.lastDrag = .init(x: 40, y: -80)
      state.control.title.formattedValue = "36"
    }
    await ctx.store.receive(.control(.title(.cancelValueDisplayTimer))) { state in
      state.control.title.formattedValue = nil
    }
    await ctx.store.send(.control(.title(.titleTapped))) { state in
      state.editor.focus = .value
      state.editor.value = "36"
    }
    await ctx.store.send(.editor(.valueChanged("32.124"))) { state in
      state.editor.value = "32.124"
    }
    await ctx.store.send(.editor(.cancelButtonTapped)) { state in
      state.control.track.norm = 0.36000000000000004
      state.control.title.formattedValue = nil
      state.editor.focus = nil
    }
  }

  @MainActor
  func testChangedValue() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<KnobFeature>

      var body: some SwiftUI.View {
        KnobView(store: store, config: config, proxy: nil)
      }
    }

    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config)) {
      KnobFeature(config: ctx.config)
    } withDependencies: {
      $0.continuousClock = ContinuousClock()
    })

    await view.store.send(
      .control(.track(.dragChanged(start: .init(x: 40, y: 0), position: .init(x: 40, y: -80))))).finish()

    try assertSnapshot(matching: view)
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = KnobViewPreview.previews
      try assertSnapshot(matching: view)
    }
  }
}
