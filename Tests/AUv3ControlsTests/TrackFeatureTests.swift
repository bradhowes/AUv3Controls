import AVFoundation
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
final class TrackFeatureTests: XCTestCase {
  let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var store: TestStore<TrackFeature.State, TrackFeature.Action>!
  
  func makeStore() {
    store = TestStore(initialState: TrackFeature.State(norm: 0.0)) {
      TrackFeature(config: config)
    }
  }
  
  override func setUpWithError() throws {
    isRecording = false
    config = KnobConfig(parameter: param, logScale: false, theme: Theme())
    makeStore()
  }
  
  override func tearDownWithError() throws {
  }
  
  func testInit() {
    XCTAssertEqual(0.0, store.state.norm)
    XCTAssertNil(store.state.lastDrag)
  }
  
  func testDragChangedAffectedBySensitivity() async {
    config.touchSensitivity = 1.0
    makeStore()
    
    await store.send(.dragChanged(start: .init(x: config.controlRadius, y: 0.0),
                                  position: .init(x: config.controlRadius,
                                                  y: -config.controlDiameter * 0.4))) { store in
      store.norm = 0.40
      store.lastDrag = CGPoint(x: 40, y: -32)
    }
    
    config.touchSensitivity = 2.0
    makeStore()
    
    await store.send(.dragChanged(start: .init(x: config.controlRadius, y: 0.0),
                                  position: .init(x: config.controlRadius,
                                                  y: -config.controlDiameter * 0.8))) { store in
      store.norm = 0.40
      store.lastDrag = CGPoint(x: 40, y: -64)
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
        store.norm = 0.525
      }
    }
  }
  
  func testDragEnded() async {
    let pos: CGPoint = .init(x: config.controlRadius, y: -config.controlDiameter * 0.4)
    await store.send(.dragEnded(start: .init(x: 0.0, y: 0.0), position: pos)) { store in
      store.lastDrag = nil
      store.norm = 0.2
    }
  }
  
#if os(iOS)

  func testIndicatorAtMininum() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }
    
    let view = MyView(config: config, store: Store(initialState: .init(norm: 0.0)) {
      TrackFeature(config: config)
    })
    
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))
  }
  
  func testIndicatorAtMiddle() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }
    
    let view = MyView(config: config, store: Store(initialState: .init(norm: 0.5)) {
      TrackFeature(config: config)
    })
    
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))
  }
  
  func testIndicatorAtMaximum() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }
    
    let view = MyView(config: config, store: Store(initialState: .init(norm: 1.0)) {
      TrackFeature(config: config)
    })
    
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))
  }
  
  func testIndicatorStrokeWidth() async throws {
    struct MyView: SwiftUI.View {
      let config: KnobConfig
      @State var store: StoreOf<TrackFeature>
      
      var body: some SwiftUI.View {
        TrackView(store: store, config: config)
      }
    }

    config.indicatorStrokeWidth = 12.0
    let view = MyView(config: config, store: Store(initialState: .init(norm: 0.5)) {
      TrackFeature(config: config)
    })
    
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))
  }

  func testPreview() async throws {
    let view = TrackViewPreview.previews
    assertSnapshot(of: view, as: .image(layout: .fixed(width: 220, height: 220),
                                        traits: .init(userInterfaceStyle: .dark)))
  }

#endif

}
