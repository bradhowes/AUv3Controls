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

  lazy var config = KnobConfig(parameter: param, theme: Theme())
  var store: TestStore<TrackFeature.State, TrackFeature.Action>!

  func makeStore() {
    store = TestStore(initialState: TrackFeature.State(config: config, norm: 0.0)) {
      TrackFeature()
    }
  }

  init() {
    makeStore()
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
    let ctx = Context()
    ctx.config.touchSensitivity = 1.0

    await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
                                      position: .init(x: ctx.config.controlRadius,
                                                      y: -ctx.config.controlDiameter * 0.4))) { store in
      store.norm = 0.20
      store.lastDrag = CGPoint(x: 50, y: -40)
    }
    
    ctx.config.touchSensitivity = 2.0
    ctx.makeStore()

    await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
                                  position: .init(x: ctx.config.controlRadius,
                                                  y: -ctx.config.controlDiameter * 0.8))) { store in
      store.norm = 0.40
      store.lastDrag = CGPoint(x: 50, y: -80)
    }
  }
  
  @MainActor
  func testDragChangedAffectedByHorizontalOffset() async {
    let ctx = Context()
    ctx.config.touchSensitivity = 1.0
    
    for offset in [-10.0, 10.0] {
      ctx.makeStore()
      _ = await ctx.store.withExhaustivity(.off) {
        await ctx.store.send(.dragChanged(start: .init(x: ctx.config.controlRadius, y: 0.0),
                                          position: .init(x: ctx.config.controlRadius + offset,
                                                          y: -ctx.config.controlDiameter * 0.7))) { store in
          store.norm = 0.6300000000000001
        }
      }
    }
  }
  
  @MainActor
  func testDragEnded() async {
    let ctx = Context()
    let pos: CGPoint = .init(x: ctx.config.controlRadius, y: -ctx.config.controlDiameter * 0.4)
    await ctx.store.send(.dragEnded(start: .init(x: 0.0, y: 0.0), position: pos)) { store in
      store.lastDrag = nil
      store.norm = 0.2
    }
  }
  
  @MainActor
  func testIndicatorAtMininum() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config, norm: 0.0)) {
      TrackFeature()
    })
    
    try assertSnapshot(matching: view)
  }
  
  @MainActor
  func testIndicatorAtMiddle() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config, norm: 0.5)) {
      TrackFeature()
    })
    
    try assertSnapshot(matching: view)
  }
  
  @MainActor
  func testIndicatorAtMaximum() async throws {
    let ctx = Context()

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }
    
    let view = MyView(config: ctx.config, store: Store(initialState: .init(config: ctx.config, norm: 1.0)) {
      TrackFeature()
    })
    
    try assertSnapshot(matching: view)
  }
  
  @MainActor
  func testIndicatorStrokeWidth() async throws {
    let ctx = Context()
    let theme = Theme(controlValueStrokeStyle: .init(lineWidth: 4.0, lineCap: .round))
    let config = KnobConfig(parameter: ctx.param, theme: theme)

    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }

    let view = MyView(config: config, store: Store(initialState: .init(config: ctx.config, norm: 0.5)) {
      TrackFeature()
    })

    try assertSnapshot(matching: view)
  }

//  func testPreview() async throws {
//    try await assertSnapshot(matching: TrackViewPreview.previews)
//  }
}
