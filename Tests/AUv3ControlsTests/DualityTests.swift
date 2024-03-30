import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

final class DualityTests: XCTestCase {
  let clock = TestClock()
  let boolParam = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
  var boolStore: TestStore<ToggleFeature.State, ToggleFeature.Action>!
  let floatParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 2,
                                                   min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                   valueStrings: nil, dependentParameters: nil)
  var config: KnobConfig!
  var floatStore: TestStore<KnobFeature.State, KnobFeature.Action>!
  var paramTree: AUParameterTree!

  override func setUpWithError() throws {
    isRecording = false
    config = KnobConfig(parameter: floatParam, theme: Theme())
    boolStore = TestStore(initialState: ToggleFeature.State(parameter: boolParam)) {
      ToggleFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    floatStore = TestStore(initialState: KnobFeature.State(config: config)) {
      KnobFeature(config: config)
    } withDependencies: {
      $0.continuousClock = clock
    }
    paramTree = AUParameterTree.createTree(withChildren: [boolParam, floatParam])
  }

  func testRemoteBoolValueChanged() async {
    boolStore.exhaustivity = .off
    await boolStore.send(.observationStart)
    boolStore.exhaustivity = .on
    boolParam.setValue(1.0, originator: nil)
    await boolStore.receive(.observedValueChanged(1.0)) { $0.isOn = true }
    boolParam.setValue(0.0, originator: nil)
    await boolStore.receive(.observedValueChanged(0.0)) { $0.isOn = false }
  }

  func testRemoteFloatValueChanged() async {
    floatStore.exhaustivity = .off
    await floatStore.send(.observationStart)
    floatStore.exhaustivity = .on
    floatParam.setValue(1.0, originator: nil)
    await floatStore.receive(.observedValueChanged(1.0)) { state in
      state.control.track.norm = 0.01
      state.control.title.formattedValue = "1"
    }
    floatParam.setValue(12.5, originator: nil)
    await floatStore.receive(.observedValueChanged(12.5)) { state in
      state.control.track.norm = 0.125
      state.control.title.formattedValue = "12.5"
    }
    floatParam.setValue(100.0, originator: nil)
    await floatStore.receive(.observedValueChanged(100.0)) { state in
      state.control.track.norm = 1.0
      state.control.title.formattedValue = "100"
    }
  }
}
