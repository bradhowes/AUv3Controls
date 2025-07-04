import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let theme = Theme()
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  let config = KnobConfig()
  let mainQueue = DispatchQueue.test

  lazy var test = TestStore(initialState: .init(parameter: param)) {
    KnobFeature(formatter: KnobValueFormatter.general(), normValueTransform: .init(parameter: param)) { [weak self] address in
      guard let self else { return }
      changed[address] = changed[address]! + 1
    }
  } withDependencies: {
    $0.continuousClock = ImmediateClock()
    $0.mainQueue = mainQueue.eraseToAnyScheduler()
  }

  lazy var live = Store(initialState: .init(parameter: param)) {
    KnobFeature(formatter: KnobValueFormatter.general(), normValueTransform: .init(parameter: param))
  } withDependencies: {
    $0.continuousClock = ImmediateClock()
    $0.mainQueue = DispatchQueue.main.eraseToAnyScheduler()
  }

  var changed: [AUParameterAddress:Int] = [:]

  init() {
    changed[1] = 0
    changed[2] = 0
  }
}

final class KnobFeatureTests: XCTestCase {

  @MainActor
  func testValueChanged() async {
    let ctx = Context()
    await ctx.test.send(.control(.track(.dragChanged(0.36)))) { state in
      state.control.track.norm = 0.3600000000000
      state.control.title.formattedValue = "36"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
    await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) {
      $0.control.title.formattedValue = nil
    }
    await ctx.test.send(.control(.track(.dragChanged(0.0)))) { state in
      state.control.track.norm = 0.0
      state.control.title.formattedValue = "0"
    }
    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
    await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) { state in
      state.control.title.formattedValue = nil
    }
    XCTAssertEqual(ctx.changed[1], 2)
  }

//  @MainActor
//  func testValueEditing() async {
//    let ctx = Context()
//    _ = await ctx.test.withExhaustivity(.off) {
//      await ctx.test.send(.control(.track(.dragChanged(0.36)))) { state in
//        state.control.track.norm = 0.3600000000000000
//        state.control.title.formattedValue = "36"
//      }
//      await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
//      await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) {
//        $0.control.title.formattedValue = nil
//      }
//      await ctx.test.send(.control(.title(.titleTapped))) { state in
//        state.editor.focus = .value
//        state.editor.value = "36"
//      }
//    }
//  }
//
//  @MainActor
//  func testAcceptValidEdit() async {
//    let ctx = Context()
//    _ = await ctx.test.withExhaustivity(.off) {
//      await ctx.test.send(.control(.track(.dragChanged(0.36)))) { state in
//        state.control.track.norm = 0.3600000000000000
//        state.control.title.formattedValue = "36"
//      }
//      await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
//      await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) {
//        $0.control.title.formattedValue = nil
//      }
//      await ctx.test.send(.control(.title(.titleTapped))) { state in
//        state.editor.focus = .value
//        state.editor.value = "36"
//      }
//      await ctx.test.send(.editor(.valueChanged("32.124"))) { state in
//      }
//      await ctx.test.send(.editor(.acceptButtonTapped)) { state in
//        state.control.title.formattedValue = "32"
//        state.editor.focus = nil
//      }
//      await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
//      await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) {
//        $0.control.title.formattedValue = nil
//      }
//    }
//    XCTAssertEqual(ctx.changed[1], 2)
//  }
//
//  @MainActor
//  func testAcceptInvalidEdit() async {
//    let ctx = Context()
//    await ctx.test.send(.control(.track(.dragChanged(0.36)))) { state in
//      state.control.track.norm = 0.3600000000000000
//      state.control.title.formattedValue = "36"
//    }
//    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
//    await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) {
//      $0.control.title.formattedValue = nil
//    }
//    await ctx.test.send(.control(.title(.titleTapped))) { state in
//      state.editor.focus = .value
//      state.editor.value = "36"
//      state.showingEditor = true
//      state.scrollToDestination = 1
//    }
//    await ctx.test.send(.editor(.clearButtonTapped)) { state in
//      state.editor.value = ""
//    }
//    await ctx.test.send(.editor(.acceptButtonTapped)) { state in
//      state.control.track.norm = 0.3600000000000000
//      state.control.title.formattedValue = nil
//      state.editor.focus = nil
//    }
//  }
//
//  @MainActor
//  func testCancelEdit() async {
//    let ctx = Context()
//    await ctx.test.send(.control(.track(.dragChanged(0.36)))) { state in
//      state.control.track.norm = 0.3600000000000000
//      state.control.title.formattedValue = "36"
//    }
//    await ctx.mainQueue.advance(by: .milliseconds(KnobConfig.default.controlShowValueMilliseconds))
//    await ctx.test.receive(.control(.title(.valueDisplayTimerFired))) {
//      $0.control.title.formattedValue = nil
//    }
//    await ctx.test.send(.control(.title(.titleTapped))) { state in
//      state.editor.focus = .value
//      state.editor.value = "36"
//      state.showingEditor = true
//      state.scrollToDestination = 1
//    }
//    await ctx.test.send(.editor(.valueChanged("32.124"))) { state in
//      state.editor.value = "32.124"
//    }
//    await ctx.test.send(.editor(.cancelButtonTapped)) { state in
//      state.control.track.norm = 0.3600000000000000
//      state.control.title.formattedValue = nil
//      state.editor.focus = nil
//      state.scrollToDestination = nil
//      state.showingEditor = false
//    }
//  }
//
  @MainActor
  func testChangedValue() async throws {
    let ctx = Context()
    struct MyView: SwiftUI.View {
      @State var store: StoreOf<KnobFeature>

      var body: some SwiftUI.View {
        KnobView(store: store)
      }
    }

    let view = MyView(store: ctx.live)

    await view.store.send(
      KnobFeature.Action.control(.track(.dragChanged(0.0)))).finish()

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }

  @MainActor
  func testPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = KnobViewPreview.previews
      try withSnapshotTesting(record: .failed) {
        try assertSnapshot(matching: view)
      }
    }
  }
}
