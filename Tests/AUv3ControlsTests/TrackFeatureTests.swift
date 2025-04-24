import AVFoundation
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let param = AUParameterTree.createParameter(
    withIdentifier: "RELEASE",
    name: "Release",
    address: 1,
    min: 0.0,
    max: 100.0,
    unit: .generic,
    unitName: nil,
    valueStrings: nil,
    dependentParameters: nil
  )

  let config: KnobConfig
  let store: TestStore<TrackFeature.State, TrackFeature.Action>!

  init(touchSensitivity: Double = KnobConfig.default.touchSensitivity) {
    self.config = KnobConfig(touchSensitivity: touchSensitivity)
    store = TestStore(initialState: TrackFeature.State(
      norm: 0.0,
      normValueTransform: .init(parameter: param),
      config: config
    )) {
      TrackFeature()
    }
  }
}

final class TrackFeatureTests: XCTestCase {

  @MainActor
  func testInit() {
    let ctx = Context()
    XCTAssertEqual(0.0, ctx.store.state.norm)
    XCTAssertNil(ctx.store.state.lastDrag)
  }
  
  @MainActor
  func testDragChangedAffectedBySensitivity() async {
    var ctx = Context(touchSensitivity: 1.0)
    await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
                                      position: .init(x: ctx.config.controlRadius,
                                                      y: -ctx.config.controlDiameter * 0.4))) { store in
      store.norm = 0.0
      store.lastDrag = CGPoint(x: 50, y: -40)
    }

    await ctx.store.receive(.normChanged(0.4)) {
      $0.norm = 0.4
    }

    ctx = Context(touchSensitivity: 1.0)
    await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
                                  position: .init(x: ctx.config.controlRadius,
                                                  y: -ctx.config.controlDiameter * 0.8))) { store in
      store.norm = 0.0
      store.lastDrag = CGPoint(x: 50, y: -80)
    }

    await ctx.store.receive(.normChanged(0.8)) {
      $0.norm = 0.8
    }
  }
  
//  @MainActor
//  func testDragChangedAffectedByHorizontalOffset() async {
//    let ctx = Context(touchSensitivity: 1.0)
//
//    _ = await ctx.store.withExhaustivity(.off) {
//      await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
//                                        position: .init(x: ctx.config.controlRadius - 10,
//                                                        y: -ctx.config.controlDiameter * 0.7))) { store in
//        store.norm = 0.0
//      }
//
//      await ctx.store.receive(.normChanged(0.0))
//
////      await ctx.store.receive(.normChanged(0.4)) {
////        $0.norm = 0.4
////      }
//
//      await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
//                                        position: .init(x: ctx.config.controlRadius + 10,
//                                                        y: -ctx.config.controlDiameter * 0.7))) { store in
//        store.norm = 0.6300000000000001
//      }
//
////      await ctx.store.receive(.normChanged(0.4)) {
////        $0.norm = 0.4
////      }
//    }
//  }
  
  @MainActor
  func testDragEnded() async {
    let ctx = Context()
    let pos: CGPoint = .init(x: ctx.config.controlRadius, y: -ctx.config.controlDiameter * 0.4)
    await ctx.store.send(.dragEnded(start: .init(x: 0.0, y: 0.0), position: pos))
    await ctx.store.receive(.normChanged(0.2)) {
      $0.norm = 0.2
    }
  }
  
  @MainActor
  func testIndicatorAtMininum() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(
      norm: 0.0,
      normValueTransform: .init(parameter: ctx.param),
      config: ctx.config
    )) {
      TrackFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }
  
  @MainActor
  func testIndicatorAtMiddle() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(
      norm: 0.5,
      normValueTransform: .init(parameter: ctx.param),
      config: ctx.config
    )) {
      TrackFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }
  
  @MainActor
  func testIndicatorAtMaximum() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(
      norm: 1.0,
      normValueTransform: .init(parameter: ctx.param),
      config: ctx.config
    )) {
      TrackFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }
  
  @MainActor
  func testIndicatorStrokeWidth() async throws {
    let ctx = Context()
    let config = KnobConfig()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      let theme = Theme(controlValueStrokeStyle: .init(lineWidth: 4.0, lineCap: .round))
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store)
          .auv3ControlsTheme(theme)
      }
    }

    let view = MyView(config: config, store: Store(initialState: .init(
      norm: 0.5,
      normValueTransform: .init(parameter: ctx.param),
      config: ctx.config
    )) {
      TrackFeature()
    })

    try withSnapshotTesting(record: .failed) {
      try assertSnapshot(matching: view)
    }
  }

//  func testPreview() async throws {
//    try await assertSnapshot(matching: TrackViewPreview.previews)
//  }
}
