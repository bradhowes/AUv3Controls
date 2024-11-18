import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

@MainActor
private final class Context {
  let clock = TestClock()
  let boolParam = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
  let floatParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 2,
                                                   min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                   valueStrings: nil, dependentParameters: nil)
  lazy var paramTree = AUParameterTree.createTree(withChildren: [boolParam, floatParam])

  lazy var boolStore = TestStore(initialState: ToggleFeature.State(parameter: boolParam)) {
    ToggleFeature()
  } withDependencies: {
    $0.continuousClock = clock
  }

  lazy var config = KnobConfig(parameter: floatParam, theme: Theme())

  lazy var floatStore = TestStore(initialState: KnobFeature.State(config: config)) {
    KnobFeature(config: config)
  } withDependencies: {
    $0.continuousClock = clock
  }

  init() {}
}

final class DualityTests: XCTestCase {

  @MainActor
  func testRemoteBoolValueChanged() async {
    let ctx = Context()
    await ctx.boolStore.withExhaustivity(.off) {
      ctx.boolParam.setValue(0.0, originator: nil)
      await ctx.boolStore.send(.observationStart)
      ctx.boolParam.setValue(1.0, originator: nil)
      await ctx.boolStore.receive(.observedValueChanged(1.0)) { $0.isOn = true }
      ctx.boolParam.setValue(0.0, originator: nil)
      await ctx.boolStore.receive(.observedValueChanged(0.0)) { $0.isOn = false }
    }
    await ctx.boolStore.skipInFlightEffects()
  }

  @MainActor
  func testRemoteFloatValueChanged() async {
    let ctx = Context()
    _ = await ctx.floatStore.withExhaustivity(.off) {
      await ctx.floatStore.send(.observationStart)
    }
    _ = await ctx.floatStore.withExhaustivity(.on) {
      ctx.floatParam.setValue(1.0, originator: nil)
      await ctx.floatStore.receive(.observedValueChanged(1.0)) { state in
        state.control.track.norm = 0.01
        state.control.title.formattedValue = "1"
      }
      ctx.floatParam.setValue(12.5, originator: nil)
      await ctx.floatStore.receive(.observedValueChanged(12.5)) { state in
        state.control.track.norm = 0.125
        state.control.title.formattedValue = "12.5"
      }
      ctx.floatParam.setValue(100.0, originator: nil)
      await ctx.floatStore.receive(.observedValueChanged(100.0)) { state in
        state.control.track.norm = 1.0
        state.control.title.formattedValue = "100"
      }
    }
  }
}
