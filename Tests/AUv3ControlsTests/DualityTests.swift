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

  lazy var boolStore = TestStore(initialState: ToggleFeature.State(parameter: paramTree.parameter(withAddress: 1)!)) {
    ToggleFeature()
  } withDependencies: {
    $0.continuousClock = clock
  }

  lazy var config = KnobConfig(parameter: paramTree.parameter(withAddress: 2)!, theme: Theme())
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
    _ = await ctx.boolStore.withExhaustivity(.off) {
      await ctx.boolStore.send(.startValueObservation)
    }

    ctx.boolParam.setValue(1.0, originator: nil)
    await ctx.boolStore.receive(.observedValueChanged(1.0))
    await ctx.boolStore.receive(.animatedObservedValueChanged(true)) { $0.isOn = true }

    ctx.boolParam.setValue(0.0, originator: nil)
    await ctx.boolStore.receive(.observedValueChanged(0.0))
    await ctx.boolStore.receive(.animatedObservedValueChanged(false)) { $0.isOn = false }

    await ctx.boolStore.send(.stopValueObservation) { $0.observerToken = nil }
  }

  @MainActor
  func SKIP_testRemoteFloatValueChanged() async throws {
    let ctx = Context()
    _ = await ctx.floatStore.withExhaustivity(.off) {
      await ctx.floatStore.send(.startValueObservation)
      ctx.floatParam.setValue(1.0, originator: nil)
      await ctx.floatStore.receive(.observedValueChanged(1.0)) {
        $0.control.track.norm = 0.01
        $0.control.title.formattedValue = "1"
      }

      ctx.floatParam.setValue(12.5, originator: nil)
      await ctx.floatStore.receive(.observedValueChanged(12.5)) {
        $0.control.track.norm = 0.125
        $0.control.title.formattedValue = "12.5"
      }
      
      ctx.floatParam.setValue(100.0, originator: nil)
      await ctx.floatStore.receive(.observedValueChanged(100.0)) {
        $0.control.track.norm = 1.0
        $0.control.title.formattedValue = "100"
      }
      
      await ctx.floatStore.send(.stopValueObservation) { $0.observerToken = nil }
    }
  }
}
